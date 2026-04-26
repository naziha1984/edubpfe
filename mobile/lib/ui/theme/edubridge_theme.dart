import 'package:flutter/material.dart';
import 'edubridge_colors.dart';
import 'edubridge_design_system.dart';
import 'edubridge_typography.dart';

/// Design System EduBridge - Material 3
/// Thème moderne avec glassmorphism, gradients doux, et animations fluides
class EduBridgeTheme {
  // Radius constants
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radius2XL = 24.0;
  static const double radiusFull = 9999.0;

  // Spacing constants
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacing2XL = 48.0;

  // Elevation constants (Material 3)
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 3.0;
  static const double elevation3 = 6.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;

  /// Thème clair Material 3
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: EduBridgeColors.primary,
      brightness: Brightness.light,
      primary: EduBridgeColors.primary,
      secondary: EduBridgeColors.secondary,
      surface: EduBridgeColors.surface,
      background: EduBridgeColors.background,
      error: EduBridgeColors.error,
      onPrimary: EduBridgeColors.textOnPrimary,
      onSecondary: EduBridgeColors.textOnPrimary,
      onSurface: EduBridgeColors.textPrimary,
      onBackground: EduBridgeColors.textPrimary,
      onError: EduBridgeColors.textOnPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Scaffold
      scaffoldBackgroundColor: EduBridgeColors.background,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: EduBridgeColors.textPrimary,
        titleTextStyle: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme — surface élevée, ombre portée douce
      cardTheme: EDSComponentThemes.card(false),

      // Input Decoration Theme
      inputDecorationTheme: EDSComponentThemes.input(false),

      // Elevated Button Theme
      elevatedButtonTheme: EDSComponentThemes.elevatedButton(false),

      // Text Button Theme
      textButtonTheme: EDSComponentThemes.textButton(false),

      // Outlined Button Theme
      outlinedButtonTheme: EDSComponentThemes.outlinedButton(false),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        backgroundColor: EduBridgeColors.primary,
        foregroundColor: EduBridgeColors.textOnPrimary,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: EduBridgeTypography.displayLarge.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        displayMedium: EduBridgeTypography.displayMedium.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        displaySmall: EduBridgeTypography.displaySmall.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        headlineLarge: EduBridgeTypography.headlineLarge.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        headlineMedium: EduBridgeTypography.headlineMedium.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        headlineSmall: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        titleLarge: EduBridgeTypography.titleLarge.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        titleMedium: EduBridgeTypography.titleMedium.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        titleSmall: EduBridgeTypography.titleSmall.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        bodyLarge: EduBridgeTypography.bodyLarge.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        bodyMedium: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.textSecondary,
        ),
        bodySmall: EduBridgeTypography.bodySmall.copyWith(
          color: EduBridgeColors.textSecondary,
        ),
        labelLarge: EduBridgeTypography.labelLarge.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        labelMedium: EduBridgeTypography.labelMedium.copyWith(
          color: EduBridgeColors.textSecondary,
        ),
        labelSmall: EduBridgeTypography.labelSmall.copyWith(
          color: EduBridgeColors.textTertiary,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: EduBridgeColors.textPrimary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: EduBridgeColors.textTertiary.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: EDSComponentThemes.chip(false),

      // Design-system extensions: badges/chips tokens
      extensions: <ThemeExtension<dynamic>>[
        EDSComponentThemes.badgeTokens(false),
        EDSComponentThemes.chipTokens(false),
      ],

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EduBridgeColors.textPrimary,
        contentTextStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation3,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: EduBridgeColors.surface,
        elevation: elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        contentTextStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: EduBridgeColors.surface,
        elevation: elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXL),
          ),
        ),
      ),
    );
  }

  /// Thème sombre — ardoise profonde, pas de noir pur.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: EduBridgeColors.primaryLight,
      brightness: Brightness.dark,
      primary: EduBridgeColors.primaryLight,
      onPrimary: Colors.white,
      secondary: EduBridgeColors.secondaryLight,
      onSecondary: Colors.white,
      surface: EduBridgeColors.darkSurface,
      error: EduBridgeColors.errorLight,
      onError: Colors.white,
      onSurface: EduBridgeColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: EduBridgeColors.darkBackground,
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: EduBridgeColors.darkTextPrimary,
        titleTextStyle: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: EDSComponentThemes.card(true),
      inputDecorationTheme: EDSComponentThemes.input(true),
      elevatedButtonTheme: EDSComponentThemes.elevatedButton(true),
      textButtonTheme: EDSComponentThemes.textButton(true),
      outlinedButtonTheme: EDSComponentThemes.outlinedButton(true),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        backgroundColor: EduBridgeColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: EduBridgeTypography.displayLarge.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        displayMedium: EduBridgeTypography.displayMedium.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        displaySmall: EduBridgeTypography.displaySmall.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        headlineLarge: EduBridgeTypography.headlineLarge.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        headlineMedium: EduBridgeTypography.headlineMedium.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        headlineSmall: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        titleLarge: EduBridgeTypography.titleLarge.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        titleMedium: EduBridgeTypography.titleMedium.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        titleSmall: EduBridgeTypography.titleSmall.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        bodyLarge: EduBridgeTypography.bodyLarge.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        bodyMedium: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.darkTextSecondary,
        ),
        bodySmall: EduBridgeTypography.bodySmall.copyWith(
          color: EduBridgeColors.darkTextSecondary,
        ),
        labelLarge: EduBridgeTypography.labelLarge.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        labelMedium: EduBridgeTypography.labelMedium.copyWith(
          color: EduBridgeColors.darkTextSecondary,
        ),
        labelSmall: EduBridgeTypography.labelSmall.copyWith(
          color: EduBridgeColors.darkTextTertiary,
        ),
      ),
      iconTheme: IconThemeData(
        color: EduBridgeColors.darkTextPrimary,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: EduBridgeColors.darkTextTertiary.withOpacity(0.25),
        thickness: 1,
        space: 1,
      ),
      chipTheme: EDSComponentThemes.chip(true),
      extensions: <ThemeExtension<dynamic>>[
        EDSComponentThemes.badgeTokens(true),
        EDSComponentThemes.chipTokens(true),
      ],
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EduBridgeColors.darkSurfaceVariant,
        contentTextStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EduBridgeColors.darkSurface,
        elevation: elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: EduBridgeTypography.headlineSmall.copyWith(
          color: EduBridgeColors.darkTextPrimary,
        ),
        contentTextStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.darkTextSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: EduBridgeColors.darkSurface,
        elevation: elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXL),
          ),
        ),
      ),
    );
  }
}
