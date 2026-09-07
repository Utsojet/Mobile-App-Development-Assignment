import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_model.dart';
import '../models/recipe_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String categoryCollection = 'categories';
  static const String usersCollection = 'users';

  /// Stream of all categories.
  Stream<List<Category>> getCategoriesStream() {
    return _firestore.collection(categoryCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  /// Stream of all recipes across category subcollections.
  Stream<List<Recipe>> getRecipesStream() {
    return _firestore.collectionGroup('recipes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  /// Stream of favorite recipe IDs for a specific authenticated user.
  Stream<List<String>> getUserFavoritesStream(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Persists or removes a favorite recipe for a specific user.
  Future<void> setUserFavorite(
    String userId,
    String recipeId,
    bool isFavorite,
  ) async {
    final favRef = _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection('favorites')
        .doc(recipeId);

    if (isFavorite) {
      await favRef.set({
        'recipeId': recipeId,
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await favRef.delete();
    }
  }

  /// Adds a new recipe to Firestore in the specified category subcollection.
  Future<void> addRecipe({
    required String categoryId,
    required String categoryName,
    required String name,
    required String image,
    required String calorie,
    required int time,
    int servings = 2,
    String difficulty = 'Easy',
    required List<String> ingredientName,
    required List<String> ingredientAmount,
    List<String>? ingredientImage,
    required List<String> instructions,
    String? userId,
  }) async {
    final cleanCategoryId = categoryId.trim().toLowerCase();
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final recipeId = slug.isNotEmpty ? '${slug}_$timestamp' : 'recipe_$timestamp';

    final recipeDoc = _firestore
        .collection(categoryCollection)
        .doc(cleanCategoryId)
        .collection('recipes')
        .doc(recipeId);

    final cleanCal = calorie
        .trim()
        .replaceAll(RegExp(r'\s*(kcal|cal|calories)\s*', caseSensitive: false), '')
        .trim();
    final finalCalorie = cleanCal.isNotEmpty ? cleanCal : Recipe.defaultCategoryCalorie(categoryName);

    final finalIngredientImages = List.generate(ingredientName.length, (i) {
      if (ingredientImage != null &&
          i < ingredientImage.length &&
          ingredientImage[i].trim().isNotEmpty) {
        final img = ingredientImage[i].trim();
        return img.startsWith('http://') ? img.replaceFirst('http://', 'https://') : img;
      }
      final clean = ingredientName[i].trim();
      return clean.isNotEmpty
          ? 'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(clean)}-Small.png'
          : 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300&q=80';
    });

    final finalImage = image.trim().isNotEmpty
        ? image.trim()
        : Recipe.defaultCategoryImage(categoryName);

    await recipeDoc.set({
      'id': recipeId,
      'categoryId': cleanCategoryId,
      'name': name.trim(),
      'category': categoryName.trim(),
      'image': finalImage,
      'calorie': finalCalorie,
      'time': time > 0 ? time : Recipe.defaultCategoryTime(categoryName),
      'servings': servings > 0 ? servings : 2,
      'difficulty': difficulty.trim().isNotEmpty ? difficulty.trim() : 'Easy',
      'rating': 5.0,
      'review': 1,
      'isFavorite': false,
      'ingredientName': ingredientName,
      'ingredientAmount': ingredientAmount,
      'ingredientImage': finalIngredientImages,
      'instructions': instructions,
      if (userId != null && userId.isNotEmpty) 'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Legacy toggle (retained for backward compatibility).
  Future<void> toggleFavorite(String recipeId, bool currentStatus, {String? category}) async {
    final newStatus = !currentStatus;
    if (category != null && category.isNotEmpty) {
      final categoryId = category.trim().toLowerCase();
      final docRef = _firestore
          .collection(categoryCollection)
          .doc(categoryId)
          .collection('recipes')
          .doc(recipeId);
      await docRef.set({'isFavorite': newStatus}, SetOptions(merge: true));
      return;
    }

    final query = await _firestore
        .collectionGroup('recipes')
        .where(FieldPath.documentId, isEqualTo: recipeId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.set({'isFavorite': newStatus}, SetOptions(merge: true));
    }
  }
}