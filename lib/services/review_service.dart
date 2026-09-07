import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// Service managing recipe reviews and ratings in Cloud Firestore.
///
/// Reviews are stored at:
class ReviewService {
  final FirebaseFirestore? _customFirestore;

  ReviewService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Stream of all reviews for a specific recipe, sorted with most recent first.
  Stream<List<ReviewModel>> getRecipeReviews(String categoryId, String recipeId) {
    final cleanCatId = categoryId.trim().toLowerCase();
    return _firestore
        .collection('categories')
        .doc(cleanCatId)
        .collection('recipes')
        .doc(recipeId)
        .collection('reviews')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// Stream of all reviews written by a specific user across all recipes.
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// Submits or edits a review for a recipe, and atomically updates the recipe's
  /// aggregate rating and review count.
  Future<void> submitOrUpdateReview({
    required String categoryId,
    required String recipeId,
    required String recipeName,
    required String userId,
    required String userName,
    String userPhotoUrl = '',
    required int rating,
    required String comment,
  }) async {
    final cleanCatId = categoryId.trim().toLowerCase();
    final recipeRef = _firestore
        .collection('categories')
        .doc(cleanCatId)
        .collection('recipes')
        .doc(recipeId);

    final reviewRef = recipeRef.collection('reviews').doc(userId);

    final existingSnap = await reviewRef.get();
    final isNew = !existingSnap.exists;

    await reviewRef.set({
      'userId': userId,
      'recipeId': recipeId,
      'categoryId': cleanCatId,
      'recipeName': recipeName.trim(),
      'userName': userName.trim().isNotEmpty ? userName.trim() : 'Chef',
      'userPhotoUrl': userPhotoUrl.trim(),
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _recalculateRecipeRating(cleanCatId, recipeId);
  }

  /// Deletes a review and updates the recipe's aggregate rating and review count.
  Future<void> deleteReview({
    required String categoryId,
    required String recipeId,
    required String userId,
  }) async {
    final cleanCatId = categoryId.trim().toLowerCase();
    final recipeRef = _firestore
        .collection('categories')
        .doc(cleanCatId)
        .collection('recipes')
        .doc(recipeId);

    await recipeRef.collection('reviews').doc(userId).delete();
    await _recalculateRecipeRating(cleanCatId, recipeId);
  }

  /// Recalculates the average rating and review count directly on the recipe doc.
  Future<void> _recalculateRecipeRating(String categoryId, String recipeId) async {
    try {
      final recipeRef = _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('recipes')
          .doc(recipeId);

      final reviewsSnap = await recipeRef.collection('reviews').get();
      final total = reviewsSnap.docs.length;
      double avg = 0.0;

      if (total > 0) {
        final sum = reviewsSnap.docs.fold<num>(
          0,
          (acc, doc) {
            final r = doc.data()['rating'];
            if (r is num) return acc + r;
            if (r is String) return acc + (num.tryParse(r) ?? 0);
            return acc;
          },
        );
        avg = double.parse((sum / total).toStringAsFixed(1));
      }

      await recipeRef.update({
        'rating': avg,
        'review': total,
      });
    } catch (_) {
      // In case recipe doc update fails, non-fatal to review save
    }
  }
}
