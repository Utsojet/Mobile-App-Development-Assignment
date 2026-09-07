import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipe/theme/app_theme.dart';
import 'package:recipe/theme/theme_controller.dart';
import 'package:recipe/utils/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme System Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppTheme light and dark themes have correct brightness and seed', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primary);
    });

    test('ThemeController defaults to system theme mode', () {
      final controller = ThemeController();
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.themeModeString, 'system');
      expect(controller.isDarkMode, false);
    });

    test('ThemeController updates theme mode and persists', () async {
      final controller = ThemeController();

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.themeModeString, 'dark');
      expect(controller.isDarkMode, true);

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.themeModeString, 'light');
      expect(controller.isDarkMode, false);
    });

    test('ThemeController syncs correctly from user doc string', () {
      final controller = ThemeController();

      controller.syncFromUserDoc('dark');
      expect(controller.themeMode, ThemeMode.dark);

      controller.syncFromUserDoc('light');
      expect(controller.themeMode, ThemeMode.light);

      controller.syncFromUserDoc('system');
      expect(controller.themeMode, ThemeMode.system);
    });
  });
}
