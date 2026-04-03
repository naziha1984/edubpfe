import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/assignment_model.dart';
import '../utils/upload_url.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card d'assignment avec animations et status chips
class AssignmentCard extends StatefulWidget {
  final AssignmentModel assignment;
  final int index;
  final VoidCallback? onTap;
  final bool showSubmissionStatus; // Pour afficher le statut de soumission (kid view)

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.index,
    this.onTap,
    this.showSubmissionStatus = false,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(SubmissionStatus? status) {
    if (status == null) return EduBridgeColors.textTertiary;
    switch (status) {
      case SubmissionStatus.assigned:
        return EduBridgeColors.warning;
      case SubmissionStatus.inProgress:
        return EduBridgeColors.info;
      case SubmissionStatus.completed:
        return EduBridgeColors.success;
    }
  }

  String _getStatusText(SubmissionStatus? status) {
    if (status == null) return 'Non assigné';
    return status.displayName;
  }

  IconData _iconForMime(String mime) {
    final m = mime.toLowerCase();
    if (m.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (m.startsWith('image/')) return Icons.image_rounded;
    if (m.startsWith('video/')) return Icons.movie_rounded;
    if (m.contains('word') || m.contains('document')) {
      return Icons.description_rounded;
    }
    if (m.contains('sheet') || m.contains('excel')) {
      return Icons.table_chart_rounded;
    }
    return Icons.attach_file_rounded;
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(absoluteUploadUrl(url));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getDueDateColor() {
    if (widget.assignment.isOverdue) {
      return EduBridgeColors.error;
    }
    if (widget.assignment.daysUntilDue <= 3) {
      return EduBridgeColors.warning;
    }
    return EduBridgeColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final dueDateFormatted = DateFormat('dd MMM yyyy', 'fr_FR')
        .format(widget.assignment.dueDate);
    final timeFormatted = DateFormat('HH:mm', 'fr_FR')
        .format(widget.assignment.dueDate);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
                    decoration: BoxDecoration(
                      gradient: EduBridgeColors.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        EduBridgeTheme.radiusMD,
                      ),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: EduBridgeColors.textOnPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assignment.title,
                          style: EduBridgeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: EduBridgeColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.assignment.lessonTitle != 'No lesson') ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.assignment.lessonTitle,
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status chip (pour kid view)
                  if (widget.showSubmissionStatus &&
                      widget.assignment.submission != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EduBridgeTheme.spacingSM,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                                widget.assignment.submission?.status)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusSM,
                        ),
                        border: Border.all(
                          color: _getStatusColor(
                                  widget.assignment.submission?.status)
                              .withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusText(widget.assignment.submission?.status),
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: _getStatusColor(
                              widget.assignment.submission?.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.assignment.description != null &&
                  widget.assignment.description!.isNotEmpty) ...[
                const SizedBox(height: EduBridgeTheme.spacingSM),
                Text(
                  widget.assignment.description!,
                  style: EduBridgeTypography.bodySmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.assignment.attachments.isNotEmpty) ...[
                const SizedBox(height: EduBridgeTheme.spacingMD),
                Text(
                  'Pièces jointes',
                  style: EduBridgeTypography.labelSmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.assignment.attachments.map((a) {
                    return ActionChip(
                      avatar: Icon(
                        _iconForMime(a.mimeType),
                        size: 18,
                        color: EduBridgeColors.secondaryDark,
                      ),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          a.originalName,
                          overflow: TextOverflow.ellipsis,
                          style: EduBridgeTypography.labelSmall,
                        ),
                      ),
                      backgroundColor:
                          EduBridgeColors.secondaryContainer.withOpacity(0.5),
                      onPressed: a.url.isEmpty
                          ? null
                          : () => _openAttachment(a.url),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: EduBridgeTheme.spacingSM),
              // Due date timeline
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _getDueDateColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: $dueDateFormatted à $timeFormatted',
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: _getDueDateColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (widget.assignment.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EduBridgeColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusSM,
                        ),
                      ),
                      child: Text(
                        'En retard',
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: EduBridgeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (widget.assignment.daysUntilDue <= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EduBridgeColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusSM,
                        ),
                      ),
                      child: Text(
                        '${widget.assignment.daysUntilDue}j restants',
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: EduBridgeColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              // Score (si soumis)
              if (widget.showSubmissionStatus &&
                  widget.assignment.submission?.status ==
                      SubmissionStatus.completed &&
                  widget.assignment.submission?.score != null) ...[
                const SizedBox(height: EduBridgeTheme.spacingSM),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: EduBridgeColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score: ${widget.assignment.submission!.score!.toStringAsFixed(1)}/100',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
