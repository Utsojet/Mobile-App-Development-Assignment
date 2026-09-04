import 'package:flutter/material.dart';

/// Central color palette for the Recipe App.
abstract final class AppColors {
  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);      // vibrant orange
  static const Color primaryLight = Color(0xFFFFEDE8);  // soft tinted background

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color scaffold = Color(0xFFF8F8F8);     // near-white
  static const Color card = Colors.white;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textLight = Colors.white;

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color star = Color(0xFFFFC107);          // amber/gold
  static const Color favorite = Color(0xFFE53935);      // deep red heart
  static const Color divider = Color(0xFFEEEEEE);
}
