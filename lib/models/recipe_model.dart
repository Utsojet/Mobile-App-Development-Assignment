import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String categoryId;
  final String name;
  final String calorie;
  final String category;
  final String image;
  final double rating;
  final int review;
  final int time;
  final int servings;
  final String difficulty;
  final List<String> ingredientImage;
  final List<String> ingredientName;
  final List<String> ingredientAmount;
  final List<String> instructions;
  final bool isFavorite;

  const Recipe({
    required this.id,
    this.categoryId = '',
    required this.name,
    required this.calorie,
    required this.category,
    required this.image,
    required this.rating,
    required this.review,
    required this.time,
    this.servings = 2,
    this.difficulty = 'Easy',
    required this.ingredientImage,
    required this.ingredientName,
    required this.ingredientAmount,
    this.instructions = const [],
    this.isFavorite = false,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final parentCatId = doc.reference.parent.parent?.id;
    final rawCategoryName = (data['category'] as String? ?? '').trim();
    final catId = (data['categoryId'] as String? ??
            parentCatId ??
            rawCategoryName.toLowerCase())
        .trim();

    final effectiveCategory = rawCategoryName.isNotEmpty
        ? rawCategoryName
        : (catId.isNotEmpty
            ? (catId[0].toUpperCase() + catId.substring(1))
            : 'General');

    final rawImage = (data['image'] as String?)?.trim() ??
        (data['imageUrl'] as String?)?.trim() ??
        (data['image_url'] as String?)?.trim() ??
        (data['strMealThumb'] as String?)?.trim() ??
        (data['photoUrl'] as String?)?.trim() ??
        (data['photo'] as String?)?.trim() ??
        '';

    final effectiveImage = rawImage.isNotEmpty
        ? (rawImage.startsWith('http://')
            ? rawImage.replaceFirst('http://', 'https://')
            : rawImage)
        : defaultCategoryImage(effectiveCategory);

    // Calorie parsing & fallback
    final rawCal = data['calorie'] ?? data['calories'] ?? data['kcal'] ?? data['cal'] ?? data['strCalories'];
    final parsedCal = _cleanCalorieString(rawCal);
    final effectiveCalorie = parsedCal.isNotEmpty ? parsedCal : defaultCategoryCalorie(effectiveCategory);

    // Time parsing & fallback
    final rawTime = data['time'] ?? data['cookTime'] ?? data['cookingTime'] ?? data['readyInMinutes'] ?? data['duration'] ?? data['timeInMinutes'];
    var parsedTime = _parseInt(rawTime);
    if (parsedTime <= 0) {
      parsedTime = _extractMinutesFromName(data['name']?.toString() ?? '') ?? defaultCategoryTime(effectiveCategory);
    }

    // Rating parsing & fallback
    final rawRating = data['rating'] ?? data['ratings'] ?? data['score'] ?? data['stars'] ?? data['rate'];
    var parsedRating = _parseDouble(rawRating);
    if (parsedRating <= 0.0) parsedRating = 4.6;

    // Review parsing & fallback
    final rawReview = data['review'] ?? data['reviews'] ?? data['reviewCount'] ?? data['ratingsCount'];
    var parsedReview = _parseInt(rawReview);
    if (parsedReview <= 0) parsedReview = 12;

    // Servings parsing & fallback
    final rawServings = data['servings'] ?? data['yield'] ?? data['portions'];
    var parsedServings = _parseInt(rawServings);
    if (parsedServings <= 0) parsedServings = 2;

    // Difficulty parsing & fallback
    var parsedDifficulty = (data['difficulty'] as String?)?.trim() ?? (data['level'] as String?)?.trim() ?? '';
    if (parsedDifficulty.isEmpty) {
      parsedDifficulty = parsedTime <= 20 ? 'Easy' : (parsedTime <= 45 ? 'Medium' : 'Hard');
    }

    // Ingredients parsing & robust fallback
    var rawNames = <String>[];
    var rawAmounts = <String>[];
    var rawImages = <String>[];

    final rawIngredientsData = data['ingredientName'] ??
        data['ingredientNames'] ??
        data['ingredients'] ??
        data['ingredient_list'];

    if (rawIngredientsData is List) {
      for (final item in rawIngredientsData) {
        if (item is Map) {
          final n = item['name'] ?? item['ingredient'] ?? item['title'] ?? '';
          final a = item['amount'] ?? item['measure'] ?? item['quantity'] ?? '';
          final img = item['image'] ?? item['imageUrl'] ?? item['img'] ?? '';
          if (n.toString().trim().isNotEmpty) {
            rawNames.add(n.toString().trim());
            rawAmounts.add(a.toString().trim());
            rawImages.add(img.toString().trim());
          }
        } else if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty) rawNames.add(str);
        }
      }
    }

    // Check TheMealDB strIngredient1..20
    if (rawNames.isEmpty) {
      for (int i = 1; i <= 20; i++) {
        final ing = data['strIngredient$i']?.toString().trim();
        final measure = data['strMeasure$i']?.toString().trim();
        if (ing != null && ing.isNotEmpty) {
          rawNames.add(ing);
          rawAmounts.add(measure != null && measure.isNotEmpty ? measure : '1 serving');
        }
      }
    }

    if (rawAmounts.isEmpty) {
      final rawAmtData = data['ingredientAmount'] ??
          data['ingredientAmounts'] ??
          data['amounts'] ??
          data['measures'];
      rawAmounts = _parseStringList(rawAmtData);
    }

    if (rawImages.isEmpty) {
      final rawImgData = data['ingredientImage'] ??
          data['ingredientImages'] ??
          data['images'];
      rawImages = _parseStringList(rawImgData);
    }

    final recipeName = data['name']?.toString().trim() ?? '';

    if (rawNames.isEmpty) {
      final defaults = defaultIngredients(recipeName, effectiveCategory);
      rawNames = defaults.names;
      rawAmounts = defaults.amounts;
    }

    final ingredientImages = List<String>.generate(rawNames.length, (i) {
      if (i < rawImages.length && rawImages[i].trim().isNotEmpty) {
        final img = rawImages[i].trim();
        return img.startsWith('http://') ? img.replaceFirst('http://', 'https://') : img;
      }
      final cleanName = rawNames[i].trim();
      return cleanName.isNotEmpty
          ? resolveTheMealDbIngredientUrl(cleanName)
          : '';
    });

    // Instructions parsing & category fallback
    var parsedInstructions = _parseStringList(
        data['instructions'] ?? data['steps'] ?? data['directions'] ?? data['strInstructions']);
    if (parsedInstructions.isEmpty) {
      parsedInstructions = defaultInstructions(recipeName, effectiveCategory);
    }

    return Recipe(
      id: doc.id,
      categoryId: catId,
      name: recipeName,
      calorie: effectiveCalorie,
      category: effectiveCategory,
      image: effectiveImage,
      rating: parsedRating,
      review: parsedReview,
      time: parsedTime,
      servings: parsedServings,
      difficulty: parsedDifficulty,
      ingredientImage: ingredientImages,
      ingredientName: rawNames,
      ingredientAmount: rawAmounts,
      instructions: parsedInstructions,
      isFavorite: data['isFavorite'] as bool? ?? false,
    );
  }

  String get displayCalorie {
    final clean = _cleanCalorieString(calorie);
    if (clean.isNotEmpty && clean != '0') {
      return '$clean kcal';
    }
    return '${defaultCategoryCalorie(category)} kcal';
  }

  int get displayTime => time > 0 ? time : defaultCategoryTime(category);
  double get displayRating => rating > 0.0 ? rating : 4.6;
  int get displayReview => review > 0 ? review : 12;

  static String defaultCategoryCalorie(String category) {
    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'breakfast': return '320';
      case 'lunch': return '480';
      case 'dinner': return '560';
      case 'dessert':
      case 'cake':
      case 'sweet': return '380';
      case 'vegetables':
      case 'vegetarian':
      case 'salad': return '220';
      case 'chicken': return '440';
      case 'beef':
      case 'meat': return '540';
      case 'seafood':
      case 'fish': return '380';
      case 'pasta':
      case 'noodles': return '490';
      default: return '350';
    }
  }

  static int defaultCategoryTime(String category) {
    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'breakfast': return 15;
      case 'dessert': return 35;
      case 'dinner': return 30;
      case 'lunch': return 25;
      case 'vegetables': return 20;
      case 'chicken': return 25;
      case 'beef': return 40;
      case 'seafood': return 20;
      case 'pasta': return 20;
      default: return 25;
    }
  }

  static String resolveTheMealDbIngredientUrl(String ingredient) {
    final clean = ingredient.trim();
    if (clean.isEmpty) return '';
    final lower = clean.toLowerCase();
    String query = clean;

    if (lower.contains('breast') || lower == 'chicken') {
      query = 'Chicken Breast';
    } else if (lower.contains('bun') || lower.contains('toast') || lower.contains('bread')) {
      query = 'Bread';
    } else if (lower.contains('beef') || lower.contains('steak') || lower.contains('meat')) {
      query = 'Beef';
    } else if (lower.contains('salmon') || lower.contains('fish') || lower.contains('tuna')) {
      query = 'Salmon';
    } else if (lower.contains('shrimp') || lower.contains('prawn')) {
      query = 'Prawns';
    } else if (lower.contains('pasta') || lower.contains('spaghetti') || lower.contains('fettuccine') || lower.contains('noodle')) {
      query = 'Spaghetti';
    } else if (lower.contains('cheese') || lower.contains('cheddar') || lower.contains('mozzarella') || lower.contains('halloumi') || lower.contains('paneer')) {
      query = 'Cheddar Cheese';
    } else if (lower.contains('oil')) {
      query = 'Olive Oil';
    } else if (lower.contains('pepper')) {
      query = 'Black Pepper';
    } else if (lower.contains('salt')) {
      query = 'Salt';
    } else if (lower.contains('garlic')) {
      query = 'Garlic';
    } else if (lower.contains('onion')) {
      query = 'Onion';
    } else if (lower.contains('tomato')) {
      query = 'Tomato';
    } else if (lower.contains('potato')) {
      query = 'Potatoes';
    } else if (lower.contains('rice')) {
      query = 'Rice';
    } else if (lower.contains('egg')) {
      query = 'Eggs';
    } else if (lower.contains('butter')) {
      query = 'Butter';
    } else if (lower.contains('cream')) {
      query = 'Double Cream';
    } else if (lower.contains('milk')) {
      query = 'Milk';
    } else if (lower.contains('sugar')) {
      query = 'Sugar';
    } else if (lower.contains('flour')) {
      query = 'Flour';
    } else if (lower.contains('lemon')) {
      query = 'Lemon';
    } else if (lower.contains('lime')) {
      query = 'Lime';
    } else if (lower.contains('chili') || lower.contains('chilli')) {
      query = 'Chili';
    } else if (lower.contains('ginger')) {
      query = 'Ginger';
    } else if (lower.contains('mushroom')) {
      query = 'Mushrooms';
    } else if (lower.contains('basil') || lower.contains('herb') || lower.contains('parsley')) {
      query = 'Basil';
    } else if (lower.contains('curry')) {
      query = 'Curry Powder';
    }

    return 'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(query)}-Small.png';
  }

  static ({List<String> names, List<String> amounts}) defaultIngredients(String name, String category) {
    final lowerName = name.trim().toLowerCase();
    final cat = category.trim().toLowerCase();

    // 1. Recipe name specific ingredients (covers popular and seeded recipes)
    if (lowerName.contains('halloumi') || (lowerName.contains('burger') && lowerName.contains('chicken'))) {
      return (
        names: ['Chicken Breast', 'Cheddar Cheese', 'Bread', 'Tomato', 'Olive Oil'],
        amounts: ['300 gm', '150 gm', '2 buns', '1 medium', '1 tbsp'],
      );
    }
    if (lowerName.contains('burger')) {
      return (
        names: ['Beef', 'Bread', 'Cheddar Cheese', 'Tomato', 'Onion', 'Olive Oil'],
        amounts: ['350 gm', '2 buns', '2 slices', '1 medium', '1/2 medium', '1 tbsp'],
      );
    }
    if (lowerName.contains('ayam percik')) {
      return (
        names: ['Chicken Breast', 'Garlic', 'Chili', 'Ginger', 'Onion', 'Olive Oil'],
        amounts: ['500 gm', '4 cloves', '2 pcs', '1 piece', '1 medium', '2 tbsp'],
      );
    }
    if (lowerName.contains('curry')) {
      return (
        names: ['Chicken Breast', 'Curry Powder', 'Potatoes', 'Onion', 'Garlic', 'Ginger'],
        amounts: ['400 gm', '2 tbsp', '2 medium', '1 large', '3 cloves', '1 piece'],
      );
    }
    if (lowerName.contains('congee')) {
      return (
        names: ['Rice', 'Chicken Breast', 'Ginger', 'Onion', 'Garlic', 'Salt'],
        amounts: ['1 cup', '200 gm', '1 piece', '2 stalks', '2 cloves', '1 tsp'],
      );
    }
    if (lowerName.contains('fried rice')) {
      return (
        names: ['Rice', 'Chicken Breast', 'Eggs', 'Carrots', 'Onion', 'Garlic'],
        amounts: ['2 cups', '200 gm', '2 large', '1 medium', '1/2 medium', '2 cloves'],
      );
    }
    if (lowerName.contains('alfredo') || lowerName.contains('primavera') || lowerName.contains('carbonara')) {
      return (
        names: ['Spaghetti', 'Double Cream', 'Cheddar Cheese', 'Garlic', 'Butter', 'Black Pepper'],
        amounts: ['250 gm', '1 cup', '50 gm', '3 cloves', '2 tbsp', '1/2 tsp'],
      );
    }
    if (lowerName.contains('enchilada') || lowerName.contains('casserole') || lowerName.contains('taco')) {
      return (
        names: ['Chicken Breast', 'Cheddar Cheese', 'Tomato', 'Onion', 'Garlic', 'Olive Oil'],
        amounts: ['350 gm', '120 gm', '2 medium', '1 medium', '2 cloves', '1 tbsp'],
      );
    }
    if (lowerName.contains('stew')) {
      return (
        names: ['Chicken Breast', 'Potatoes', 'Carrots', 'Onion', 'Garlic', 'Olive Oil'],
        amounts: ['450 gm', '2 large', '2 medium', '1 large', '3 cloves', '2 tbsp'],
      );
    }
    if (lowerName.contains('paneer')) {
      return (
        names: ['Tomato', 'Butter', 'Onion', 'Double Cream', 'Garlic', 'Ginger'],
        amounts: ['3 medium', '2 tbsp', '1 large', '2 tbsp', '3 cloves', '1 piece'],
      );
    }
    if (lowerName.contains('toast') || lowerName.contains('french toast')) {
      return (
        names: ['Bread', 'Eggs', 'Milk', 'Butter', 'Sugar'],
        amounts: ['4 slices', '2 large', '1/2 cup', '1 tbsp', '1 tbsp'],
      );
    }
    if (lowerName.contains('pancake') || lowerName.contains('waffle')) {
      return (
        names: ['Flour', 'Milk', 'Eggs', 'Butter', 'Sugar'],
        amounts: ['1.5 cups', '1 cup', '2 large', '2 tbsp', '2 tbsp'],
      );
    }
    if (lowerName.contains('salmon') || lowerName.contains('fish') || lowerName.contains('shrimp')) {
      return (
        names: ['Salmon', 'Lemon', 'Butter', 'Garlic', 'Black Pepper', 'Salt'],
        amounts: ['350 gm', '1 whole', '2 tbsp', '3 cloves', '1/2 tsp', '1/2 tsp'],
      );
    }
    if (lowerName.contains('pizza')) {
      return (
        names: ['Flour', 'Tomato', 'Cheddar Cheese', 'Olive Oil', 'Basil', 'Garlic'],
        amounts: ['2 cups', '2 medium', '150 gm', '2 tbsp', 'Handful', '1 clove'],
      );
    }
    if (lowerName.contains('salad')) {
      return (
        names: ['Tomato', 'Olive Oil', 'Lemon', 'Cheddar Cheese', 'Black Pepper', 'Salt'],
        amounts: ['2 medium', '2 tbsp', '1 tbsp', '50 gm', '1/2 tsp', '1/2 tsp'],
      );
    }

    // 2. Category specific ingredients
    switch (cat) {
      case 'chicken':
        return (
          names: ['Chicken Breast', 'Olive Oil', 'Garlic', 'Onion', 'Black Pepper', 'Salt'],
          amounts: ['450 gm', '2 tbsp', '3 cloves', '1 medium', '1/2 tsp', '1 tsp'],
        );
      case 'breakfast':
        return (
          names: ['Eggs', 'Bread', 'Butter', 'Milk', 'Black Pepper', 'Salt'],
          amounts: ['2 large', '2 slices', '1 tbsp', '1/4 cup', '1 pinch', '1 pinch'],
        );
      case 'dessert':
      case 'cake':
      case 'sweet':
        return (
          names: ['Flour', 'Sugar', 'Butter', 'Eggs', 'Milk'],
          amounts: ['1.5 cups', '3/4 cup', '1/2 cup', '2 large', '1/2 cup'],
        );
      case 'dinner':
      case 'beef':
      case 'meat':
        return (
          names: ['Beef', 'Onion', 'Garlic', 'Olive Oil', 'Potatoes', 'Black Pepper'],
          amounts: ['450 gm', '1 medium', '3 cloves', '2 tbsp', '2 medium', '1 tsp'],
        );
      case 'lunch':
        return (
          names: ['Chicken Breast', 'Rice', 'Olive Oil', 'Tomato', 'Garlic', 'Salt'],
          amounts: ['350 gm', '1 cup', '2 tbsp', '1 medium', '2 cloves', '1 tsp'],
        );
      case 'vegetables':
      case 'vegetarian':
        return (
          names: ['Carrots', 'Potatoes', 'Olive Oil', 'Garlic', 'Lemon', 'Salt'],
          amounts: ['200 gm', '200 gm', '2 tbsp', '3 cloves', '1 tbsp', '1/2 tsp'],
        );
      case 'seafood':
      case 'fish':
        return (
          names: ['Salmon', 'Lemon', 'Butter', 'Garlic', 'Basil', 'Black Pepper'],
          amounts: ['400 gm', '1 whole', '2 tbsp', '2 cloves', '1 tbsp', '1/2 tsp'],
        );
      case 'pasta':
      case 'noodles':
        return (
          names: ['Spaghetti', 'Tomato', 'Olive Oil', 'Garlic', 'Cheddar Cheese', 'Basil'],
          amounts: ['250 gm', '3 medium', '2 tbsp', '3 cloves', '50 gm', 'Handful'],
        );
      default:
        return (
          names: ['Chicken Breast', 'Olive Oil', 'Garlic', 'Onion', 'Black Pepper', 'Salt'],
          amounts: ['350 gm', '2 tbsp', '2 cloves', '1 medium', '1/2 tsp', '1 tsp'],
        );
    }
  }

  static List<String> defaultInstructions(String name, String category) {
    final lowerName = name.trim().toLowerCase();
    final cat = category.trim().toLowerCase();

    if (lowerName.contains('burger')) {
      return [
        'Form the seasoned patties evenly and chill for 10 minutes before cooking.',
        'Heat a skillet or grill with olive oil over medium-high heat.',
        'Cook patties for 3–4 minutes per side until nicely browned and juicy.',
        'Toast the buns lightly and assemble with fresh toppings and condiments.',
      ];
    }
    if (lowerName.contains('curry')) {
      return [
        'Heat oil in a heavy pot and sauté chopped onions, garlic, and ginger until fragrant.',
        'Add curry spices and stir for 1 minute until aromatic.',
        'Add the meat and potatoes, stirring to coat with the spice mixture.',
        'Pour in the liquid, cover, and simmer gently for 20–25 minutes until tender.',
      ];
    }
    if (lowerName.contains('fried rice') || lowerName.contains('rice')) {
      return [
        'Heat oil in a wok or large frying pan over high heat.',
        'Scramble the eggs quickly and set aside.',
        'Stir-fry vegetables and protein for 3–4 minutes until tender-crisp.',
        'Add cooked chilled rice, sauce, and eggs, tossing vigorously until heated through.',
      ];
    }
    if (lowerName.contains('pasta') || lowerName.contains('alfredo') || lowerName.contains('spaghetti')) {
      return [
        'Cook pasta in a large pot of salted boiling water until al dente.',
        'In a pan, melt butter with minced garlic and warm gently over medium heat.',
        'Pour in cream and stir in grated cheese until a silky sauce forms.',
        'Toss pasta in the sauce, garnish with fresh herbs, and serve immediately.',
      ];
    }

    switch (cat) {
      case 'chicken':
        return [
          'Rinse and pat dry the chicken, then season evenly with salt, pepper, and minced garlic.',
          'Heat olive oil in a skillet over medium-high heat until shimmering.',
          'Sear chicken for 6–8 minutes per side until golden brown and cooked thoroughly.',
          'Allow to rest for 5 minutes before slicing. Serve warm with your favorite sides.',
        ];
      case 'breakfast':
        return [
          'Whisk the eggs, milk, a pinch of salt, and pepper together in a mixing bowl.',
          'Melt butter in a non-stick skillet over low-to-medium heat.',
          'Pour in the egg mixture and gently fold with a spatula until soft curds form.',
          'Serve immediately alongside warm toasted bread and fresh fruit.',
        ];
      case 'dessert':
      case 'cake':
        return [
          'Preheat your oven to 350°F (175°C) and lightly grease the baking dish.',
          'Beat butter and sugar together until creamy and pale in color.',
          'Gradually mix in eggs, flour, and vanilla extract until a smooth batter forms.',
          'Bake for 25–30 minutes until golden and a toothpick inserted into center comes out clean.',
        ];
      case 'dinner':
      case 'beef':
        return [
          'Season the meat generously with salt, pepper, and finely minced garlic.',
          'Heat olive oil in a pan over high heat, then sear meat until browned on all sides.',
          'Reduce heat to medium, add sliced onions, and cook to desired tenderness.',
          'Garnish with fresh herbs and serve hot.',
        ];
      case 'vegetables':
      case 'vegetarian':
        return [
          'Wash, peel, and cut fresh vegetables into uniform bite-sized pieces.',
          'Toss vegetables with olive oil, minced garlic, sea salt, and black pepper in a bowl.',
          'Roast in an oven at 400°F (200°C) or sauté in a skillet for 15–20 minutes until tender-crisp.',
          'Drizzle with fresh lemon juice and serve immediately.',
        ];
      case 'pasta':
        return [
          'Bring a large pot of salted water to a rolling boil and cook pasta until al dente.',
          'Meanwhile, warm olive oil and sauté minced garlic in a separate pan until aromatic.',
          'Drain pasta, reserving a small splash of pasta water, then toss into the garlic oil.',
          'Stir in grated Parmesan and fresh basil, then serve immediately.',
        ];
      default:
        return [
          'Prepare and measure all fresh ingredients according to the ingredient checklist.',
          'Heat cooking oil in a pan over medium heat and sauté aromatics until fragrant.',
          'Add primary ingredients and seasonings, cooking thoroughly to the recommended temperature.',
          'Plate nicely, garnish with fresh herbs, and enjoy warm.',
        ];
    }
  }

  static String defaultCategoryImage(String category) {
    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'breakfast':
        return 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?auto=format&fit=crop&w=800&q=80';
      case 'dessert':
      case 'cake':
      case 'sweet':
        return 'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=800&q=80';
      case 'dinner':
        return 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80';
      case 'lunch':
        return 'https://images.unsplash.com/photo-1563379091339-03246963d96c?auto=format&fit=crop&w=800&q=80';
      case 'vegetables':
      case 'vegetarian':
      case 'salad':
        return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80';
      case 'chicken':
        return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=800&q=80';
      case 'beef':
      case 'meat':
        return 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80';
      case 'seafood':
      case 'fish':
        return 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80';
      case 'pasta':
      case 'noodles':
        return 'https://images.unsplash.com/photo-1621996346565-e3d5d628169a?auto=format&fit=crop&w=800&q=80';
      default:
        return 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?auto=format&fit=crop&w=800&q=80';
    }
  }

  Recipe copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? calorie,
    String? category,
    String? image,
    double? rating,
    int? review,
    int? time,
    int? servings,
    String? difficulty,
    List<String>? ingredientImage,
    List<String>? ingredientName,
    List<String>? ingredientAmount,
    List<String>? instructions,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      calorie: calorie ?? this.calorie,
      category: category ?? this.category,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      time: time ?? this.time,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      ingredientImage: ingredientImage ?? this.ingredientImage,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientAmount: ingredientAmount ?? this.ingredientAmount,
      instructions: instructions ?? this.instructions,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'calorie': calorie,
      'category': category,
      'image': image,
      'rating': rating,
      'review': review,
      'time': time,
      'servings': servings,
      'difficulty': difficulty,
      'ingredientImage': ingredientImage,
      'ingredientName': ingredientName,
      'ingredientAmount': ingredientAmount,
      'instructions': instructions,
      'isFavorite': isFavorite,
    };
  }

  static String _cleanCalorieString(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty) return '';
    return str.replaceAll(RegExp(r'\s*(kcal|cal|calories)\s*', caseSensitive: false), '').trim();
  }

  static int? _extractMinutesFromName(String name) {
    final match = RegExp(r'(\d+)\s*[- ]?min', caseSensitive: false).firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
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