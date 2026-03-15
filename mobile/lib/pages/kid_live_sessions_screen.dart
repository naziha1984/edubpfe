import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/live_sessions_provider.dart';
import '../components/live_session_card.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';

/// Écran pour afficher les live sessions d'un kid
class KidLiveSessionsScreen extends StatefulWidget {
  const KidLiveSessionsScreen({super.key});

  @override
  State<KidLiveSessionsScreen> createState() => _KidLiveSessionsScreenState();
}

class _KidLiveSessionsScreenState extends State<KidLiveSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les live sessions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<LiveSessionsProvider>(context, listen: false);
      provider.loadKidLiveSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LiveSessionsProvider>(context);

    // Séparer les sessions en sections
    final liveNow = provider.kidLiveSessionsNow;
    final upcoming = provider.kidUpcomingSessions;
    final past = provider.kidLiveSessions
        .where((s) => s.isPast)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Sessions Live',
                        style: EduBridgeTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EduBridgeColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: provider.isLoadingKidLiveSessions
                    ? const LoadingSkeleton(width: double.infinity, height: 200)
                    : provider.kidLiveSessionsError != null
                        ? ErrorState(
                            message: provider.kidLiveSessionsError!,
                            onRetry: () {
                              provider.loadKidLiveSessions();
                            },
                          )
                        : provider.kidLiveSessions.isEmpty
                            ? EmptyState(
                                icon: Icons.video_call_outlined,
                                title: 'Aucune session live',
                                message:
                                    'Vous n\'avez pas encore de sessions live programmées',
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await provider.loadKidLiveSessions();
                                },
                                child: ListView(
                                  padding: const EdgeInsets.all(
                                    EduBridgeTheme.spacingLG,
                                  ),
                                  children: [
                                    // Sessions en direct
                                    if (liveNow.isNotEmpty) ...[
                                      Text(
                                        'En direct maintenant',
                                        style: EduBridgeTypography.titleMedium
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: EduBridgeColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: EduBridgeTheme.spacingMD),
                                      ...liveNow.asMap().entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: EduBridgeTheme.spacingMD,
                                          ),
                                          child: LiveSessionCard(
                                            session: entry.value,
                                            index: entry.key,
                                            showJoinButton: true,
                                          ),
                                        );
                                      }),
                                      const SizedBox(
                                          height: EduBridgeTheme.spacingXL),
                                    ],
                                    // Sessions à venir
                                    if (upcoming.isNotEmpty) ...[
                                      Text(
                                        'À venir',
                                        style: EduBridgeTypography.titleMedium
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: EduBridgeColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: EduBridgeTheme.spacingMD),
                                      ...upcoming.asMap().entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: EduBridgeTheme.spacingMD,
                                          ),
                                          child: LiveSessionCard(
                                            session: entry.value,
                                            index: entry.key,
                                            showJoinButton: true,
                                          ),
                                        );
                                      }),
                                      const SizedBox(
                                          height: EduBridgeTheme.spacingXL),
                                    ],
                                    // Sessions passées
                                    if (past.isNotEmpty) ...[
                                      Text(
                                        'Passées',
                                        style: EduBridgeTypography.titleMedium
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: EduBridgeColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: EduBridgeTheme.spacingMD),
                                      ...past.asMap().entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: EduBridgeTheme.spacingMD,
                                          ),
                                          child: LiveSessionCard(
                                            session: entry.value,
                                            index: entry.key,
                                            showJoinButton: false,
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
