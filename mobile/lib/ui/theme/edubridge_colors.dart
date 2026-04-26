import 'package:flutter/material.dart';

/// Système de couleurs EduBridge - Material 3
/// Palette moderne avec gradients doux et glassmorphism
class EduBridgeColors {
  // Brand palette (inspired by Stripe/Linear/Notion)
  static const Color brand900 = Color(0xFF312E81);
  static const Color brand800 = Color(0xFF3730A3);
  static const Color brand700 = Color(0xFF4338CA);
  static const Color brand600 = Color(0xFF4F46E5);
  static const Color brand500 = Color(0xFF6366F1);
  static const Color brand400 = Color(0xFF818CF8);
  static const Color brand300 = Color(0xFFA5B4FC);

  // Primary Colors - Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryContainer = Color(0xFFE0E7FF);

  // Secondary Colors - Purple
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryContainer = Color(0xFFEDE9FE);

  // Accent Colors - Cyan
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentDark = Color(0xFF0891B2);
  static const Color accentLight = Color(0xFF22D3EE);
  static const Color accentContainer = Color(0xFFCFFAFE);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceDim = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF1E293B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

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

  /// Fond app — diagonal doux (indigo / slate / cyan), style produit premium.
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

  // ——— Dark theme (slate / indigo, pas de noir pur) ———
  static const Color darkBackground = Color(0xFF0F1218);
  static const Color darkSurface = Color(0xFF171B24);
  static const Color darkSurfaceVariant = Color(0xFF222836);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFE8EEF4);
  static const Color darkTextSecondary = Color(0xFF9BA4B5);
  static const Color darkTextTertiary = Color(0xFF6B7588);

  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF121622),
      Color(0xFF171C28),
      Color(0xFF141A24),
      Color(0xFF0F1219),
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  static const Color glassBackgroundDark = Color(0x14FFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceVariant],
  );

  // Glass Effect Colors
  static const Color glassBackground = Color(0x40FFFFFF);
  static const Color glassBackgroundStrong = Color(0x60FFFFFF);
  static const Color glassBorder = Color(0x80FFFFFF);
  static const Color glassBorderStrong = Color(0xB3FFFFFF);

  // Shadow Colors
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get shadowPrimary => [
        BoxShadow(
          color: primary.withOpacity(0.32),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Ombre portée multicouche pour cartes (léger halo teinté + profondeur).
  static List<BoxShadow> get cardShadowLayered => [
        BoxShadow(
          color: primary.withOpacity(0.08),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> cardShadowHover(bool elevated) {
    if (elevated) {
      return [
        BoxShadow(
          color: primary.withOpacity(0.12),
          blurRadius: 36,
          spreadRadius: -4,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.09),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return cardShadowLayered;
  }

  static List<BoxShadow> get cardShadowLayeredDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.55),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: primaryLight.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> cardShadowHoverDark(bool elevated) {
    if (elevated) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.65),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: primaryLight.withOpacity(0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return cardShadowLayeredDark;
  }
}
