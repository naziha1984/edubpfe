import 'package:flutter/material.dart';
import '../models/student_progress_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card de progression d'un élève avec mini chart
class StudentProgressCard extends StatelessWidget {
  final StudentProgressModel student;
  final int index;

  const StudentProgressCard({
    super.key,
    required this.student,
    required this.index,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'No activity';
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: EduBridgeColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    student.kidName.isNotEmpty
                        ? student.kidName[0].toUpperCase()
                        : '?',
                    style: EduBridgeTypography.titleMedium.copyWith(
                      color: EduBridgeColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              // Name & Level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.kidName,
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EduBridgeTheme.spacingSM,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: student.levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        student.level,
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: student.levelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student.avgScore.toStringAsFixed(1)}%',
                    style: EduBridgeTypography.headlineSmall.copyWith(
                      color: EduBridgeColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Avg Score',
                    style: EduBridgeTypography.labelSmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Mini Chart (Bar)
          if (student.totalLessons > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusSM,
                        ),
                        child: LinearProgressIndicator(
                          value: student.completionRate / 100,
                          minHeight: 8,
                          backgroundColor: EduBridgeColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            student.completionRate >= 75
                                ? EduBridgeColors.success
                                : student.completionRate >= 50
                                    ? EduBridgeColors.warning
                                    : EduBridgeColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.completedLessons}/${student.totalLessons} lessons',
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: EduBridgeTheme.spacingMD),
                // Completion Rate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${student.completionRate.toStringAsFixed(0)}%',
                      style: EduBridgeTypography.titleSmall.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: EduBridgeTypography.labelSmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
              decoration: BoxDecoration(
                color: EduBridgeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: EduBridgeColors.textSecondary,
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingSM),
                  Text(
                    'No progress data yet',
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: EduBridgeTheme.spacingSM),
          // Last Activity
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: EduBridgeColors.textSecondary,
              ),
              const SizedBox(width: EduBridgeTheme.spacingXS),
              Text(
                'Last activity: ${_formatDate(student.lastActivity)}',
                style: EduBridgeTypography.labelSmall.copyWith(
                  color: EduBridgeColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
