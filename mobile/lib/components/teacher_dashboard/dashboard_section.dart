import 'package:flutter/material.dart';

import '../../ui/theme/edubridge_theme.dart';
import '../../ui/theme/edubridge_typography.dart';
import '../../ui/components/glass_card.dart';

/// Unifie le style des sections du tableau de bord.
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    this.action,
    required this.child,
    this.padding,
  });

  final String title;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? const EdgeInsets.all(EduBridgeTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EduBridgeTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: EduBridgeTheme.spacingSM),
                action!,
              ],
            ],
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          child,
        ],
      ),
    );
  }
}

