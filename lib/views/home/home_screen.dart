import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';
import '../profile/profile_screen.dart';
import '../recipe/add_recipe_screen.dart';
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
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final photoUrl = auth.photoUrl;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add, size: 20),
        label: const Text(
          'Add Recipe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${auth.displayName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textGrey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Find Best',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              const Text(
                                'Recipes',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Iconsax.user,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Iconsax.user,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Search bar ──────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
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
                          style: TextStyle(color: textDark),
                          decoration: InputDecoration(
                            hintText: 'Search recipes or ingredients…',
                            hintStyle: TextStyle(
                              color: textGrey,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Iconsax.search_normal,
                              color: textGrey,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: textGrey),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    final cardBg = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

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
                color: isSelected ? AppColors.primary : cardBg,
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
                  color: isSelected ? Colors.white : textGrey,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

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
                style: TextStyle(color: textGrey),
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
              style: TextStyle(color: textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isCompact ? 220 : 280,
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
      },
    );
  }
}
