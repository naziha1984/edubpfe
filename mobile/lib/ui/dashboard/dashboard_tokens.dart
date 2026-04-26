import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';

class DashboardTokens {
  static const double maxContentWidth = 1280;
  static const double headerHeight = 136;
  static const double radiusCard = EduBridgeTheme.radiusXL;
  static const double radiusChip = EduBridgeTheme.radiusFull;

  static const EdgeInsets pagePadding = EdgeInsets.all(EduBridgeTheme.spacingLG);
  static const EdgeInsets sectionPadding = EdgeInsets.all(EduBridgeTheme.spacingLG);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEF2FF),
      Color(0xFFE0E7FF),
      Color(0xFFF8FAFC),
    ],
  );

  static List<BoxShadow> get cardShadow => EduBridgeColors.cardShadowLayered;

  static Color semanticColor(String semantic) {
    switch (semantic) {
      case 'success':
        return EduBridgeColors.success;
      case 'warning':
        return EduBridgeColors.warning;
      case 'danger':
        return EduBridgeColors.error;
      case 'info':
        return EduBridgeColors.info;
      default:
        return EduBridgeColors.primary;
    }
  }
}
