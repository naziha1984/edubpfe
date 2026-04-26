import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';

class DashboardStateWrapper extends StatelessWidget {
  const DashboardStateWrapper({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.child,
    this.loadingHeight = 120,
    this.emptyIcon = Icons.inbox_rounded,
  });

  final bool isLoading;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyMessage;
  final Widget child;
  final double loadingHeight;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: loadingHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
          border: Border.all(color: EduBridgeColors.border),
          boxShadow: EduBridgeColors.cardShadowLayered,
        ),
      );
    }
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
          border: Border.all(color: EduBridgeColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
              child: Icon(emptyIcon, size: 18, color: EduBridgeColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: EduBridgeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emptyMessage,
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return child;
  }
}

class ProgressOverviewCard extends StatelessWidget {
  const ProgressOverviewCard({
    super.key,
    required this.progressPercent,
    required this.avgScore,
    required this.completedLessons,
    required this.totalLessons,
    this.isLoading = false,
    this.isEmpty = false,
  });

  final int progressPercent;
  final double avgScore;
  final int completedLessons;
  final int totalLessons;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No progress yet',
      emptyMessage: 'Progress metrics will appear after activity.',
      emptyIcon: Icons.query_stats_rounded,
      loadingHeight: 150,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: EduBridgeColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Progress Overview',
                  style: EduBridgeTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                _softBadge('$progressPercent%'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (progressPercent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metric('Avg score', avgScore.toStringAsFixed(1))),
                const SizedBox(width: 10),
                Expanded(child: _metric('Lessons', '$completedLessons/$totalLessons')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PointsCard extends StatelessWidget {
  const PointsCard({
    super.key,
    required this.points,
    required this.level,
    required this.nextLevelPoints,
    this.isLoading = false,
    this.isEmpty = false,
  });

  final int points;
  final int level;
  final int nextLevelPoints;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final safeNext = nextLevelPoints <= 0 ? points + 100 : nextLevelPoints;
    final progress = (points / safeNext).clamp(0.0, 1.0);
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No points yet',
      emptyMessage: 'Earn points by completing lessons and quizzes.',
      emptyIcon: Icons.bolt_rounded,
      loadingHeight: 140,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '$points points',
                  style: EduBridgeTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'L$level',
                    style: EduBridgeTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Next level at $safeNext points',
              style: EduBridgeTypography.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
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
    this.isLoading = false,
    this.isEmpty = false,
  });

  final int currentStreak;
  final int bestStreak;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No streak yet',
      emptyMessage: 'Study regularly to build your streak.',
      emptyIcon: Icons.local_fire_department_rounded,
      loadingHeight: 110,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: _metricWithIcon(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEA580C),
                label: 'Current streak',
                value: '$currentStreak days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricWithIcon(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFCA8A04),
                label: 'Best streak',
                value: '$bestStreak days',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeChip extends StatelessWidget {
  const BadgeChip({
    super.key,
    required this.label,
    this.icon = Icons.workspace_premium_rounded,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EduBridgeColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: EduBridgeTypography.labelSmall.copyWith(
              color: const Color(0xFF3730A3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  const BadgeCard({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.workspace_premium_rounded,
    this.isLoading = false,
    this.isEmpty = false,
  });

  final String title;
  final String? description;
  final IconData icon;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No badges yet',
      emptyMessage: 'Unlock badges by finishing learning milestones.',
      emptyIcon: Icons.workspace_premium_rounded,
      loadingHeight: 100,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
              child: Icon(icon, size: 16, color: EduBridgeColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MilestoneProgressBar extends StatelessWidget {
  const MilestoneProgressBar({
    super.key,
    required this.currentValue,
    required this.targetValue,
    this.label = 'Milestone progress',
    this.isLoading = false,
    this.isEmpty = false,
  });

  final int currentValue;
  final int targetValue;
  final String label;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final safeTarget = targetValue <= 0 ? 100 : targetValue;
    final ratio = (currentValue / safeTarget).clamp(0.0, 1.0);
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No milestone yet',
      emptyMessage: 'Start learning activity to trigger milestones.',
      emptyIcon: Icons.flag_rounded,
      loadingHeight: 95,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${(ratio * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$currentValue / $safeTarget',
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.title,
    required this.progress,
    this.description,
    this.icon = Icons.emoji_events_rounded,
    this.isCompleted = false,
    this.isLoading = false,
    this.isEmpty = false,
  });

  final String title;
  final double progress;
  final String? description;
  final IconData icon;
  final bool isCompleted;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No achievements yet',
      emptyMessage: 'Achievements will appear with learning progression.',
      emptyIcon: Icons.emoji_events_rounded,
      loadingHeight: 120,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : EduBridgeColors.primary.withOpacity(0.12),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    size: 16,
                    color: isCompleted ? const Color(0xFF166534) : EduBridgeColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isCompleted) _softBadge('Completed'),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: EduBridgeTypography.bodySmall.copyWith(
                  color: EduBridgeColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 7,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonCompletionCard extends StatelessWidget {
  const LessonCompletionCard({
    super.key,
    required this.lessonTitle,
    required this.completionPercent,
    this.subjectName,
    this.isLoading = false,
    this.isEmpty = false,
  });

  final String lessonTitle;
  final int completionPercent;
  final String? subjectName;
  final bool isLoading;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final ratio = (completionPercent / 100).clamp(0.0, 1.0);
    return DashboardStateWrapper(
      isLoading: isLoading,
      isEmpty: isEmpty,
      emptyTitle: 'No lesson completion data',
      emptyMessage: 'Completion analytics will appear after lesson progress.',
      emptyIcon: Icons.play_lesson_rounded,
      loadingHeight: 105,
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_lesson_rounded, color: EduBridgeColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lessonTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$completionPercent%'),
              ],
            ),
            if (subjectName != null) ...[
              const SizedBox(height: 4),
              Text(
                subjectName!,
                style: EduBridgeTypography.bodySmall.copyWith(
                  color: EduBridgeColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Gradient? gradient}) {
  return BoxDecoration(
    color: gradient == null ? Colors.white : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
    border: Border.all(color: EduBridgeColors.border),
    boxShadow: EduBridgeColors.cardShadowLayered,
  );
}

Widget _softBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: EduBridgeColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: EduBridgeTypography.labelSmall.copyWith(
        color: EduBridgeColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget _metric(String label, String value) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: EduBridgeColors.surfaceVariant,
      borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: EduBridgeTypography.bodySmall.copyWith(
            color: EduBridgeColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

Widget _metricWithIcon({
  required IconData icon,
  required Color color,
  required String label,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: EduBridgeColors.surfaceVariant,
      borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
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
