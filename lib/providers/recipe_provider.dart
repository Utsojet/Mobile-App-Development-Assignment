import 'dart:async';
import 'package:flutter/material.dart';
import '../category_model.dart';
import '../models/recipe_model.dart';
import '../services/firestore_service.dart';

class RecipeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  StreamSubscription<List<Category>>? _categorySubscription;
  StreamSubscription<List<Recipe>>? _recipeSubscription;

  List<Category> _categories = [];
  List<Recipe> _recipes = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _servings = 1;
  bool _isLoading = true;
  String? _errorMessage;

  RecipeProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _initStreams();
  }

  List<Category> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get servings => _servings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Recipe> get allRecipes => _recipes;

  List<Recipe> get filteredRecipes {
    return _recipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'All' ||
          recipe.category.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredientName.any(
            (ing) => ing.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Recipe> get favoriteRecipes {
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  void _initStreams() {
    _isLoading = true;
    notifyListeners();

    _categorySubscription = _firestoreService.getCategoriesStream().listen(
      (categories) {
        _categories = categories;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _recipeSubscription = _firestoreService.getRecipesStream().listen(
      (recipes) {
        final unique = <String, Recipe>{};
        for (final r in recipes) {
          unique[r.id] = r;
        }
        _recipes = unique.values.toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void incrementServings() {
    _servings++;
    notifyListeners();
  }

  void decrementServings() {
    if (_servings > 1) {
      _servings--;
      notifyListeners();
    }
  }

  void resetServings() {
    _servings = 1;
    notifyListeners();
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = recipe.copyWith(isFavorite: !recipe.isFavorite);
      notifyListeners();
    }

    try {
      await _firestoreService.toggleFavorite(recipe.id, recipe.isFavorite,
          category: recipe.category);
    } catch (e) {
      if (index != -1) {
        _recipes[index] = recipe;
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _recipeSubscription?.cancel();
    super.dispose();
  }
}