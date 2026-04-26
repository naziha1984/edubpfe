import 'package:flutter/material.dart';
import '../ui/theme/edubridge_typography.dart';

class TeacherApprovalBadge extends StatelessWidget {
  const TeacherApprovalBadge({
    super.key,
    required this.status,
  });

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? 'PENDING').toUpperCase();
    final isAccepted = normalized == 'ACCEPTED';
    final isRejected = normalized == 'REJECTED';
    final bg = isAccepted
        ? const Color(0xFFDCFCE7)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final fg = isAccepted
        ? const Color(0xFF166534)
        : isRejected
            ? const Color(0xFF991B1B)
            : const Color(0xFF92400E);
    final label = isAccepted
        ? 'Accepted'
        : isRejected
            ? 'Rejected'
            : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: EduBridgeTypography.labelMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
