import 'package:flutter/material.dart';

import 'edubridge_colors.dart';
import 'edubridge_typography.dart';

/// Centralized design tokens for spacing/radius/shadows/icon sizing.
class EDS {
  // Spacing scale (4pt grid)
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;

  // Radius scale
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
  static const double r2xl = 24;
  static const double rFull = 999;

  // Icon sizing rules
  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 28;

  static BorderRadius br([double value = rLg]) => BorderRadius.circular(value);
}

/// Semantic status styles to keep badge/chip color mapping consistent.
class EDSStatusStyle {
  const EDSStatusStyle({
    required this.bg,
    required this.fg,
    required this.border,
  });

  final Color bg;
  final Color fg;
  final Color border;
}

class EDSSemantic {
  static EDSStatusStyle success(bool dark) => EDSStatusStyle(
        bg: dark ? const Color(0xFF0B2C1F) : const Color(0xFFDCFCE7),
        fg: dark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
        border: dark ? const Color(0xFF14532D) : const Color(0xFF86EFAC),
      );

  static EDSStatusStyle warning(bool dark) => EDSStatusStyle(
        bg: dark ? const Color(0xFF3A2A08) : const Color(0xFFFEF3C7),
        fg: dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
        border: dark ? const Color(0xFF713F12) : const Color(0xFFFCD34D),
      );

  static EDSStatusStyle danger(bool dark) => EDSStatusStyle(
        bg: dark ? const Color(0xFF3A1414) : const Color(0xFFFEE2E2),
        fg: dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
        border: dark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
      );

  static EDSStatusStyle info(bool dark) => EDSStatusStyle(
        bg: dark ? const Color(0xFF0F2345) : const Color(0xFFDBEAFE),
        fg: dark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
        border: dark ? const Color(0xFF1E3A8A) : const Color(0xFF93C5FD),
      );
}

@immutable
class EDSBadgeTheme extends ThemeExtension<EDSBadgeTheme> {
  const EDSBadgeTheme({
    required this.padding,
    required this.radius,
    required this.textStyle,
  });

  final EdgeInsets padding;
  final BorderRadius radius;
  final TextStyle textStyle;

  @override
  EDSBadgeTheme copyWith({
    EdgeInsets? padding,
    BorderRadius? radius,
    TextStyle? textStyle,
  }) {
    return EDSBadgeTheme(
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  EDSBadgeTheme lerp(ThemeExtension<EDSBadgeTheme>? other, double t) {
    if (other is! EDSBadgeTheme) return this;
    return EDSBadgeTheme(
      padding: EdgeInsets.lerp(padding, other.padding, t) ?? padding,
      radius: BorderRadius.lerp(radius, other.radius, t) ?? radius,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t) ?? textStyle,
    );
  }
}

@immutable
class EDSChipTokens extends ThemeExtension<EDSChipTokens> {
  const EDSChipTokens({
    required this.padding,
    required this.radius,
    required this.borderColor,
    required this.bg,
    required this.labelStyle,
  });

  final EdgeInsets padding;
  final BorderRadius radius;
  final Color borderColor;
  final Color bg;
  final TextStyle labelStyle;

  @override
  EDSChipTokens copyWith({
    EdgeInsets? padding,
    BorderRadius? radius,
    Color? borderColor,
    Color? bg,
    TextStyle? labelStyle,
  }) {
    return EDSChipTokens(
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      borderColor: borderColor ?? this.borderColor,
      bg: bg ?? this.bg,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  EDSChipTokens lerp(ThemeExtension<EDSChipTokens>? other, double t) {
    if (other is! EDSChipTokens) return this;
    return EDSChipTokens(
      padding: EdgeInsets.lerp(padding, other.padding, t) ?? padding,
      radius: BorderRadius.lerp(radius, other.radius, t) ?? radius,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t) ?? labelStyle,
    );
  }
}

class EDSComponentThemes {
  static ElevatedButtonThemeData elevatedButton(bool dark) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: EDS.s6, vertical: EDS.s4),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: EDS.br(EDS.rMd)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          }
          if (states.contains(WidgetState.pressed)) {
            return dark ? EduBridgeColors.primary : EduBridgeColors.primaryDark;
          }
          return dark ? EduBridgeColors.primaryLight : EduBridgeColors.primary;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        textStyle: WidgetStatePropertyAll(
          EduBridgeTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButton(bool dark) {
    final border = dark ? EduBridgeColors.primaryLight : EduBridgeColors.primary;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: EDS.s6, vertical: EDS.s4),
        shape: RoundedRectangleBorder(borderRadius: EDS.br(EDS.rMd)),
        side: BorderSide(color: border, width: 1.5),
        foregroundColor: border,
        textStyle: EduBridgeTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  static TextButtonThemeData textButton(bool dark) {
    final fg = dark ? EduBridgeColors.primaryLight : EduBridgeColors.primary;
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: EDS.s4, vertical: EDS.s2),
        shape: RoundedRectangleBorder(borderRadius: EDS.br(EDS.rMd)),
        foregroundColor: fg,
        textStyle: EduBridgeTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  static InputDecorationTheme input(bool dark) {
    final border = dark
        ? EduBridgeColors.darkTextTertiary.withOpacity(0.35)
        : EduBridgeColors.textTertiary.withOpacity(0.3);
    final fill = dark ? EduBridgeColors.darkSurfaceVariant : EduBridgeColors.surface;
    final label = dark ? EduBridgeColors.darkTextSecondary : EduBridgeColors.textSecondary;
    final hint = dark ? EduBridgeColors.darkTextTertiary : EduBridgeColors.textTertiary;
    final focus = dark ? EduBridgeColors.primaryLight : EduBridgeColors.primary;

    OutlineInputBorder ob(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: EDS.br(EDS.rMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: EDS.s4, vertical: EDS.s4),
      border: ob(border),
      enabledBorder: ob(border),
      focusedBorder: ob(focus, 2),
      errorBorder: ob(EduBridgeColors.error, 1.5),
      focusedErrorBorder: ob(EduBridgeColors.error, 2),
      labelStyle: EduBridgeTypography.bodyMedium.copyWith(color: label),
      hintStyle: EduBridgeTypography.bodyMedium.copyWith(color: hint),
    );
  }

  static CardThemeData card(bool dark) {
    return CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: EDS.br(EDS.rLg)),
      color: dark ? EduBridgeColors.darkSurface : EduBridgeColors.surface,
      margin: EdgeInsets.zero,
    );
  }

  static ChipThemeData chip(bool dark) {
    final bg = dark ? EduBridgeColors.darkSurfaceVariant : EduBridgeColors.surfaceVariant;
    final fg = dark ? EduBridgeColors.darkTextPrimary : EduBridgeColors.textPrimary;
    final side = dark
        ? EduBridgeColors.darkTextTertiary.withOpacity(0.25)
        : EduBridgeColors.border;
    return ChipThemeData(
      backgroundColor: bg,
      labelStyle: EduBridgeTypography.labelMedium.copyWith(color: fg),
      padding: const EdgeInsets.symmetric(horizontal: EDS.s2, vertical: EDS.s1),
      shape: RoundedRectangleBorder(
        borderRadius: EDS.br(EDS.rFull),
        side: BorderSide(color: side),
      ),
    );
  }

  static EDSBadgeTheme badgeTokens(bool dark) {
    final fg = dark ? EduBridgeColors.darkTextPrimary : EduBridgeColors.textPrimary;
    return EDSBadgeTheme(
      padding: const EdgeInsets.symmetric(horizontal: EDS.s3, vertical: EDS.s1),
      radius: EDS.br(EDS.rFull),
      textStyle: EduBridgeTypography.labelSmall.copyWith(
        color: fg,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static EDSChipTokens chipTokens(bool dark) {
    final bg = dark ? EduBridgeColors.darkSurfaceVariant : EduBridgeColors.surfaceVariant;
    final side = dark
        ? EduBridgeColors.darkTextTertiary.withOpacity(0.25)
        : EduBridgeColors.border;
    final fg = dark ? EduBridgeColors.darkTextPrimary : EduBridgeColors.textPrimary;
    return EDSChipTokens(
      padding: const EdgeInsets.symmetric(horizontal: EDS.s2, vertical: EDS.s1),
      radius: EDS.br(EDS.rFull),
      borderColor: side,
      bg: bg,
      labelStyle: EduBridgeTypography.labelSmall.copyWith(color: fg),
    );
  }
}

