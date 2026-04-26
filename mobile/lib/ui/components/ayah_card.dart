import 'package:flutter/material.dart';

import '../theme/edubridge_theme.dart';

/// Reusable premium card for centered Arabic text.
class AyahCard extends StatelessWidget {
  const AyahCard({
    super.key,
    required this.ayahText,
    this.padding,
    this.margin,
    this.textStyle,
    this.gradient,
    this.backgroundColor,
  });

  final String ayahText;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final LinearGradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final cardPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isCompact
              ? EduBridgeTheme.spacingMD
              : EduBridgeTheme.spacingLG,
          vertical: isCompact
              ? EduBridgeTheme.spacingMD
              : EduBridgeTheme.spacingLG,
        );
    final effectiveTextStyle = textStyle ??
        TextStyle(
          fontSize: isCompact ? 20 : 24,
          fontWeight: FontWeight.w700,
          height: 1.7,
          color: colorScheme.onSurface,
        );

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient ??
            (backgroundColor == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF1F2937), Color(0xFF27364D)]
                        : const [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
                  )
                : null),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: isDark ? 14 : 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: cardPadding,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            ayahText,
            textAlign: TextAlign.center,
            style: effectiveTextStyle,
          ),
        ),
      ),
    );
  }
}
