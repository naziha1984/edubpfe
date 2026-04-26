import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';
import 'dashboard_tokens.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.badge,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: DashboardTokens.headerGradient,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: DashboardTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: EduBridgeTheme.spacingMD),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EduBridgeTypography.headlineMedium.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: EduBridgeTheme.spacingXS),
                Text(
                  subtitle,
                  style: EduBridgeTypography.bodyMedium.copyWith(
                    color: EduBridgeColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: EduBridgeTheme.spacingSM),
                  badge!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: EduBridgeTheme.spacingMD),
            trailing!,
          ],
        ],
      ),
    );
  }
}
