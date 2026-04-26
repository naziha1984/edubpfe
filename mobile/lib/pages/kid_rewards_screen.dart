import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../ui/gamification/gamification_widgets.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/theme/edubridge_typography.dart';
import '../utils/error_handler.dart';

class KidRewardsScreen extends StatefulWidget {
  const KidRewardsScreen({super.key});

  @override
  State<KidRewardsScreen> createState() => _KidRewardsScreenState();
}

class _KidRewardsScreenState extends State<KidRewardsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final res = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      api.getKidRewards,
    );
    if (!mounted) return;
    setState(() {
      _data = res;
      _loading = false;
    });
  }

  int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final totalPoints = _asInt(data?['totalXP'] ?? data?['totalPoints'] ?? data?['points']);
    final currentLevel = _asInt(data?['currentLevel']);
    final xpForNext = _asInt(data?['xpForNextLevel'] ?? data?['nextMilestonePoints']);
    final currentStreak = _asInt(data?['currentStreak'] ?? data?['streak']);
    final bestStreak = _asInt(data?['bestStreak']);
    final history =
        ((data?['recentHistory'] as List?) ?? const []).cast<dynamic>().take(15).toList();
    final badges = ((data?['badges'] as List?) ?? const []).cast<dynamic>().toList();

    final milestoneTarget = xpForNext > 0 ? totalPoints + xpForNext : (totalPoints + 100);
    final milestoneProgress =
        milestoneTarget <= 0 ? 0.0 : (totalPoints / milestoneTarget).clamp(0.0, 1.0);

    final achievements = <Map<String, dynamic>>[
      {
        'title': 'Consistency',
        'progress': (currentStreak / 14).clamp(0.0, 1.0),
        'icon': Icons.event_repeat_rounded,
      },
      {
        'title': 'Badge collector',
        'progress': (badges.length / 10).clamp(0.0, 1.0),
        'icon': Icons.workspace_premium_rounded,
      },
      {
        'title': 'Level progression',
        'progress': (currentLevel / 12).clamp(0.0, 1.0),
        'icon': Icons.trending_up_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: EduBridgeColors.backgroundGradient),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : data == null
                ? const Center(child: Text('Erreur de chargement'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                      children: [
                        const MotivationalStateCard(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Keep building your learning momentum',
                          message:
                              'Every completed lesson contributes to meaningful long-term growth.',
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 1. points summary card
                        PointsSummaryCard(
                          totalPoints: totalPoints,
                          currentLevel: currentLevel,
                          nextMilestonePoints: milestoneTarget,
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 4. current streak card
                        GamificationSectionCard(
                          title: 'Current streak',
                          subtitle: 'Build regularity to reinforce learning outcomes',
                          child: StreakCard(
                            currentStreak: currentStreak,
                            bestStreak: bestStreak < currentStreak ? currentStreak : bestStreak,
                          ),
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 2. earned badges
                        GamificationSectionCard(
                          title: 'Earned badges',
                          subtitle: 'Academic achievements unlocked over time',
                          child: badges.isEmpty
                              ? const MotivationalStateCard(
                                  icon: Icons.workspace_premium_rounded,
                                  title: 'No badge yet',
                                  message:
                                      'Complete lessons and quizzes to unlock your first badge.',
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: badges.map((b) {
                                    final m = Map<String, dynamic>.from(b as Map);
                                    return BadgePill(
                                      icon: Icons.workspace_premium_rounded,
                                      name: m['name']?.toString() ?? 'Badge',
                                      subtitle: m['description']?.toString(),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 3. achievements progress
                        GamificationSectionCard(
                          title: 'Achievements progress',
                          subtitle: 'Track key indicators with clear goals',
                          child: Column(
                            children: achievements.map((a) {
                              return AchievementProgressTile(
                                title: a['title']?.toString() ?? '',
                                progress: (a['progress'] as num).toDouble(),
                                leadingIcon: a['icon'] as IconData,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 5. milestone progress bar
                        GamificationSectionCard(
                          title: 'Milestone progress',
                          subtitle: 'Progress rewards based on consistent performance',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$totalPoints / $milestoneTarget points',
                                      style: EduBridgeTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(milestoneProgress * 100).toStringAsFixed(0)}%',
                                    style: EduBridgeTypography.labelMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 9,
                                  value: milestoneProgress,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 6. rewards history
                        GamificationSectionCard(
                          title: 'Rewards history',
                          subtitle: 'Recent recognized learning actions',
                          child: history.isEmpty
                              ? const MotivationalStateCard(
                                  icon: Icons.history_toggle_off_rounded,
                                  title: 'No reward history yet',
                                  message:
                                      'Your milestones and reward events will appear here soon.',
                                )
                              : Column(
                                  children: history.map((h) {
                                    final m = Map<String, dynamic>.from(h as Map);
                                    final earned = _asInt(m['xpEarned'] ?? m['points']);
                                    final source = m['source']?.toString() ?? 'activity';
                                    final dt = _parseDate(m['createdAt']);
                                    final dateText = dt == null
                                        ? ''
                                        : DateFormat('dd/MM/yyyy').format(dt.toLocal());
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(EduBridgeTheme.radiusLG),
                                        border: Border.all(color: EduBridgeColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Color(0xFFEEF2FF),
                                            child: Icon(
                                              Icons.emoji_events_outlined,
                                              size: 16,
                                              color: EduBridgeColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '+$earned points · $source',
                                                  style: EduBridgeTypography.titleSmall.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  m['description']?.toString() ?? dateText,
                                                  style: EduBridgeTypography.bodySmall.copyWith(
                                                    color: EduBridgeColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (dateText.isNotEmpty)
                                            Text(
                                              dateText,
                                              style: EduBridgeTypography.labelSmall.copyWith(
                                                color: EduBridgeColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: EduBridgeTheme.spacingMD),

                        // 7. motivational success state
                        if (currentStreak >= 7 || badges.isNotEmpty)
                          const MotivationalStateCard(
                            icon: Icons.verified_rounded,
                            title: 'Great momentum',
                            message:
                                'You are building strong and consistent academic habits. Keep going.',
                            success: true,
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
