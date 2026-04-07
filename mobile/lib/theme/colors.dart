import 'package:flutter/material.dart';

/// EduBridge 颜色系统
class EduBridgeColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // Accent Colors
  static const Color accent = Color(0xFF06B6D4); // Cyan
  static const Color accentDark = Color(0xFF0891B2);
  static const Color accentLight = Color(0xFF22D3EE);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEF2FF),
      Color(0xFFF8FAFC),
      Color(0xFFE0F2FE),
      Color(0xFFF1F5F9),
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  // Glass Effect Colors
  static const Color glassBackground = Color(0x40FFFFFF);
  static const Color glassBorder = Color(0x80FFFFFF);
}
