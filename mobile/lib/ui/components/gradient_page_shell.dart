import 'package:flutter/material.dart';
import '../theme/edubridge_colors.dart';

/// Fond plein écran : gradient global + halos radiaux discrets (profondeur premium).
class GradientPageShell extends StatelessWidget {
  const GradientPageShell({
    super.key,
    required this.child,
    this.showAmbientOrbs = true,
  });

  final Widget child;
  final bool showAmbientOrbs;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final orbPrimary = dark ? 0.14 : 0.11;
    final orbAccent = dark ? 0.11 : 0.09;
    final orbSecondary = dark ? 0.09 : 0.07;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: dark
                ? EduBridgeColors.backgroundGradientDark
                : EduBridgeColors.backgroundGradient,
          ),
        ),
        if (showAmbientOrbs) ...[
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EduBridgeColors.primary.withOpacity(orbPrimary),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EduBridgeColors.accent.withOpacity(orbAccent),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EduBridgeColors.secondary.withOpacity(orbSecondary),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.68],
                  ),
                ),
              ),
            ),
          ),
        ],
        child,
      ],
    );
  }
}
