import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';

enum DashboardStateVariant {
  neutral,
  info,
  success,
  warning,
}

class DashboardStateTone {
  const DashboardStateTone({
    required this.background,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
  });

  final Color background;
  final Color iconBg;
  final Color iconColor;
  final Color borderColor;
}

class DashboardPremiumStateCard extends StatelessWidget {
  const DashboardPremiumStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.variant = DashboardStateVariant.neutral,
    this.action,
    this.alignStart = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final DashboardStateVariant variant;
  final Widget? action;
  final bool alignStart;

  static DashboardStateTone tone(DashboardStateVariant variant) {
    switch (variant) {
      case DashboardStateVariant.info:
        return DashboardStateTone(
          background: const Color(0xFFEFF6FF),
          iconBg: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF1D4ED8),
          borderColor: const Color(0xFFBFDBFE),
        );
      case DashboardStateVariant.success:
        return DashboardStateTone(
          background: const Color(0xFFECFDF5),
          iconBg: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF047857),
          borderColor: const Color(0xFFA7F3D0),
        );
      case DashboardStateVariant.warning:
        return DashboardStateTone(
          background: const Color(0xFFFFFBEB),
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFB45309),
          borderColor: const Color(0xFFFDE68A),
        );
      case DashboardStateVariant.neutral:
        return DashboardStateTone(
          background: const Color(0xFFF8FAFC),
          iconBg: const Color(0xFFE2E8F0),
          iconColor: const Color(0xFF475569),
          borderColor: const Color(0xFFE2E8F0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tone(variant);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: t.borderColor),
      ),
      child: Column(
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: t.iconBg,
            child: Icon(icon, color: t.iconColor, size: 20),
          ),
          const SizedBox(height: EduBridgeTheme.spacingSM),
          Text(
            title,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: EduBridgeTypography.titleSmall.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingXS),
          Text(
            message,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.textSecondary,
              height: 1.45,
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

class DashboardPremiumLoadingState extends StatefulWidget {
  const DashboardPremiumLoadingState({
    super.key,
    this.blockCount = 3,
    this.blockHeight = 88,
  });

  final int blockCount;
  final double blockHeight;

  @override
  State<DashboardPremiumLoadingState> createState() =>
      _DashboardPremiumLoadingStateState();
}

class _DashboardPremiumLoadingStateState extends State<DashboardPremiumLoadingState>
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
        final shift = -1 + (_controller.value * 2);
        return Column(
          children: List.generate(widget.blockCount, (index) {
            return Container(
              margin: EdgeInsets.only(
                bottom: index == widget.blockCount - 1
                    ? 0
                    : EduBridgeTheme.spacingSM,
              ),
              width: double.infinity,
              height: widget.blockHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                gradient: LinearGradient(
                  begin: Alignment(shift - 1.1, 0),
                  end: Alignment(shift + 1.1, 0),
                  colors: [
                    const Color(0xFFE2E8F0),
                    Colors.white,
                    const Color(0xFFE2E8F0),
                  ],
                  stops: const [0.2, 0.5, 0.8],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class DashboardNoNotificationsState extends StatelessWidget {
  const DashboardNoNotificationsState({
    super.key,
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardPremiumStateCard(
      icon: Icons.notifications_none_rounded,
      title: 'No notifications yet',
      message:
          'You are all caught up. New platform alerts and class updates will appear here.',
      variant: DashboardStateVariant.info,
      action: action,
    );
  }
}

class DashboardNoLessonsState extends StatelessWidget {
  const DashboardNoLessonsState({
    super.key,
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardPremiumStateCard(
      icon: Icons.menu_book_rounded,
      title: 'No lessons available',
      message:
          'Lessons will be listed here once new educational content is published.',
      variant: DashboardStateVariant.neutral,
      action: action,
    );
  }
}

class DashboardNoReviewsState extends StatelessWidget {
  const DashboardNoReviewsState({
    super.key,
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardPremiumStateCard(
      icon: Icons.reviews_rounded,
      title: 'No reviews yet',
      message:
          'Feedback history will appear here as learners and parents submit their reviews.',
      variant: DashboardStateVariant.neutral,
      action: action,
    );
  }
}

class DashboardNoBadgesState extends StatelessWidget {
  const DashboardNoBadgesState({
    super.key,
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardPremiumStateCard(
      icon: Icons.workspace_premium_rounded,
      title: 'No badges unlocked yet',
      message:
          'Keep progressing through lessons to unlock your first achievement badge.',
      variant: DashboardStateVariant.warning,
      action: action,
    );
  }
}

class DashboardNoMessagesState extends StatelessWidget {
  const DashboardNoMessagesState({
    super.key,
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardPremiumStateCard(
      icon: Icons.forum_outlined,
      title: 'No messages yet',
      message:
          'Direct conversations will appear here once communication starts.',
      variant: DashboardStateVariant.info,
      action: action,
    );
  }
}
