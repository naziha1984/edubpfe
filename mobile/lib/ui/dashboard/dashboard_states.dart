import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        color: EduBridgeColors.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: EduBridgeColors.textTertiary),
          const SizedBox(height: EduBridgeTheme.spacingSM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: EduBridgeTypography.titleSmall.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingXS),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: EduBridgeTheme.spacingMD),
            action!,
          ],
        ],
      ),
    );
  }
}

class DashboardLoadingBlock extends StatefulWidget {
  const DashboardLoadingBlock({super.key, this.height = 88});

  final double height;

  @override
  State<DashboardLoadingBlock> createState() => _DashboardLoadingBlockState();
}

class _DashboardLoadingBlockState extends State<DashboardLoadingBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = -1 + (_controller.value * 2);
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 1.2, 0),
              end: Alignment(x + 1.2, 0),
              colors: [
                EduBridgeColors.surfaceVariant.withOpacity(0.75),
                Colors.white.withOpacity(0.85),
                EduBridgeColors.surfaceVariant.withOpacity(0.75),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        );
      },
    );
  }
}
