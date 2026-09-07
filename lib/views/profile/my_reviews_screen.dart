import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/review_service.dart';
import '../../utils/app_colors.dart';
import '../detail/recipe_detail_screen.dart';

/// Screen displaying all reviews written by the currently logged-in user.
class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reviewService = context.watch<ReviewService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    if (!auth.isAuthenticated || auth.isAnonymous) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reviews')),
        body: Center(
          child: Text(
            'Please sign in to view your reviews.',
            style: TextStyle(color: textGrey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: StreamBuilder<List<ReviewModel>>(
            stream: reviewService.getUserReviews(auth.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.star_1, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews written yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cook a recipe, rate it, and share your tips with fellow home chefs!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: textGrey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Explore Recipes'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _UserReviewCard(review: review);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _UserReviewCard({required this.review});

  void _navigateToRecipe(BuildContext context) {
    final recipeProvider = context.read<RecipeProvider>();
    final matched = recipeProvider.allRecipes.where((r) => r.id == review.recipeId).toList();
    if (matched.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipe: matched.first,
            heroTag: 'my-review-${review.id}-${review.recipeId}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe details not found in current catalogue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to remove your review for this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reviewService = context.read<ReviewService>();
              await reviewService.deleteReview(
                categoryId: review.categoryId,
                recipeId: review.recipeId,
                userId: review.userId,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review deleted.'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editReview(BuildContext context) {
    final commentController = TextEditingController(text: review.comment);
    int currentRating = review.rating;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final inputFill = isDark ? const Color(0xFF282832) : AppColors.scaffold;

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
                  'Edit Review for ${review.recipeName}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
                ),
                const SizedBox(height: 14),

                // Star selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (starIdx) {
                    final ratingVal = starIdx + 1;
                    return IconButton(
                      icon: Icon(
                        ratingVal <= currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: ratingVal <= currentRating ? AppColors.star : Colors.grey,
                      ),
                      onPressed: () => setModalState(() => currentRating = ratingVal),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your updated thoughts on this recipe…',
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final reviewService = context.read<ReviewService>();
                      await reviewService.submitOrUpdateReview(
                        categoryId: review.categoryId,
                        recipeId: review.recipeId,
                        recipeName: review.recipeName,
                        userId: review.userId,
                        userName: review.userName,
                        userPhotoUrl: review.userPhotoUrl,
                        rating: currentRating,
                        comment: commentController.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review updated!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    final dateStr = review.createdAt != null
        ? '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}'
        : '';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Recipe Name & Action Icons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToRecipe(context),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          review.recipeName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.edit, size: 18, color: AppColors.textGrey),
                onPressed: () => _editReview(context),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Iconsax.trash, size: 18, color: Colors.red),
                onPressed: () => _confirmDelete(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Rating stars and date
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: i < review.rating ? AppColors.star : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: textGrey),
                ),
            ],
          ),

          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: textDark,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
