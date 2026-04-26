import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/gradient_page_shell.dart';
import '../utils/error_handler.dart';

/// Parent / teacher notification list. Realtime: Socket.IO `/notifications`, auth token.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final provider = Provider.of<NotificationsProvider>(context, listen: false);
    await ErrorHandler.handleApiCall<void>(
      context,
      () => provider.load(),
    );
  }

  Future<void> _markRead(String id) async {
    final provider = Provider.of<NotificationsProvider>(context, listen: false);
    await ErrorHandler.handleApiCall<void>(
      context,
      () => provider.markRead(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: EduBridgeTypography.titleLarge.copyWith(
            color: EduBridgeColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xE6EEF2FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: EduBridgeColors.textPrimary,
        shadowColor: Colors.black.withOpacity(0.06),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, notifications, _) => GradientPageShell(
          showAmbientOrbs: false,
          child: notifications.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.error != null
                ? Center(
                    child: Text(
                      notifications.error!,
                      style: EduBridgeTypography.bodyLarge.copyWith(
                        color: EduBridgeColors.error,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: EduBridgeColors.primary,
                    child: notifications.items.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.25,
                              ),
                              Center(
                                child: Text(
                                  'No notifications yet',
                                  style: EduBridgeTypography.bodyLarge.copyWith(
                                    color: EduBridgeColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              EduBridgeTheme.spacingLG,
                              8,
                              EduBridgeTheme.spacingLG,
                              EduBridgeTheme.spacingXL,
                            ),
                            itemCount: notifications.items.length,
                            itemBuilder: (context, i) {
                              final n = notifications.items[i];
                              final id = n['id']?.toString() ?? '';
                              final unread =
                                  n['status']?.toString() == 'UNREAD';
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 280 + (i.clamp(0, 8) * 36),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, v, child) {
                                  return Opacity(
                                    opacity: v,
                                    child: Transform.translate(
                                      offset: Offset(0, 10 * (1 - v)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    padding: EdgeInsets.zero,
                                    margin: EdgeInsets.zero,
                                    borderRadius: BorderRadius.circular(
                                      EduBridgeTheme.radiusLG,
                                    ),
                                    enableHover: true,
                                    onTap: unread && id.isNotEmpty
                                        ? () => _markRead(id)
                                        : null,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: EduBridgeTheme.spacingMD,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        n['title']?.toString() ?? '',
                                        style: EduBridgeTypography.titleSmall
                                            .copyWith(
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: EduBridgeColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          n['message']?.toString() ?? '',
                                          style: EduBridgeTypography.bodySmall
                                              .copyWith(
                                            color: EduBridgeColors.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      trailing: unread
                                          ? TextButton(
                                              onPressed: id.isEmpty
                                                  ? null
                                                  : () => _markRead(id),
                                              child: const Text('Read'),
                                            )
                                          : Icon(
                                              Icons.check_circle_outline,
                                              size: 22,
                                              color: EduBridgeColors.textTertiary,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
        ),
      ),
    );
  }
}
