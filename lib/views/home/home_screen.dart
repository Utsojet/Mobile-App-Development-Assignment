import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';
import 'recipe_card.dart';

/// The main Home screen featuring a search bar, horizontal category filter,
/// and a real-time recipe grid sourced from Cloud Firestore.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Best',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Text(
                    'Recipes 🍳',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Search bar ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search recipes or ingredients…',
                        hintStyle: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Iconsax.search_normal,
                          color: AppColors.textGrey,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textGrey),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Categories strip ─────────────────────────────────────────
            _CategoriesBar(provider: provider),

            const SizedBox(height: 12),

            // ── Recipe grid / loading / empty ────────────────────────────
            Expanded(child: _RecipeGrid(provider: provider)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal categories bar
// ─────────────────────────────────────────────────────────────────────────────
class _CategoriesBar extends StatelessWidget {
  final RecipeProvider provider;

  const _CategoriesBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...provider.categories.map((c) => c.name)];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final name = categories[index];
          final isSelected = provider.selectedCategory == name;
          return GestureDetector(
            onTap: () => provider.setSelectedCategory(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textGrey,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe grid
// ─────────────────────────────────────────────────────────────────────────────
class _RecipeGrid extends StatelessWidget {
  final RecipeProvider provider;

  const _RecipeGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Oops! Something went wrong.\n${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    final recipes = provider.filteredRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.image, size: 64, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No recipes found for\n"${provider.searchQuery}"'
                  : 'No recipes in this category yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: recipes.length,
      itemBuilder: (_, index) => RecipeCard(
        recipe: recipes[index],
        heroTag: 'home-${recipes[index].id}-$index',
      ),
    );
  }
}
