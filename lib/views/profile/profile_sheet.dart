import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../auth/register_screen.dart';
import '../recipe/add_recipe_screen.dart';
import 'profile_screen.dart';
import 'theme_settings_screen.dart';

/// Modal bottom sheet displaying the current user's profile summary and quick actions.
class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isAnonymous || !auth.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final photoUrl = auth.photoUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ───────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // ── Avatar ───────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isGuest
                  ? textGrey.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        isGuest ? Iconsax.user : Iconsax.lamp_charge,
                        size: 36,
                        color: isGuest ? textGrey : AppColors.primary,
                      ),
                    )
                  : Icon(
                      isGuest ? Iconsax.user : Iconsax.lamp_charge,
                      size: 36,
                      color: isGuest ? textGrey : AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Display Name ─────────────────────────────────────────────
          Text(
            auth.displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),

          // ── Email / Guest Status ─────────────────────────────────────
          Text(
            auth.email,
            style: TextStyle(
              fontSize: 14,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 12),

          // ── Mode Badge ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  isGuest ? 'Guest Mode' : 'Verified Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isGuest ? Colors.amber[800] : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── If Guest: Upgrade Prompt ─────────────────────────────────
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262630) : AppColors.scaffold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Want to sync your favorites across devices?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Create an Account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── View Full Profile ────────────────────────────────────────
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.profile_circle, color: AppColors.primary, size: 20),
            ),
            title: Text(
              'View Full Profile',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: Icon(Iconsax.arrow_right_3, size: 16, color: textGrey),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          // ── Theme Settings ──────────────────────────────────────────
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.colorfilter, color: Colors.teal, size: 20),
            ),
            title: Text(
              'Theme Settings',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: Icon(Iconsax.arrow_right_3, size: 16, color: textGrey),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
              );
            },
          ),

          // ── Create Recipe Button ────────────────────────────────────
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.add_circle, color: AppColors.primary, size: 20),
            ),
            title: Text(
              'Add New Recipe',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: Icon(Iconsax.arrow_right_3, size: 16, color: textGrey),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
              );
            },
          ),

          // ── Sign Out Button ──────────────────────────────────────────
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.logout, color: Colors.red, size: 20),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
    );
  }
}
