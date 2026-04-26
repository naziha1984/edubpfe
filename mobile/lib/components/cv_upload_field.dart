import 'package:flutter/material.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';

class CvUploadField extends StatelessWidget {
  const CvUploadField({
    super.key,
    required this.fileName,
    required this.onPick,
    this.onClear,
    this.errorText,
  });

  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CV enseignant (PDF, DOC, DOCX)',
          style: EduBridgeTypography.titleSmall.copyWith(
            color: EduBridgeColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasFile
                    ? EduBridgeColors.success.withOpacity(0.6)
                    : EduBridgeColors.secondary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: hasFile ? EduBridgeColors.success : EduBridgeColors.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasFile ? fileName! : 'Choisir un fichier CV',
                    style: EduBridgeTypography.bodyMedium.copyWith(
                      color: hasFile
                          ? EduBridgeColors.textPrimary
                          : EduBridgeColors.textSecondary,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasFile && onClear != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Retirer',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
