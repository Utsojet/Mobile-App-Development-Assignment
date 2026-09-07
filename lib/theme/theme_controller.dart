import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages application theme mode with SharedPreferences local persistence
/// and Cloud Firestore synchronization for authenticated users.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  final FirebaseFirestore? _customFirestore;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeController({FirebaseFirestore? firestore})
      : _customFirestore = firestore {
    _loadFromPrefs();
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        _themeMode = _parseThemeMode(saved);
        notifyListeners();
      }
    } catch (_) {
      // Fallback to system default if SharedPreferences read fails
    }
  }

  /// Sets the application theme mode, caching it locally and optionally syncing to Firestore.
  Future<void> setThemeMode(ThemeMode mode, {String? userId}) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, themeModeString);
    } catch (_) {}

    if (userId != null && userId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'themeMode': themeModeString,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Syncs the theme from Firestore user document (if set).
  void syncFromUserDoc(String? firestoreThemeMode) {
    if (firestoreThemeMode == null || firestoreThemeMode.isEmpty) return;
    final mode = _parseThemeMode(firestoreThemeMode);
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_prefKey, themeModeString);
      }).catchError((_) {});
    }
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value.trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
