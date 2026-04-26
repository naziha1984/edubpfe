import 'package:flutter/material.dart';

import '../../ui/components/glass_card.dart';
import '../../ui/theme/edubridge_theme.dart';
import '../../ui/theme/edubridge_typography.dart';

class AdminDashboardSection extends StatelessWidget {
  const AdminDashboardSection({
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
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EduBridgeTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
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

