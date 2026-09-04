import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/ingredient_scaler.dart';

/// Full-screen detail view for a single recipe.
///
/// Resets the serving counter to 1 on entry via [RecipeProvider.resetServings].
/// Ingredient amounts are scaled proportionally using [IngredientScaler.scale].
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final String? heroTag;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.heroTag,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Reset to 1 serving each time this screen is opened so stale state
    // from a previous recipe visit doesn't bleed through.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecipeProvider>().resetServings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for live serving count updates.
    final provider = context.watch<RecipeProvider>();
    final recipe = widget.recipe;
    final servings = provider.servings;

    // Find the live version of this recipe (for isFavorite sync).
    final liveRecipe = provider.allRecipes.firstWhere(
      (r) => r.id == recipe.id,
      orElse: () => recipe,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textDark, size: 18),
              ),
            ),
            actions: [
              // ── Favorite toggle ──────────────────────────────────────
              GestureDetector(
                onTap: () => provider.toggleFavorite(liveRecipe),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    liveRecipe.isFavorite
                        ? Iconsax.heart_add
                        : Iconsax.heart,
                    color: liveRecipe.isFavorite
                        ? AppColors.favorite
                        : AppColors.textGrey,
                    size: 22,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag ?? 'recipe-image-${recipe.id}',
                child: recipe.image.isNotEmpty
                    ? Image.network(
                        recipe.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => Container(
                          color: AppColors.primaryLight,
                          child: const Center(
                            child: Icon(Iconsax.image,
                                size: 60, color: AppColors.primary),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: Icon(Iconsax.image,
                              size: 60, color: AppColors.primary),
                        ),
                      ),
              ),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ───────────────────────────────────────────
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.category,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats row ────────────────────────────────────────
                  _StatsRow(recipe: recipe),
                  const SizedBox(height: 24),

                  // ── Serving counter ──────────────────────────────────
                  _ServingCounter(provider: provider, servings: servings),
                  const SizedBox(height: 24),

                  // ── Ingredients ──────────────────────────────────────
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _IngredientsList(recipe: recipe, servings: servings),
                  if (recipe.instructions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InstructionsList(instructions: recipe.instructions),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row — calories, time, rating, reviews
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Recipe recipe;

  const _StatsRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Iconsax.flash_1,
          iconColor: AppColors.primary,
          label: '${recipe.calorie} kcal',
          sublabel: 'Calories',
        ),
        const _Divider(),
        _StatItem(
          icon: Iconsax.clock,
          iconColor: Colors.blue,
          label: '${recipe.time} min',
          sublabel: 'Cook time',
        ),
        const _Divider(),
        _StatItem(
          icon: Iconsax.star_1,
          iconColor: AppColors.star,
          label: recipe.rating.toStringAsFixed(1),
          sublabel: '${recipe.review} reviews',
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Serving counter
// ─────────────────────────────────────────────────────────────────────────────
class _ServingCounter extends StatelessWidget {
  final RecipeProvider provider;
  final int servings;

  const _ServingCounter({required this.provider, required this.servings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Iconsax.profile_2user, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Servings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Decrement
          _CounterButton(
            icon: Icons.remove,
            onTap: provider.decrementServings,
            enabled: servings > 1,
          ),
          const SizedBox(width: 16),
          Text(
            '$servings',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          // Increment
          _CounterButton(
            icon: Icons.add,
            onTap: provider.incrementServings,
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : AppColors.textGrey, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredients list with proportional scaling
// ─────────────────────────────────────────────────────────────────────────────
class _IngredientsList extends StatelessWidget {
  final Recipe recipe;
  final int servings;

  const _IngredientsList({required this.recipe, required this.servings});

  @override
  Widget build(BuildContext context) {
    final count = recipe.ingredientName.length;
    if (count == 0) {
      return const Center(
        child: Text('No ingredients listed.',
            style: TextStyle(color: AppColors.textGrey)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, index) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final name = recipe.ingredientName[index];
        final rawAmount = index < recipe.ingredientAmount.length
            ? recipe.ingredientAmount[index]
            : '';
        final imageUrl = index < recipe.ingredientImage.length
            ? recipe.ingredientImage[index]
            : '';
        // Scale the base amount by the current serving multiplier.
        final scaledAmount = IngredientScaler.scale(rawAmount, servings);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Ingredient image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) =>
                            _ingredientPlaceholder(),
                      )
                    : _ingredientPlaceholder(),
              ),
              const SizedBox(width: 14),

              // Name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              // Scaled amount badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  scaledAmount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ingredientPlaceholder() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Iconsax.image, color: AppColors.primary, size: 22),
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final List<String> instructions;

  const _InstructionsList({required this.instructions});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: instructions.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instructions[index],
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
