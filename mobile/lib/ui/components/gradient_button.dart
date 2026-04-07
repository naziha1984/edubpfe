import 'package:flutter/material.dart';
import '../theme/edubridge_colors.dart';
import '../theme/edubridge_typography.dart';
import '../theme/edubridge_theme.dart';

/// Bouton avec gradient et animations fluides
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final bool isLoading;
  final GradientButtonVariant variant;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = 56,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
    this.variant = GradientButtonVariant.primary,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

enum GradientButtonVariant {
  primary,
  secondary,
  outline,
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  Gradient _getGradient() {
    if (widget.gradient != null) return widget.gradient!;

    switch (widget.variant) {
      case GradientButtonVariant.primary:
        return EduBridgeColors.primaryGradient;
      case GradientButtonVariant.secondary:
        return EduBridgeColors.accentGradient;
      case GradientButtonVariant.outline:
        return const LinearGradient(colors: [Colors.transparent]);
    }
  }

  Color _getTextColor() {
    switch (widget.variant) {
      case GradientButtonVariant.primary:
      case GradientButtonVariant.secondary:
        return EduBridgeColors.textOnPrimary;
      case GradientButtonVariant.outline:
        return EduBridgeColors.primary;
    }
  }

  List<BoxShadow>? _getShadow() {
    if (widget.variant == GradientButtonVariant.outline) return null;
    if (widget.onPressed == null || widget.isLoading) return null;

    return [
      ...EduBridgeColors.shadowPrimary,
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.height <= 48;
    final iconSize = compact ? 18.0 : 20.0;
    final fontSize = compact ? 14.0 : 16.0;
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(EduBridgeTheme.radiusLG);
    final effectiveGradient = _getGradient();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.variant == GradientButtonVariant.outline
                  ? null
                  : effectiveGradient,
              borderRadius: effectiveBorderRadius,
              border: widget.variant == GradientButtonVariant.outline
                  ? Border.all(
                      color: EduBridgeColors.primary,
                      width: 2,
                    )
                  : null,
              boxShadow: _getShadow(),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: effectiveBorderRadius,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: Container(
                  padding: widget.padding ??
                      EdgeInsets.symmetric(
                        horizontal:
                            compact ? 20.0 : EduBridgeTheme.spacingLG,
                        vertical: compact ? 10.0 : EduBridgeTheme.spacingMD,
                      ),
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTextColor(),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: _getTextColor(),
                                size: iconSize,
                              ),
                              SizedBox(
                                width: compact
                                    ? EduBridgeTheme.spacingXS + 2
                                    : EduBridgeTheme.spacingSM,
                              ),
                            ],
                            Text(
                              widget.text,
                              style: EduBridgeTypography.labelLarge.copyWith(
                                color: _getTextColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
