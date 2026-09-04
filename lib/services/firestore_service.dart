import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_model.dart';
import '../models/recipe_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String categoryCollection = 'categories';

  Stream<List<Category>> getCategoriesStream() {
    return _firestore.collection(categoryCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Recipe>> getRecipesStream() {
    return _firestore.collectionGroup('recipes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

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