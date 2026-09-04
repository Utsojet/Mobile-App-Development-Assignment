import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String calorie;
  final String category;
  final String image;
  final double rating;
  final int review;
  final int time;
  final List<String> ingredientImage;
  final List<String> ingredientName;
  final List<String> ingredientAmount;
  final List<String> instructions;
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.name,
    required this.calorie,
    required this.category,
    required this.image,
    required this.rating,
    required this.review,
    required this.time,
    required this.ingredientImage,
    required this.ingredientName,
    required this.ingredientAmount,
    this.instructions = const [],
    this.isFavorite = false,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Recipe(
      id: doc.id,
      name: data['name'] as String? ?? '',
      calorie: data['calorie']?.toString() ?? '',
      category: data['category'] as String? ?? '',
      image: data['image'] as String? ?? '',
      rating: _parseDouble(data['rating']),
      review: _parseInt(data['review']),
      time: _parseInt(data['time']),
      ingredientImage: _parseStringList(data['ingredientImage']),
      ingredientName: _parseStringList(data['ingredientName']),
      ingredientAmount: _parseStringList(data['ingredientAmount']),
      instructions: _parseStringList(data['instructions']),
      isFavorite: data['isFavorite'] as bool? ?? false,
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? calorie,
    String? category,
    String? image,
    double? rating,
    int? review,
    int? time,
    List<String>? ingredientImage,
    List<String>? ingredientName,
    List<String>? ingredientAmount,
    List<String>? instructions,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      calorie: calorie ?? this.calorie,
      category: category ?? this.category,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      time: time ?? this.time,
      ingredientImage: ingredientImage ?? this.ingredientImage,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientAmount: ingredientAmount ?? this.ingredientAmount,
      instructions: instructions ?? this.instructions,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'calorie': calorie,
      'category': category,
      'image': image,
      'rating': rating,
      'review': review,
      'time': time,
      'ingredientImage': ingredientImage,
      'ingredientName': ingredientName,
      'ingredientAmount': ingredientAmount,
      'instructions': instructions,
      'isFavorite': isFavorite,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }
}