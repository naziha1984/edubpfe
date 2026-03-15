import 'package:flutter/material.dart';
import 'edubridge_colors.dart';
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

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        color: EduBridgeColors.surface,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EduBridgeColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: EduBridgeColors.textTertiary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: EduBridgeColors.textTertiary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: EduBridgeColors.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: EduBridgeColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: EduBridgeColors.error,
            width: 2.0,
          ),
        ),
        labelStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.textSecondary,
        ),
        hintStyle: EduBridgeTypography.bodyMedium.copyWith(
          color: EduBridgeColors.textTertiary,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          backgroundColor: EduBridgeColors.primary,
          foregroundColor: EduBridgeColors.textOnPrimary,
          textStyle: EduBridgeTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMD,
            vertical: spacingSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          foregroundColor: EduBridgeColors.primary,
          textStyle: EduBridgeTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: BorderSide(
            color: EduBridgeColors.primary,
            width: 1.5,
          ),
          foregroundColor: EduBridgeColors.primary,
          textStyle: EduBridgeTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

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
      chipTheme: ChipThemeData(
        backgroundColor: EduBridgeColors.surfaceVariant,
        labelStyle: EduBridgeTypography.labelMedium.copyWith(
          color: EduBridgeColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSM,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),

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

  /// Thème sombre (pour le futur)
  static ThemeData get darkTheme {
    // TODO: Implémenter le thème sombre
    return lightTheme;
  }
}
