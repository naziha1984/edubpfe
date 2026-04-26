import 'package:flutter/material.dart';

import '../../ui/components/glass_card.dart';
import '../../ui/theme/edubridge_colors.dart';
import '../../ui/theme/edubridge_theme.dart';
import '../../ui/theme/edubridge_typography.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Text(
            value,
            style: EduBridgeTypography.headlineMedium.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

