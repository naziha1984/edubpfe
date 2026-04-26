import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';
import 'dashboard_motion.dart';
import 'dashboard_tokens.dart';

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = EduBridgeColors.primary,
    this.badgeCount = 0,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return DashboardHoverCard(
      baseShadows: EduBridgeColors.shadowSm,
      hoverShadows: EduBridgeColors.shadowMd,
      child: DashboardPressable(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          decoration: BoxDecoration(
            color: EduBridgeColors.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
            border: Border.all(color: Colors.white.withOpacity(0.75)),
            boxShadow: EduBridgeColors.shadowSm,
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: EduBridgeTypography.titleLarge.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: EduBridgeTypography.bodySmall.copyWith(
                            color: EduBridgeColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: DashboardPulseBadge(value: badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DashboardTokens.sectionPadding,
      decoration: BoxDecoration(
        color: EduBridgeColors.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: EduBridgeColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EduBridgeTypography.titleMedium.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          child,
        ],
      ),
    );
  }
}
