import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// EduBridge 应用主题
class EduBridgeTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
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
      ),
      scaffoldBackgroundColor: EduBridgeColors.background,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EduBridgeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EduBridgeColors.textTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EduBridgeColors.textTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EduBridgeColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EduBridgeColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      // Flutter 3.22+ 使用 CardThemeData 类型
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: EduBridgeColors.surface,
      ),
    );
  }
}
