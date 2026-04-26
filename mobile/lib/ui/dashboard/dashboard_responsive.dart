import 'package:flutter/material.dart';

enum DashboardSizeClass { mobile, tablet, desktop }

class DashboardResponsive {
  static DashboardSizeClass sizeClass(double width) {
    if (width >= 1200) return DashboardSizeClass.desktop;
    if (width >= 760) return DashboardSizeClass.tablet;
    return DashboardSizeClass.mobile;
  }

  static bool isDesktop(double width) => sizeClass(width) == DashboardSizeClass.desktop;
  static bool isTablet(double width) => sizeClass(width) == DashboardSizeClass.tablet;
  static bool isMobile(double width) => sizeClass(width) == DashboardSizeClass.mobile;

  static EdgeInsets pagePadding(double width) {
    if (isDesktop(width)) return const EdgeInsets.all(24);
    if (isTablet(width)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(14);
  }

  static double maxContentWidth(double width) {
    if (isDesktop(width)) return 1360;
    if (isTablet(width)) return 1040;
    return double.infinity;
  }

  static int adaptiveCardColumns(double width, {int maxColumns = 4}) {
    if (width >= 1280) return maxColumns.clamp(1, 6);
    if (width >= 1024) return maxColumns >= 3 ? 3 : maxColumns;
    if (width >= 720) return 2;
    return 1;
  }
}

class AdaptiveDashboardGrid extends StatelessWidget {
  const AdaptiveDashboardGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.spacing = 12,
    this.childAspectRatioDesktop = 2.0,
    this.childAspectRatioTablet = 1.8,
    this.childAspectRatioMobile = 2.2,
  });

  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double childAspectRatioDesktop;
  final double childAspectRatioTablet;
  final double childAspectRatioMobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = DashboardResponsive.adaptiveCardColumns(width, maxColumns: maxColumns);
        final ratio = DashboardResponsive.isDesktop(width)
            ? childAspectRatioDesktop
            : DashboardResponsive.isTablet(width)
                ? childAspectRatioTablet
                : childAspectRatioMobile;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: ratio,
          ),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
