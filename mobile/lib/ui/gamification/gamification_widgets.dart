import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';

class GamificationSectionCard extends StatelessWidget {
  const GamificationSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        border: Border.all(color: EduBridgeColors.border),
        boxShadow: EduBridgeColors.cardShadowLayered,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EduBridgeTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
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

class PointsSummaryCard extends StatelessWidget {
  const PointsSummaryCard({
    super.key,
    required this.totalPoints,
    required this.currentLevel,
    required this.nextMilestonePoints,
  });

  final int totalPoints;
  final int currentLevel;
  final int nextMilestonePoints;

  @override
  Widget build(BuildContext context) {
    final safeNext = nextMilestonePoints <= 0 ? totalPoints + 100 : nextMilestonePoints;
    final progress = (totalPoints / safeNext).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331D4ED8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$totalPoints points',
                  style: EduBridgeTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _softTag('Level $currentLevel'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Next milestone at $safeNext points',
            style: EduBridgeTypography.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _softTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: EduBridgeTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _metric(
            icon: Icons.local_fire_department_rounded,
            label: 'Current streak',
            value: '$currentStreak days',
            color: const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metric(
            icon: Icons.emoji_events_rounded,
            label: 'Best streak',
            value: '$bestStreak days',
            color: const Color(0xFFCA8A04),
          ),
        ),
      ],
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: EduBridgeColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(label, style: EduBridgeTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementProgressTile extends StatelessWidget {
  const AchievementProgressTile({
    super.key,
    required this.title,
    required this.progress,
    required this.leadingIcon,
  });

  final String title;
  final double progress;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduBridgeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(leadingIcon, size: 18, color: EduBridgeColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: EduBridgeTypography.titleSmall)),
              Text('${(p * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: p,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.icon,
    required this.name,
    this.subtitle,
  });

  final IconData icon;
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: EduBridgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: EduBridgeColors.primary.withOpacity(0.15),
            child: Icon(icon, size: 16, color: EduBridgeColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MotivationalStateCard extends StatelessWidget {
  const MotivationalStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.success = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final bg = success ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF);
    final fg = success ? const Color(0xFF065F46) : const Color(0xFF3730A3);
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: fg.withOpacity(0.14),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EduBridgeTypography.titleSmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: EduBridgeTypography.bodySmall.copyWith(color: fg.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
