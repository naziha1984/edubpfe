import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card d'élève dans une classe
class StudentCard extends StatelessWidget {
  final ClassMemberModel member;
  final VoidCallback? onRemove;

  const StudentCard({
    super.key,
    required this.member,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      child: Row(
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
                member.kidName.isNotEmpty
                    ? member.kidName[0].toUpperCase()
                    : '?',
                style: EduBridgeTypography.titleMedium.copyWith(
                  color: EduBridgeColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: EduBridgeTheme.spacingMD),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.kidName,
                  style: EduBridgeTypography.titleMedium.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (member.joinedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${_formatDate(member.joinedAt!)}',
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
              color: EduBridgeColors.error,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
