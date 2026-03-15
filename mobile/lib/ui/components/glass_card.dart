import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';

/// Glass Card moderne avec glassmorphism et animations subtiles
class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool enableHover;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.backgroundColor,
    this.enableHover = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(EduBridgeTheme.radiusXL),
              border: Border.all(
                color: _isHovered && widget.enableHover
                    ? EduBridgeColors.glassBorderStrong
                    : EduBridgeColors.glassBorder,
                width: 1.5,
              ),
              boxShadow: EduBridgeColors.shadowMd,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(EduBridgeTheme.radiusXL),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: widget.padding ??
                      const EdgeInsets.all(EduBridgeTheme.spacingLG),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ??
                        (_isHovered && widget.enableHover
                            ? EduBridgeColors.glassBackgroundStrong
                            : EduBridgeColors.glassBackground),
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(EduBridgeTheme.radiusXL),
                  ),
                  child: widget.onTap != null
                      ? GestureDetector(
                          onTapDown: _handleTapDown,
                          onTapUp: _handleTapUp,
                          onTapCancel: _handleTapCancel,
                          child: widget.child,
                        )
                      : widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
