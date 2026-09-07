import 'package:cloud_firestore/cloud_firestore.dart';

/// Review document model stored in:
/// `categories/{categoryId}/recipes/{recipeId}/reviews/{uid}`
class ReviewModel {
  final String id; // Document ID (user's UID)
  final String userId;
  final String recipeId;
  final String categoryId;
  final String recipeName;
  final String userName;
  final String userPhotoUrl;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.categoryId,
    required this.recipeName,
    required this.userName,
    this.userPhotoUrl = '',
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      userId: data['userId'] as String? ?? doc.id,
      recipeId: data['recipeId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      recipeName: data['recipeName'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous Chef',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      rating: _parseInt(data['rating'], fallback: 5),
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'recipeId': recipeId,
      'categoryId': categoryId,
      'recipeName': recipeName,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? recipeId,
    String? categoryId,
    String? recipeName,
    String? userName,
    String? userPhotoUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeId: recipeId ?? this.recipeId,
      categoryId: categoryId ?? this.categoryId,
      recipeName: recipeName ?? this.recipeName,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
