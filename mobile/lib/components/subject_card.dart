import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card de subject avec animations
class SubjectCard extends StatefulWidget {
  final SubjectModel subject;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (widget.subject.hashCode % 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
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
                          Icons.subject,
                          color: EduBridgeColors.textOnPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: EduBridgeTheme.spacingMD),
                      // Title & Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject.name,
                              style: EduBridgeTypography.titleMedium.copyWith(
                                color: EduBridgeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.subject.code != null &&
                                widget.subject.code!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subject.code!,
                                style: EduBridgeTypography.bodySmall.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EduBridgeTheme.spacingSM,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.subject.isActive
                              ? EduBridgeColors.success.withOpacity(0.1)
                              : EduBridgeColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            EduBridgeTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          widget.subject.isActive ? 'Active' : 'Inactive',
                          style: EduBridgeTypography.labelSmall.copyWith(
                            color: widget.subject.isActive
                                ? EduBridgeColors.success
                                : EduBridgeColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Description
                  if (widget.subject.description != null &&
                      widget.subject.description!.isNotEmpty) ...[
                    const SizedBox(height: EduBridgeTheme.spacingSM),
                    Text(
                      widget.subject.description!,
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Actions
                  if (widget.onEdit != null || widget.onDelete != null) ...[
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.onEdit != null)
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: EduBridgeColors.primary,
                            ),
                          ),
                        if (widget.onDelete != null) ...[
                          const SizedBox(width: EduBridgeTheme.spacingSM),
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: EduBridgeColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
