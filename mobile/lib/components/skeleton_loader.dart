import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';

/// Skeleton loader avec effet shimmer pour le chargement
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: EduBridgeColors.surfaceVariant,
      highlightColor: EduBridgeColors.surface,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: EduBridgeColors.surfaceVariant,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
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
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: EduBridgeColors.surfaceVariant,
        highlightColor: EduBridgeColors.surface,
        period: const Duration(milliseconds: 1200),
        child: Container(
          decoration: BoxDecoration(
            color: EduBridgeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: EduBridgeColors.textTertiary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: EduBridgeColors.textTertiary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: EduBridgeColors.textTertiary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}
