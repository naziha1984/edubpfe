import 'package:flutter/material.dart';
import '../theme/edubridge_colors.dart';
import '../theme/edubridge_typography.dart';
import '../theme/edubridge_theme.dart';
import 'gradient_button.dart';

/// État vide avec illustration et CTA
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EduBridgeTheme.spacing2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon avec animation subtile
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                      decoration: BoxDecoration(
                        color: EduBridgeColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 64,
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: EduBridgeTheme.spacingLG),
            
            // Title
            Text(
              title,
              style: EduBridgeTypography.titleLarge.copyWith(
                color: EduBridgeColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Message
            if (message != null) ...[
              const SizedBox(height: EduBridgeTheme.spacingSM),
              Text(
                message!,
                style: EduBridgeTypography.bodyMedium.copyWith(
                  color: EduBridgeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action
            if (action != null || (actionLabel != null && onAction != null)) ...[
              const SizedBox(height: EduBridgeTheme.spacingXL),
              action ??
                  GradientButton(
                    text: actionLabel!,
                    onPressed: onAction,
                    width: 200,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
