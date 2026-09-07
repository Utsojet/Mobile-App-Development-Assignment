import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/recipe_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/review_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/ingredient_scaler.dart';
import '../auth/login_screen.dart';

/// Full-screen detail view for a single recipe.
///
/// Features proportional ingredient scaling, instructions, and an interactive
/// real-time reviews and rating system.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecipeProvider>().resetServings(widget.recipe.servings);
      }
    });
  }

  void _handleFavoriteTap(BuildContext context, Recipe recipe) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isAnonymous) {
      _showSignInPrompt(context, 'save this recipe to your favorites');
      return;
    }
    context.read<RecipeProvider>().toggleFavorite(recipe);
  }

  void _showSignInPrompt(BuildContext context, String actionText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.lock, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Sign In Required'),
          ],
        ),
        content: Text('Please sign in or create an account to $actionText.'),
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
    final provider = context.watch<RecipeProvider>();
    final recipe = widget.recipe;
    final servings = provider.servings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    // Find the live version of this recipe (for rating and isFavorite sync).
    final liveRecipe = provider.allRecipes.firstWhere(
      (r) => r.id == recipe.id,
      orElse: () => recipe,
    );

    return Scaffold(
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
                  color: (isDark ? const Color(0xFF1E1E24) : Colors.white).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new, color: textDark, size: 18),
              ),
            ),
            actions: [
              // ── Favorite toggle ──────────────────────────────────────
              GestureDetector(
                onTap: () => _handleFavoriteTap(context, liveRecipe),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E1E24) : Colors.white).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    liveRecipe.isFavorite ? Iconsax.heart_add : Iconsax.heart,
                    color: liveRecipe.isFavorite ? AppColors.favorite : textGrey,
                    size: 22,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag ?? 'recipe-image-${recipe.id}',
                child: Image.network(
                  liveRecipe.image.isNotEmpty
                      ? liveRecipe.image
                      : Recipe.defaultCategoryImage(liveRecipe.category),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Image.network(
                    Recipe.defaultCategoryImage(liveRecipe.category),
                    fit: BoxFit.cover,
                    errorBuilder: (context, err, stack) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(Iconsax.image, size: 60, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ───────────────────────────────────────────
                      Text(
                        liveRecipe.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveRecipe.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Stats row ────────────────────────────────────────
                      _StatsRow(recipe: liveRecipe),
                      const SizedBox(height: 24),

                      // ── Serving counter ──────────────────────────────────
                      _ServingCounter(provider: provider, servings: servings),
                      const SizedBox(height: 24),

                      // ── Ingredients ──────────────────────────────────────
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _IngredientsList(recipe: liveRecipe, servings: servings),

                      if (liveRecipe.instructions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InstructionsList(instructions: liveRecipe.instructions),
                      ],

                      const SizedBox(height: 30),

                      // ── Reviews & Ratings Section ────────────────────────
                      _ReviewsSection(
                        recipe: liveRecipe,
                        onRequireAuth: () => _showSignInPrompt(context, 'write a review for this recipe'),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row — calories, time, difficulty, rating & reviews
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Recipe recipe;

  const _StatsRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final reviewService = context.watch<ReviewService>();

    return StreamBuilder<List<ReviewModel>>(
      stream: reviewService.getRecipeReviews(recipe.categoryId, recipe.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        final reviewCount = reviews.isNotEmpty ? reviews.length : recipe.displayReview;
        final ratingVal = reviews.isNotEmpty
            ? (reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length)
            : recipe.displayRating;

        return Row(
          children: [
            _StatItem(
              icon: Iconsax.flash_1,
              iconColor: AppColors.primary,
              label: recipe.displayCalorie,
              sublabel: 'Calories',
            ),
            const _Divider(),
            _StatItem(
              icon: Iconsax.clock,
              iconColor: Colors.blue,
              label: '${recipe.displayTime} min',
              sublabel: 'Cook time',
            ),
            const _Divider(),
            _StatItem(
              icon: Iconsax.award,
              iconColor: Colors.orange,
              label: recipe.difficulty,
              sublabel: 'Difficulty',
            ),
            const _Divider(),
            _StatItem(
              icon: Iconsax.star_1,
              iconColor: AppColors.star,
              label: ratingVal.toStringAsFixed(1),
              sublabel: '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
            ),
          ],
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: textGrey),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 50,
      color: isDark ? const Color(0xFF2A2A36) : AppColors.divider,
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
    final cardBg = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
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
          Expanded(
            child: Text(
              'Servings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textDark,
              ),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : (isDark ? const Color(0xFF2A2A36) : AppColors.divider),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final dividerColor = isDark ? const Color(0xFF2A2A36) : AppColors.divider;
    final badgeBg = isDark ? const Color(0xFF3B2016) : AppColors.primaryLight;

    if (count == 0) {
      return Center(
        child: Text('No ingredients listed.', style: TextStyle(color: textGrey)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, index) => Divider(color: dividerColor, height: 1),
      itemBuilder: (context, index) {
        final name = recipe.ingredientName[index];
        final rawAmount = index < recipe.ingredientAmount.length
            ? recipe.ingredientAmount[index]
            : '';
        final rawImg = index < recipe.ingredientImage.length
            ? recipe.ingredientImage[index].trim()
            : '';
        final cleanName = name.trim();
        final imageUrl = rawImg.isNotEmpty
            ? rawImg
            : (cleanName.isNotEmpty
                ? Recipe.resolveTheMealDbIngredientUrl(cleanName)
                : '');
        final scaledAmount = IngredientScaler.scale(rawAmount, servings);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) =>
                            _ingredientPlaceholder(name),
                      )
                    : _ingredientPlaceholder(name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
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

  Widget _ingredientPlaceholder([String? name]) {
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : '';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: initial.isNotEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Iconsax.image, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final List<String> instructions;

  const _InstructionsList({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;

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
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: textDark,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class _ReviewsSection extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onRequireAuth;

  const _ReviewsSection({
    required this.recipe,
    required this.onRequireAuth,
  });

  void _openReviewModal(BuildContext context, {ReviewModel? existingReview}) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.isAnonymous) {
      onRequireAuth();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final inputFill = isDark ? const Color(0xFF282832) : AppColors.scaffold;

    int currentRating = existingReview?.rating ?? 5;
    final commentController = TextEditingController(text: existingReview?.comment ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existingReview != null ? 'Edit Your Review' : 'Write a Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.name,
                  style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Star selector
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (idx) {
                      final starValue = idx + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 38,
                          color: starValue <= currentRating ? AppColors.star : Colors.grey,
                        ),
                        onPressed: () => setModalState(() => currentRating = starValue),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'What did you think? Any substitutions or cooking tips for others?…',
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    if (existingReview != null) ...[
                      IconButton(
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final reviewService = context.read<ReviewService>();
                          await reviewService.deleteReview(
                            categoryId: recipe.categoryId,
                            recipeId: recipe.id,
                            userId: auth.user!.uid,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review deleted.'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            Navigator.of(ctx).pop();
                            final reviewService = context.read<ReviewService>();
                            await reviewService.submitOrUpdateReview(
                              categoryId: recipe.categoryId,
                              recipeId: recipe.id,
                              recipeName: recipe.name,
                              userId: auth.user!.uid,
                              userName: auth.displayName,
                              userPhotoUrl: auth.photoUrl,
                              rating: currentRating,
                              comment: comment,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(existingReview != null ? 'Review updated!' : 'Review posted!'),
                                  backgroundColor: Colors.green[700],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            existingReview != null ? 'Save Changes' : 'Submit Review',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reviewService = context.watch<ReviewService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    return StreamBuilder<List<ReviewModel>>(
      stream: reviewService.getRecipeReviews(recipe.categoryId, recipe.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        final currentUid = auth.user?.uid;
        final myReviewIndex = currentUid != null && !auth.isAnonymous
            ? reviews.indexWhere((r) => r.userId == currentUid)
            : -1;
        final myReview = myReviewIndex != -1 ? reviews[myReviewIndex] : null;

        final reviewCount = reviews.isNotEmpty ? reviews.length : recipe.displayReview;
        final ratingVal = reviews.isNotEmpty
            ? (reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length)
            : recipe.displayRating;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title & Write Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openReviewModal(
                    context,
                    existingReview: myReview,
                  ),
                  icon: Icon(
                    myReview != null ? Iconsax.edit : Iconsax.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    myReview != null ? 'Edit Review' : 'Write Review',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ratingVal.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '/ 5.0',
                              style: TextStyle(fontSize: 14, color: textGrey),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < ratingVal.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 18,
                            color: i < ratingVal.round() ? AppColors.star : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$reviewCount ${reviewCount == 1 ? 'Review' : 'Reviews'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reviews List
            if (reviews.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Iconsax.message_text, size: 36, color: textGrey.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'No reviews yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Have you tried this recipe? Be the first to leave a review!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final isMyReview = review.userId == currentUid;
                  return _ReviewCard(
                    review: review,
                    isMyReview: isMyReview,
                    onEdit: () => _openReviewModal(context, existingReview: review),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isMyReview;
  final VoidCallback onEdit;

  const _ReviewCard({
    required this.review,
    required this.isMyReview,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    final dateStr = review.createdAt != null
        ? '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isMyReview ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: review.userPhotoUrl.isNotEmpty ? NetworkImage(review.userPhotoUrl) : null,
                child: review.userPhotoUrl.isEmpty
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMyReview) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 13,
                              color: i < review.rating ? AppColors.star : Colors.grey,
                            ),
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(dateStr, style: TextStyle(fontSize: 11, color: textGrey)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isMyReview)
                IconButton(
                  icon: const Icon(Iconsax.edit, size: 16, color: AppColors.textGrey),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
