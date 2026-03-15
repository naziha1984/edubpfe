import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';

/// Glass card avec animations et micro-interactions
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final bool enableHover;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHover = true,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
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
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: _isPressed
                    ? EduBridgeColors.primary.withOpacity(0.5)
                    : EduBridgeColors.glassBorder,
                width: _isPressed ? 2 : 1.5,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: EduBridgeColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? EduBridgeColors.glassBackground.withOpacity(0.6)
                        : EduBridgeColors.glassBackground,
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(20),
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
