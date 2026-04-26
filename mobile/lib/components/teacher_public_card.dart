import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/glass_card.dart';

class TeacherPublicCard extends StatelessWidget {
  const TeacherPublicCard({
    super.key,
    required this.teacher,
    this.onTap,
  });

  final Map<String, dynamic> teacher;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fullName = teacher['fullName']?.toString() ?? '';
    final specialty = teacher['specialty']?.toString() ?? '';
    final profilePhotoUrl = teacher['profilePhotoUrl']?.toString();
    final rating = (teacher['rating'] is num)
        ? (teacher['rating'] as num).toDouble()
        : 0.0;
    final ratingCount = (teacher['ratingCount'] is num)
        ? (teacher['ratingCount'] as num).toInt()
        : 0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
            backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                ? NetworkImage(profilePhotoUrl)
                : null,
            child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                ? const Icon(Icons.school_rounded)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: EduBridgeTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (specialty.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      ratingCount > 0 ? rating.toStringAsFixed(1) : '-',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($ratingCount)',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
