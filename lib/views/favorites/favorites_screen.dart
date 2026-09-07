import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';
import '../home/recipe_card.dart';

/// Screen showing all recipes the user has marked as favorite.
/// Favorites are persisted in Firestore so they survive app restarts.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final favorites = provider.favoriteRecipes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: _FavoritesBody(
                    favorites: favorites,
                    isLoading: provider.isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  final List<Recipe> favorites;
  final bool isLoading;

  const _FavoritesBody({required this.favorites, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B2016) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.heart,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Favorites Saved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon on any recipe\nto add it to your favorites.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
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
          itemCount: favorites.length,
          itemBuilder: (_, index) => RecipeCard(
            recipe: favorites[index],
            heroTag: 'fav-${favorites[index].id}-$index',
          ),
        );
      },
    );
  }
}
