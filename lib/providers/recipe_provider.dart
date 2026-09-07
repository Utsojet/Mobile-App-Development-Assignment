import 'dart:async';
import 'package:flutter/material.dart';
import '../category_model.dart';
import '../models/recipe_model.dart';
import '../services/firestore_service.dart';

class RecipeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  StreamSubscription<List<Category>>? _categorySubscription;
  StreamSubscription<List<Recipe>>? _recipeSubscription;
  StreamSubscription<List<String>>? _favoritesSubscription;

  List<Category> _categories = [];
  List<Recipe> _recipes = [];
  Set<String> _userFavoriteIds = {};
  String? _currentUserId;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _servings = 1;
  bool _isLoading = true;
  String? _errorMessage;

  RecipeProvider({FirestoreService? firestoreService, String? userId})
      : _firestoreService = firestoreService ?? FirestoreService(),
        _currentUserId = userId {
    _initStreams();
    if (userId != null && userId.isNotEmpty) {
      _listenToUserFavorites(userId);
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────
  List<Category> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get servings => _servings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  List<Recipe> get allRecipes => _recipes.map(_attachFavoriteState).toList();

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
    }).map(_attachFavoriteState).toList();
  }

  List<Recipe> get favoriteRecipes {
    return _recipes
        .where((recipe) => _userFavoriteIds.contains(recipe.id))
        .map((recipe) => recipe.copyWith(isFavorite: true))
        .toList();
  }

  bool isFavorite(String recipeId) => _userFavoriteIds.contains(recipeId);

  Recipe _attachFavoriteState(Recipe recipe) {
    final isFav = _userFavoriteIds.contains(recipe.id);
    return recipe.isFavorite != isFav ? recipe.copyWith(isFavorite: isFav) : recipe;
  }

  // ── Sync with Auth State ──────────────────────────────────────────────────
  void updateUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _userFavoriteIds.clear();

    if (userId != null && userId.isNotEmpty) {
      _listenToUserFavorites(userId);
    } else {
      notifyListeners();
    }
  }

  void _listenToUserFavorites(String userId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _firestoreService.getUserFavoritesStream(userId).listen(
      (ids) {
        _userFavoriteIds = ids.toSet();
        notifyListeners();
      },
      onError: (err) {
        // Fallback or ignore non-fatal favorites stream error
      },
    );
  }

  // ── Data Streams ──────────────────────────────────────────────────────────
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

  void resetServings([int initial = 2]) {
    _servings = initial > 0 ? initial : 2;
    notifyListeners();
  }

  // ── Toggle Favorite for Current User ──────────────────────────────────────
  Future<void> toggleFavorite(Recipe recipe) async {
    final isCurrentlyFav = _userFavoriteIds.contains(recipe.id);
    final newFav = !isCurrentlyFav;

    // Optimistic local update
    if (newFav) {
      _userFavoriteIds.add(recipe.id);
    } else {
      _userFavoriteIds.remove(recipe.id);
    }
    notifyListeners();

    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestoreService.setUserFavorite(uid, recipe.id, newFav);
      } catch (e) {
        // Rollback on error
        if (isCurrentlyFav) {
          _userFavoriteIds.add(recipe.id);
        } else {
          _userFavoriteIds.remove(recipe.id);
        }
        notifyListeners();
        rethrow;
      }
    }
  }

  // ── Add New Recipe ────────────────────────────────────────────────────────
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
  }) async {
    await _firestoreService.addRecipe(
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      image: image,
      calorie: calorie,
      time: time,
      servings: servings,
      difficulty: difficulty,
      ingredientName: ingredientName,
      ingredientAmount: ingredientAmount,
      ingredientImage: ingredientImage,
      instructions: instructions,
      userId: _currentUserId,
    );
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _recipeSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}