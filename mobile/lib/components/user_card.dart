import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';

/// Card d'utilisateur avec animations
class UserCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  Color _getRoleColor() {
    switch (widget.user.role) {
      case 'ADMIN':
        return EduBridgeColors.error;
      case 'TEACHER':
        return EduBridgeColors.secondary;
      case 'PARENT':
        return EduBridgeColors.primary;
      default:
        return EduBridgeColors.textSecondary;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.user.role) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'TEACHER':
        return Icons.school;
      case 'PARENT':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (widget.user.hashCode % 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
              onTap: widget.onTap,
              child: Row(
                children: [
                  // Avatar avec badge de rôle
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRoleColor(),
                              _getRoleColor().withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getRoleColor().withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getRoleIcon(),
                          color: EduBridgeColors.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      if (!widget.user.isActive)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: EduBridgeColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EduBridgeColors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.user.fullName,
                                style: EduBridgeTypography.titleMedium.copyWith(
                                  color: EduBridgeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: EduBridgeTheme.spacingSM,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  EduBridgeTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                widget.user.role,
                                style: EduBridgeTypography.labelSmall.copyWith(
                                  color: _getRoleColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: EduBridgeTypography.bodySmall.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.user.isActive) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.block,
                                size: 12,
                                color: EduBridgeColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Inactive',
                                style: EduBridgeTypography.labelSmall.copyWith(
                                  color: EduBridgeColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: EduBridgeColors.textTertiary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
