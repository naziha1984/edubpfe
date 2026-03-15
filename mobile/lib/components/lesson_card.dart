import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card de lesson avec animations Hero
class LessonCard extends StatefulWidget {
  final LessonModel lesson;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.index,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: GlassCard(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Order badge
                    if (widget.lesson.order != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EduBridgeTheme.spacingSM,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: EduBridgeColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            EduBridgeTheme.radiusSM,
                          ),
                        ),
                        child: Text(
                          '${widget.lesson.order}',
                          style: EduBridgeTypography.labelSmall.copyWith(
                            color: EduBridgeColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (widget.lesson.order != null)
                      const SizedBox(width: EduBridgeTheme.spacingSM),
                    // Title avec Hero
                    Expanded(
                      child: Hero(
                        tag: 'lesson_title_${widget.lesson.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.lesson.title,
                            style: EduBridgeTypography.titleMedium.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EduBridgeTheme.spacingSM,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.lesson.isActive
                            ? EduBridgeColors.success.withOpacity(0.1)
                            : EduBridgeColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          EduBridgeTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        widget.lesson.isActive ? 'Active' : 'Inactive',
                        style: EduBridgeTypography.labelSmall.copyWith(
                          color: widget.lesson.isActive
                              ? EduBridgeColors.success
                              : EduBridgeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Description
                if (widget.lesson.description != null &&
                    widget.lesson.description!.isNotEmpty) ...[
                  const SizedBox(height: EduBridgeTheme.spacingSM),
                  Text(
                    widget.lesson.description!,
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Level & Language badges
                if (widget.lesson.level != null ||
                    widget.lesson.language != null) ...[
                  const SizedBox(height: EduBridgeTheme.spacingSM),
                  Wrap(
                    spacing: EduBridgeTheme.spacingSM,
                    runSpacing: EduBridgeTheme.spacingXS,
                    children: [
                      if (widget.lesson.level != null &&
                          widget.lesson.level!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EduBridgeTheme.spacingSM,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: EduBridgeColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              EduBridgeTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 12,
                                color: EduBridgeColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.lesson.level!,
                                style: EduBridgeTypography.labelSmall.copyWith(
                                  color: EduBridgeColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.lesson.language != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EduBridgeTheme.spacingSM,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: EduBridgeColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              EduBridgeTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 12,
                                color: EduBridgeColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.lesson.language == 'en'
                                    ? 'EN'
                                    : widget.lesson.language == 'fr'
                                        ? 'FR'
                                        : widget.lesson.language == 'ar'
                                            ? 'AR'
                                            : widget.lesson.language == 'es'
                                                ? 'ES'
                                                : widget.lesson.language!.toUpperCase(),
                                style: EduBridgeTypography.labelSmall.copyWith(
                                  color: EduBridgeColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                // Content preview
                if (widget.lesson.content != null &&
                    widget.lesson.content!.isNotEmpty) ...[
                  const SizedBox(height: EduBridgeTheme.spacingSM),
                  Container(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: EduBridgeColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        EduBridgeTheme.radiusSM,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.article,
                          size: 16,
                          color: EduBridgeColors.textSecondary,
                        ),
                        const SizedBox(width: EduBridgeTheme.spacingXS),
                        Expanded(
                          child: Text(
                            'Content: ${widget.lesson.content!.length} characters',
                            style: EduBridgeTypography.labelSmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
        ),
      ),
    );
  }
}
