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

  // --- Neutral Scale (Minimalist) ---
  static const Color background = Color(0xFFF8FAFC); // Cool Slate White
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Subtle Border Slate

  static const Color textPrimary = Color(0xFF0F172A); // Midnight Slate
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate
  static const Color textPlaceholder = Color(0xFF94A3B8);

  // --- Gradients ---
  static const LinearGradient healingGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
