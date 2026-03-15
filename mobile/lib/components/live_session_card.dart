import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/live_session_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/gradient_button.dart';

/// Card de live session avec countdown et bouton Join
class LiveSessionCard extends StatefulWidget {
  final LiveSessionModel session;
  final int index;
  final VoidCallback? onTap;
  final bool showJoinButton; // Pour afficher le bouton Join (kid view)

  const LiveSessionCard({
    super.key,
    required this.session,
    required this.index,
    this.onTap,
    this.showJoinButton = false,
  });

  @override
  State<LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<LiveSessionCard> {
  Timer? _countdownTimer;
  Duration _timeUntilStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Mettre à jour le countdown toutes les secondes
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateCountdown();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    _timeUntilStart = widget.session.timeUntilStart;
  }

  Color _getStatusColor(LiveSessionStatus status) {
    switch (status) {
      case LiveSessionStatus.scheduled:
        return EduBridgeColors.info;
      case LiveSessionStatus.live:
        return EduBridgeColors.success;
      case LiveSessionStatus.completed:
        return EduBridgeColors.textTertiary;
      case LiveSessionStatus.cancelled:
        return EduBridgeColors.error;
    }
  }

  Future<void> _joinMeeting() async {
    final url = Uri.parse(widget.session.meetingUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien: ${widget.session.meetingUrl}'),
            backgroundColor: EduBridgeColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDateFormatted = DateFormat('dd MMM yyyy', 'fr_FR')
        .format(widget.session.scheduledAt);
    final scheduledTimeFormatted = DateFormat('HH:mm', 'fr_FR')
        .format(widget.session.scheduledAt);

    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
                decoration: BoxDecoration(
                  gradient: EduBridgeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    EduBridgeTheme.radiusMD,
                  ),
                ),
                child: const Icon(
                  Icons.video_call,
                  color: EduBridgeColors.textOnPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.title,
                      style: EduBridgeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: EduBridgeColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.session.className != 'Unknown Class') ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.session.className,
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EduBridgeTheme.spacingSM,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.session.status)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    EduBridgeTheme.radiusSM,
                  ),
                  border: Border.all(
                    color: _getStatusColor(widget.session.status)
                        .withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.session.status.displayName,
                  style: EduBridgeTypography.labelSmall.copyWith(
                    color: _getStatusColor(widget.session.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (widget.session.description != null &&
              widget.session.description!.isNotEmpty) ...[
            const SizedBox(height: EduBridgeTheme.spacingSM),
            Text(
              widget.session.description!,
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: EduBridgeTheme.spacingSM),
          // Date & Time
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: EduBridgeColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '$scheduledDateFormatted à $scheduledTimeFormatted',
                style: EduBridgeTypography.bodySmall.copyWith(
                  color: EduBridgeColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Countdown (si session à venir)
          if (widget.session.isUpcoming && !_timeUntilStart.isNegative) ...[
            const SizedBox(height: EduBridgeTheme.spacingSM),
            Container(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
              decoration: BoxDecoration(
                color: EduBridgeColors.infoContainer,
                borderRadius: BorderRadius.circular(
                  EduBridgeTheme.radiusMD,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: EduBridgeColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dans ${widget.session.timeUntilStartFormatted}',
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Join button (pour kid view)
          if (widget.showJoinButton &&
              (widget.session.isLive || widget.session.isUpcoming)) ...[
            const SizedBox(height: EduBridgeTheme.spacingMD),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: widget.session.isLive ? 'Rejoindre maintenant' : 'Rejoindre',
                icon: Icons.video_call,
                onPressed: _joinMeeting,
                variant: GradientButtonVariant.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
