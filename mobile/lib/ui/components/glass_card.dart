import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';

/// Carte glassmorphism : ombres multicouches, reflet haut, micro-interactions (hover / press).
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

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ??
        BorderRadius.circular(EduBridgeTheme.radiusXL);
    final tappable = widget.onTap != null;
    final elevated = tappable && widget.enableHover && (_hover || _pressed);
    final shadows = dark
        ? EduBridgeColors.cardShadowHoverDark(elevated)
        : EduBridgeColors.cardShadowHover(elevated);

    final baseTint = widget.backgroundColor ??
        (dark ? EduBridgeColors.glassBackgroundDark : EduBridgeColors.glassBackground);

    final topGlass = dark ? 0.12 : 0.62;
    final bottomGlass = dark ? 0.22 : 0.88;
    final sheen = dark ? 0.14 : 0.5;
    final borderOpacity = elevated ? (dark ? 0.35 : 0.9) : (dark ? 0.22 : 0.62);

    Widget cardFace = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(topGlass),
                    baseTint.withOpacity(bottomGlass),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(sheen),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: widget.padding ??
                  const EdgeInsets.all(EduBridgeTheme.spacingLG),
              child: widget.child,
            ),
          ],
        ),
      ),
    );

    Widget interactive = tappable
        ? Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              onHighlightChanged: (held) =>
                  setState(() => _pressed = held),
              splashColor: EduBridgeColors.primary.withOpacity(0.08),
              highlightColor: EduBridgeColors.primary.withOpacity(0.04),
              child: cardFace,
            ),
          )
        : cardFace;

    return MouseRegion(
      onEnter: (_) {
        if (tappable && widget.enableHover) {
          setState(() => _hover = true);
        }
      },
      onExit: (_) {
        if (tappable && widget.enableHover) {
          setState(() => _hover = false);
        }
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: shadows,
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: elevated ? 1.35 : 1.1,
            ),
          ),
          child: interactive,
        ),
      ),
    );
  }
}
