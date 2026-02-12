import 'package:flutter/material.dart';

class AppColors {
  // --- Healing Teal Palette (Primary) ---
  static const Color primary = Color(0xFF0F766E); // Deep Healing Teal
  static const Color primaryLight = Color(0xFF14B8A6); // Vibrant Teal
  static const Color primarySoft = Color(0xFFF0FDFA); // Subtle Teal Tint

  // --- Serene Blue Palette (Secondary) ---
  static const Color secondary = Color(0xFF0EA5E9); // Serene Sky Blue
  static const Color azureSoft = Color(0xFFF0F9FF); // Soft Azure Tint

  // --- Warmth & Action ---
  static const Color accent = Color(0xFFF97316); // Energy Orange
  static const Color success = Color(0xFF10B981); // Trust Green
  static const Color error = Color(0xFFEF4444); // Error Red
  static const Color warning = Color(0xFFF59E0B); // Caution Amber

  // --- Light Theme Colors ---
  static const Color background = Color(0xFFF8FAFC); // Cool Slate White
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Subtle Border Slate

  static const Color textPrimary = Color(0xFF0F172A); // Midnight Slate
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate
  static const Color textPlaceholder = Color(0xFF94A3B8);

  // --- Dark Theme Colors ---
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF3A3A3A);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textPlaceholderDark = Color(0xFF6A6A6A);

  // --- Gradients ---
  static const LinearGradient healingGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Helper Methods ---
  /// Get theme-aware surface color
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surface;
  }

  /// Get theme-aware background color
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : background;
  }

  /// Get theme-aware border color
  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderDark
        : border;
  }

  /// Get theme-aware text primary color
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimary;
  }

  /// Get theme-aware text secondary color
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondary;
  }
}
