import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';

/// Skeleton loader simple sans package externe
/// Utilise une animation de shimmer custom
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(EduBridgeTheme.radiusSM),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 - _controller.value * 2, 0.0),
              colors: [
                EduBridgeColors.surfaceVariant,
                EduBridgeColors.surface,
                EduBridgeColors.surfaceVariant,
              ],
              stops: [
                0.0,
                0.5 + _controller.value * 0.5,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card pour les listes
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 100,
      margin: margin ?? const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
      child: Container(
        decoration: BoxDecoration(
          color: EduBridgeColors.surface,
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          boxShadow: EduBridgeColors.shadowSm,
        ),
        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusFull),
            ),
            const SizedBox(width: EduBridgeTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingSkeleton(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXS),
                  ),
                  const SizedBox(height: EduBridgeTheme.spacingSM),
                  LoadingSkeleton(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXS),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list avec plusieurs cards
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}
