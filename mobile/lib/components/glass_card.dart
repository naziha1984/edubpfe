import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';

/// 玻璃态卡片组件
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: EduBridgeColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EduBridgeColors.glassBackground,
              borderRadius: borderRadius ?? BorderRadius.circular(20),
            ),
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: borderRadius ?? BorderRadius.circular(20),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
