import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe/category_model.dart';
import 'package:recipe/models/recipe_model.dart';
import 'package:recipe/providers/recipe_provider.dart';
import 'package:recipe/services/firestore_service.dart';

class FakeFirestoreService extends Fake implements FirestoreService {
  final StreamController<List<Category>> categoryController =
      StreamController<List<Category>>.broadcast();
  final StreamController<List<Recipe>> recipeController =
      StreamController<List<Recipe>>.broadcast();
  final StreamController<List<String>> favoritesController =
      StreamController<List<String>>.broadcast();

  final List<String> userFavorites = [];
  bool addRecipeCalled = false;

  @override
  Stream<List<Category>> getCategoriesStream() => categoryController.stream;

  @override
  Stream<List<Recipe>> getRecipesStream() => recipeController.stream;

  @override
  Stream<List<String>> getUserFavoritesStream(String userId) =>
      favoritesController.stream;

  @override
  Future<void> setUserFavorite(
    String userId,
    String recipeId,
    bool isFavorite,
  ) async {
    if (isFavorite) {
      if (!userFavorites.contains(recipeId)) userFavorites.add(recipeId);
    } else {
      userFavorites.remove(recipeId);
    }
  }

  @override
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
    addRecipeCalled = true;
  }
}

void main() {
  group('RecipeProvider User Favorites & Add Recipe Tests', () {
    test('User favorites isolate favorites to current user', () async {
      final fakeService = FakeFirestoreService();
      final provider = RecipeProvider(firestoreService: fakeService, userId: 'user_123');

      final sampleRecipe = Recipe(
        id: 'pancakes',
        name: 'Pancakes',
        category: 'Breakfast',
        image: '',
        calorie: '250 kcal',
        time: 15,
        rating: 4.8,
        review: 12,
        isFavorite: false,
        ingredientName: ['Flour'],
        ingredientAmount: ['1 cup'],
        ingredientImage: [''],
        instructions: ['Mix and cook'],
      );

      // Emit recipe
      fakeService.recipeController.add([sampleRecipe]);
      await Future.delayed(Duration.zero);

      expect(provider.isFavorite('pancakes'), false);
      expect(provider.favoriteRecipes.isEmpty, true);

      // Toggle favorite
      await provider.toggleFavorite(sampleRecipe);

      expect(provider.isFavorite('pancakes'), true);
      expect(provider.favoriteRecipes.length, 1);
      expect(provider.favoriteRecipes.first.id, 'pancakes');

      // Now switch user (e.g. log out or switch account)
      provider.updateUser('user_456');
      expect(provider.isFavorite('pancakes'), false);
      expect(provider.favoriteRecipes.isEmpty, true);
    });

    test('addRecipe invokes Firestore service properly', () async {
      final fakeService = FakeFirestoreService();
      final provider = RecipeProvider(firestoreService: fakeService, userId: 'user_123');

      await provider.addRecipe(
        categoryId: 'lunch',
        categoryName: 'Lunch',
        name: 'Caesar Salad',
        image: 'https://example.com/salad.jpg',
        calorie: '180 kcal',
        time: 10,
        ingredientName: ['Lettuce', 'Dressing'],
        ingredientAmount: ['1 head', '2 tbsp'],
        instructions: ['Chop lettuce', 'Toss with dressing'],
      );

      expect(fakeService.addRecipeCalled, true);
    });

    test('Recipe.defaultIngredients never returns "Main Ingredient" and matches keywords', () {
      final names = [
        '15-minute chicken & halloumi burgers',
        'Ayam Percik',
        'Bengali Chicken Curry with Potatoes',
        'Chicken Alfredo Primavera',
        'Chicken Congee',
        'Chicken Enchilada Casserole',
        'Chicken Fried Rice',
        'Unknown Dish',
      ];

      for (final name in names) {
        final res = Recipe.defaultIngredients(name, '');
        expect(res.names.contains('Main Ingredient'), isFalse,
            reason: 'Dish "$name" should not produce "Main Ingredient"');
        expect(res.names.isNotEmpty, isTrue);
        expect(res.amounts.length, res.names.length);
      }
    });

    test('Recipe.resolveTheMealDbIngredientUrl resolves valid image URLs', () {
      final url = Recipe.resolveTheMealDbIngredientUrl('Chicken Breast');
      expect(url, contains('Chicken%20Breast-Small.png'));
    });
  });
}
