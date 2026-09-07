import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../favorites/favorites_screen.dart';
import 'change_password_dialog.dart';
import 'edit_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'theme_settings_screen.dart';

/// Full-screen user profile displaying user info, dynamic stats,
/// theme controls, and account management options.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmSignOut(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Exit profile screen
              await context.read<AuthProvider>().signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final reviewService = context.watch<ReviewService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = auth.isAnonymous || !auth.isAuthenticated;

    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final photoUrl = auth.photoUrl;

    final favCount = recipeProvider.favoriteRecipes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
            // ── User Card / Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isGuest ? Colors.amber : AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(auth, isGuest),
                            )
                          : _avatarFallback(auth, isGuest),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Display Name
                  Text(
                    auth.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    auth.email,
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                  const SizedBox(height: 10),

                  // Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isGuest
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGuest ? Iconsax.info_circle : Iconsax.verify,
                          size: 14,
                          color: isGuest ? Colors.amber[800] : Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGuest ? 'Guest User' : 'Verified Member',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isGuest ? Colors.amber[800] : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bio (if present)
                  if (!isGuest && auth.bio.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262630) : AppColors.scaffold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],

                  // If guest: Sign In / Create account CTA
                  if (isGuest) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Sign in to sync your favorite recipes, post reviews, and customize your chef profile!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Sign In', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Dynamic Stats Row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Favorites',
                    value: '$favCount',
                    icon: Iconsax.heart,
                    color: AppColors.favorite,
                    cardBg: cardBg,
                    textDark: textDark,
                    textGrey: textGrey,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<List<ReviewModel>>(
                    stream: !isGuest && auth.user != null
                        ? reviewService.getUserReviews(auth.user!.uid)
                        : Stream.value([]),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return _StatCard(
                        title: 'My Reviews',
                        value: isGuest ? '0' : '$count',
                        icon: Iconsax.star_1,
                        color: AppColors.star,
                        cardBg: cardBg,
                        textDark: textDark,
                        textGrey: textGrey,
                        onTap: isGuest
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                                );
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Menu Section ───────────────────────────────────────────────
            Text(
              'Account & Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (!isGuest) ...[
                    _MenuTile(
                      icon: Iconsax.user_edit,
                      iconColor: Colors.blue,
                      title: 'Edit Profile',
                      subtitle: 'Update name, bio, and chef avatar',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                      },
                      textDark: textDark,
                      textGrey: textGrey,
                    ),
                    _tileDivider(isDark),
                    _MenuTile(
                      icon: Iconsax.messages_3,
                      iconColor: Colors.purple,
                      title: 'My Reviews',
                      subtitle: 'Manage all recipe reviews & ratings',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                        );
                      },
                      textDark: textDark,
                      textGrey: textGrey,
                    ),
                    _tileDivider(isDark),
                  ],
                  _MenuTile(
                    icon: Iconsax.heart,
                    iconColor: AppColors.favorite,
                    title: 'My Favorites',
                    subtitle: 'Quick access to saved recipes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                    textDark: textDark,
                    textGrey: textGrey,
                  ),
                  _tileDivider(isDark),
                  _MenuTile(
                    icon: Iconsax.colorfilter,
                    iconColor: Colors.teal,
                    title: 'Theme Settings',
                    subtitle: 'Switch between light, dark, and system',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                      );
                    },
                    textDark: textDark,
                    textGrey: textGrey,
                  ),
                  if (!isGuest) ...[
                    _tileDivider(isDark),
                    _MenuTile(
                      icon: Iconsax.lock,
                      iconColor: Colors.amber[800]!,
                      title: 'Change Password',
                      subtitle: 'Update your security credentials',
                      onTap: () => ChangePasswordDialog.show(context),
                      textDark: textDark,
                      textGrey: textGrey,
                    ),
                  ],
                  _tileDivider(isDark),
                  _MenuTile(
                    icon: Iconsax.logout,
                    iconColor: Colors.red,
                    title: isGuest ? 'Exit Guest Mode' : 'Sign Out',
                    subtitle: isGuest ? 'Return to sign in' : 'Safely sign out of your account',
                    onTap: () => _confirmSignOut(context),
                    textDark: Colors.red,
                    textGrey: textGrey,
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: isDark ? const Color(0xFF2A2A36) : AppColors.divider,
    );
  }

  Widget _avatarFallback(AuthProvider auth, bool isGuest) {
    return Center(
      child: Icon(
        isGuest ? Iconsax.user : Iconsax.profile_circle,
        size: 40,
        color: isGuest ? Colors.amber[800] : AppColors.primary,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color textDark;
  final Color textGrey;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.textDark,
    required this.textGrey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: textGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color textDark;
  final Color textGrey;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.textDark,
    required this.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: textGrey),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.textGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
