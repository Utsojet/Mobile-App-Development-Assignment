import 'package:flutter_test/flutter_test.dart';
import 'package:recipe/models/user_model.dart';
import 'package:recipe/models/review_model.dart';
import 'package:recipe/models/recipe_model.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel default constructor and copyWith', () {
      const user = UserModel(
        uid: 'user-123',
        name: 'Chef Auguste',
        email: 'auguste@escofier.com',
        bio: 'King of chefs',
        themeMode: 'dark',
      );

      expect(user.uid, 'user-123');
      expect(user.name, 'Chef Auguste');
      expect(user.email, 'auguste@escofier.com');
      expect(user.bio, 'King of chefs');
      expect(user.themeMode, 'dark');

      final updated = user.copyWith(name: 'Chef Georges', bio: 'Updated bio');
      expect(updated.name, 'Chef Georges');
      expect(updated.bio, 'Updated bio');
      expect(updated.email, 'auguste@escofier.com');
    });

    test('UserModel toFirestore contains expected map entries', () {
      const user = UserModel(
        uid: 'u-456',
        name: 'Julia Child',
        email: 'julia@cook.com',
        bio: 'Bon Appetit!',
        themeMode: 'light',
      );

      final map = user.toFirestore();
      expect(map['uid'], 'u-456');
      expect(map['name'], 'Julia Child');
      expect(map['email'], 'julia@cook.com');
      expect(map['bio'], 'Bon Appetit!');
      expect(map['themeMode'], 'light');
    });
  });

  group('ReviewModel Tests', () {
    test('ReviewModel serialization and copyWith', () {
      const review = ReviewModel(
        id: 'rev-user-1',
        userId: 'rev-user-1',
        recipeId: 'spinach_pasta_1',
        categoryId: 'dinner',
        recipeName: 'Spinach Pasta',
        userName: 'Pasta Master',
        rating: 5,
        comment: 'Delicious and fragrant!',
      );

      expect(review.id, 'rev-user-1');
      expect(review.rating, 5);
      expect(review.comment, 'Delicious and fragrant!');

      final map = review.toFirestore();
      expect(map['userId'], 'rev-user-1');
      expect(map['recipeId'], 'spinach_pasta_1');
      expect(map['categoryId'], 'dinner');
      expect(map['rating'], 5);
      expect(map['comment'], 'Delicious and fragrant!');

      final updated = review.copyWith(rating: 4, comment: 'Slightly too salty');
      expect(updated.rating, 4);
      expect(updated.comment, 'Slightly too salty');
      expect(updated.recipeName, 'Spinach Pasta');
    });

    test('Recipe aggregate rating calculation logic', () {
      final ratings = [5, 4, 5, 3, 5];
      final totalReviews = ratings.length;
      final sum = ratings.fold<int>(0, (acc, r) => acc + r);
      final avg = double.parse((sum / totalReviews).toStringAsFixed(1));

      expect(totalReviews, 5);
      expect(avg, 4.4);
    });

    test('Recipe model includes categoryId attribute', () {
      const recipe = Recipe(
        id: 'rec_101',
        categoryId: 'dinner',
        name: 'Creamy Risotto',
        calorie: '450',
        category: 'Dinner',
        image: 'https://image.com/risotto.jpg',
        rating: 4.8,
        review: 15,
        time: 35,
        ingredientImage: [],
        ingredientName: ['Arborio rice', 'Broth'],
        ingredientAmount: ['1 cup', '3 cups'],
      );

      expect(recipe.categoryId, 'dinner');
      expect(recipe.name, 'Creamy Risotto');
      expect(recipe.review, 15);
      expect(recipe.rating, 4.8);

      final copy = recipe.copyWith(rating: 4.9, review: 16);
      expect(copy.rating, 4.9);
      expect(copy.review, 16);
      expect(copy.categoryId, 'dinner');
    });
  });
}
