import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';
import '../detail/recipe_detail_screen.dart';

/// A reusable card shown in the recipe grid on the Home and Favorites screens.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String? heroTag;

  const RecipeCard({super.key, required this.recipe, this.heroTag});

  void _handleFavoriteTap(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isAnonymous) {
      _showSignInPrompt(context);
      return;
    }
    context.read<RecipeProvider>().toggleFavorite(recipe);
  }

  void _showSignInPrompt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.heart, color: AppColors.favorite, size: 22),
            const SizedBox(width: 8),
            const Text('Save to Favorites'),
          ],
        ),
        content: const Text(
          'Please sign in or create an account to save recipes to your personal favorites collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeroTag = heroTag ?? 'recipe-image-${recipe.id}';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final badgeBg = isDark ? const Color(0xFF3B2016) : AppColors.primaryLight;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipe: recipe,
            heroTag: effectiveHeroTag,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image with favorite button ─────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: effectiveHeroTag,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: recipe.image.isNotEmpty
                          ? Image.network(
                              recipe.image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) =>
                                  _fallbackImage(recipe.category),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: badgeBg,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _fallbackImage(recipe.category),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleFavoriteTap(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF1E1E24) : Colors.white).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          recipe.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                          size: 16,
                          color: recipe.isFavorite
                              ? AppColors.favorite
                              : textGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info section ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Rating
                      const Icon(Iconsax.star_1, size: 12, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        recipe.displayRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          color: textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Time
                      Icon(Iconsax.clock, size: 12, color: textGrey),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.displayTime} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Calorie badge
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recipe.displayCalorie,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262634) : const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: TextStyle(
                            fontSize: 9,
                            color: textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(String category) {
    final fallbackUrl = Recipe.defaultCategoryImage(category);
    return Image.network(
      fallbackUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Iconsax.image, size: 40, color: AppColors.primary),
      ),
    );
  }
}
