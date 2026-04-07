import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/error_handler.dart';

/// Vue gamification (XP, niveau, badges) — design sobre avec accents étoiles.
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
      () async {
        final m = await api.getKidRewards();
        return m;
      },
    );
    if (!mounted) return;
    setState(() {
      _data = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Récompenses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text('Erreur de chargement'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_data!['totalXP'] ?? 0} XP',
                                    style: EduBridgeTypography.headlineSmall
                                        .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: EduBridgeColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Niveau ${_data!['currentLevel'] ?? 0} · Encore ${_data!['xpForNextLevel'] ?? 0} XP pour le prochain',
                                    style: EduBridgeTypography.bodySmall
                                        .copyWith(
                                      color: EduBridgeColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Série : ${_data!['currentStreak'] ?? 0} jours',
                          style: EduBridgeTypography.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Badges',
                          style: EduBridgeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(((_data!['badges'] as List?) ?? []).map((b) {
                          final m = Map<String, dynamic>.from(b as Map);
                          return ListTile(
                            leading: const Icon(Icons.emoji_events_outlined,
                                color: EduBridgeColors.primary),
                            title: Text(m['name']?.toString() ?? ''),
                            subtitle: Text(m['description']?.toString() ?? ''),
                          );
                        })),
                      ],
                    ),
                  ),
      ),
    );
  }
}
