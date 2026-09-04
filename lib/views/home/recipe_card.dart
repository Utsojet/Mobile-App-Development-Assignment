import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/recipe_model.dart';
import '../../utils/app_colors.dart';
import '../detail/recipe_detail_screen.dart';

/// A reusable card shown in the recipe grid on the Home and Favorites screens.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String? heroTag;

  const RecipeCard({super.key, required this.recipe, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final effectiveHeroTag = heroTag ?? 'recipe-image-${recipe.id}';

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
          color: AppColors.card,
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
            // ── Hero image ──────────────────────────────────────────────
            Expanded(
              child: Hero(
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
                              _placeholder(),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.primaryLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : _placeholder(),
                ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
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
                        recipe.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Time
                      const Icon(Iconsax.clock, size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.time} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Calorie badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${recipe.calorie} kcal',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
