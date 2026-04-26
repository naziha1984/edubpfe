import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_page_shell.dart';
import '../ui/components/loading_skeleton.dart';
import '../ui/components/glass_card.dart';
import '../components/error_state.dart';
import '../utils/error_handler.dart';

class TeacherLessonRatingsScreen extends StatefulWidget {
  const TeacherLessonRatingsScreen({super.key});

  @override
  State<TeacherLessonRatingsScreen> createState() =>
      _TeacherLessonRatingsScreenState();
}

class _TeacherLessonRatingsScreenState
    extends State<TeacherLessonRatingsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _error = null;

    final api = Provider.of<ApiService>(context, listen: false);
    final data = await ErrorHandler.handleApiCall<List<dynamic>>(
      context,
      () => api.getTeacherLessonRatingsSummary(),
    );

    if (!mounted) return;
    if (data == null) {
      setState(() {
        _error = 'Impossible de charger les avis.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _items = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _items.sort((a, b) {
        final ra = (a['averageStars'] as num?)?.toDouble() ?? 0;
        final rb = (b['averageStars'] as num?)?.toDouble() ?? 0;
        return rb.compareTo(ra);
      });
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientPageShell(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Parent ratings & reviews',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: EduBridgeColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                        itemCount: 6,
                        itemBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LoadingSkeleton(
                            width: double.infinity,
                            height: 84,
                            borderRadius:
                                BorderRadius.circular(EduBridgeTheme.radiusLG),
                          ),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: ErrorState(
                              icon: Icons.error_outline_rounded,
                              title: 'Erreur',
                              message: _error!,
                              onRetry: _load,
                            ),
                          )
                        : _items.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Aucune note pour le moment.',
                                      style: EduBridgeTypography.bodyLarge.copyWith(
                                        color: EduBridgeColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(
                                  EduBridgeTheme.spacingLG,
                                ),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final title =
                                      item['lessonTitle']?.toString() ?? '';
                                  final avg = (item['averageStars'] as num?)
                                          ?.toDouble() ??
                                      0;
                                  final total = (item['totalReviews'] as num?)
                                          ?.toInt() ??
                                      0;

                                  return GlassCard(
                                    padding: const EdgeInsets.all(
                                      EduBridgeTheme.spacingMD,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            EduBridgeTheme.spacingSM,
                                          ),
                                          decoration: BoxDecoration(
                                            color: EduBridgeColors.primary
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(
                                              EduBridgeTheme.radiusMD,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: EduBridgeTheme.spacingMD,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: EduBridgeTypography
                                                    .titleMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: EduBridgeColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '$avg.toStringAsFixed(1) / 5.0 • $total avis',
                                                style: EduBridgeTypography
                                                    .bodySmall
                                                    .copyWith(
                                                  color: EduBridgeColors.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: EduBridgeColors.textTertiary,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

