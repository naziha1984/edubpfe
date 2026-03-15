import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card de classe avec animations
class ClassCard extends StatefulWidget {
  final ClassModel classModel;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onCopyCode;
  final VoidCallback? onShareCode;

  const ClassCard({
    super.key,
    required this.classModel,
    required this.index,
    this.onTap,
    this.onCopyCode,
    this.onShareCode,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard>
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

  @override
  Widget build(BuildContext context) {
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
                      Icons.class_,
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
                          widget.classModel.name,
                          style: EduBridgeTypography.titleMedium.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.classModel.description != null &&
                            widget.classModel.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.classModel.description!,
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      color: widget.classModel.isActive
                          ? EduBridgeColors.success.withOpacity(0.1)
                          : EduBridgeColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        EduBridgeTheme.radiusFull,
                      ),
                    ),
                    child: Text(
                      widget.classModel.isActive ? 'Active' : 'Inactive',
                      style: EduBridgeTypography.labelSmall.copyWith(
                        color: widget.classModel.isActive
                            ? EduBridgeColors.success
                            : EduBridgeColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EduBridgeTheme.spacingMD),
              // Class Code Section
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 20,
                      color: EduBridgeColors.primary,
                    ),
                    const SizedBox(width: EduBridgeTheme.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Code',
                            style: EduBridgeTypography.labelSmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                          Text(
                            widget.classModel.classCode,
                            style: EduBridgeTypography.titleSmall.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Copy & Share buttons
                    if (widget.onCopyCode != null || widget.onShareCode != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onCopyCode != null)
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: widget.onCopyCode,
                              color: EduBridgeColors.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (widget.onShareCode != null) ...[
                            const SizedBox(width: EduBridgeTheme.spacingXS),
                            IconButton(
                              icon: const Icon(Icons.share, size: 20),
                              onPressed: widget.onShareCode,
                              color: EduBridgeColors.secondary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              // Students count
              if (widget.classModel.members != null) ...[
                const SizedBox(height: EduBridgeTheme.spacingSM),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: EduBridgeColors.textSecondary,
                    ),
                    const SizedBox(width: EduBridgeTheme.spacingXS),
                    Text(
                      '${widget.classModel.members!.length} student${widget.classModel.members!.length != 1 ? 's' : ''}',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
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
