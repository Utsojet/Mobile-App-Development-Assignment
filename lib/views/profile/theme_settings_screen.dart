import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_controller.dart';
import '../../utils/app_colors.dart';

/// Screen allowing the user to select between System, Light, and Dark themes.
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
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
              padding: const EdgeInsets.all(20),
              children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 12),

            _ThemeOptionCard(
              title: 'System Default',
              subtitle: 'Match your device operating system theme',
              icon: Iconsax.mobile,
              isSelected: themeController.themeMode == ThemeMode.system,
              onTap: () => themeController.setThemeMode(
                ThemeMode.system,
                userId: auth.user?.uid,
              ),
              cardBg: cardBg,
              textDark: textDark,
              textGrey: textGrey,
            ),
            const SizedBox(height: 12),

            _ThemeOptionCard(
              title: 'Light Mode',
              subtitle: 'Bright and clean with signature orange accents',
              icon: Iconsax.sun_1,
              isSelected: themeController.themeMode == ThemeMode.light,
              onTap: () => themeController.setThemeMode(
                ThemeMode.light,
                userId: auth.user?.uid,
              ),
              cardBg: cardBg,
              textDark: textDark,
              textGrey: textGrey,
            ),
            const SizedBox(height: 12),

            _ThemeOptionCard(
              title: 'Dark Mode',
              subtitle: 'Sleek dark aesthetics, comfortable in low light',
              icon: Iconsax.moon,
              isSelected: themeController.themeMode == ThemeMode.dark,
              onTap: () => themeController.setThemeMode(
                ThemeMode.dark,
                userId: auth.user?.uid,
              ),
              cardBg: cardBg,
              textDark: textDark,
              textGrey: textGrey,
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your theme choice is stored locally and synchronized with your user account in the cloud.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFF5F5F7) : AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
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
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardBg;
  final Color textDark;
  final Color textGrey;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.cardBg,
    required this.textDark,
    required this.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
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
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : textGrey.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : textGrey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : textGrey.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
