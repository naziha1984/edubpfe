import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';
import '../theme/edubridge_theme.dart';
import '../theme/edubridge_typography.dart';
import 'dashboard_responsive.dart';
import 'dashboard_tokens.dart';

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.header,
    required this.body,
    this.trailingOverlay,
    this.navItems = const [],
    this.currentNavIndex,
    this.onNavSelected,
    this.showSideNavigationOnDesktop = true,
  });

  final Widget header;
  final Widget body;
  final Widget? trailingOverlay;
  final List<DashboardNavItem> navItems;
  final int? currentNavIndex;
  final ValueChanged<int>? onNavSelected;
  final bool showSideNavigationOnDesktop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final desktop = DashboardResponsive.isDesktop(width);
          final padding = DashboardResponsive.pagePadding(width);
          final maxWidth = DashboardResponsive.maxContentWidth(width);
          final showNav = desktop && showSideNavigationOnDesktop && navItems.isNotEmpty;

          final content = SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Padding(padding: padding, child: header),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          0,
                          padding.right,
                          padding.bottom,
                        ),
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: EduBridgeColors.backgroundGradient,
                ),
              ),
              if (!showNav)
                content
              else
                Row(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 24, 6, 24),
                        child: _DashboardSideNav(
                          items: navItems,
                          selectedIndex: currentNavIndex ?? 0,
                          onSelected: onNavSelected,
                        ),
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
              if (trailingOverlay != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: EduBridgeTheme.spacingLG,
                        bottom: EduBridgeTheme.spacingLG,
                      ),
                      child: trailingOverlay!,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardSideNav extends StatelessWidget {
  const _DashboardSideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DashboardNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: EduBridgeColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: DashboardTokens.cardShadow,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = index == selectedIndex;
          return Material(
            color: selected ? EduBridgeColors.primary.withOpacity(0.11) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSelected == null ? null : () => onSelected!(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: selected ? EduBridgeColors.primary : EduBridgeColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: EduBridgeTypography.bodyMedium.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? EduBridgeColors.primary
                              : EduBridgeColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
