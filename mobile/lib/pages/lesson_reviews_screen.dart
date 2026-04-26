import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/star_rating_input.dart';
import '../components/toast.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/error_handler.dart';

class LessonReviewsScreen extends StatefulWidget {
  const LessonReviewsScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.kidId,
  });

  final String lessonId;
  final String lessonTitle;
  final String kidId;

  @override
  State<LessonReviewsScreen> createState() => _LessonReviewsScreenState();
}

class _LessonReviewsScreenState extends State<LessonReviewsScreen> {
  bool _loading = true;
  bool _submitting = false;
  int _stars = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  List<Map<String, dynamic>> _reviews = [];
  double _average = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      () => api.getLessonReviews(widget.lessonId),
    );
    if (!mounted || data == null) return;
    final items = (data['items'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final myParentReview = items.cast<Map<String, dynamic>?>().firstWhere(
          (r) => (r?['kidId']?.toString() ?? '') == widget.kidId || (r?['kidId'] == null),
          orElse: () => null,
        );
    setState(() {
      _average = ((data['averageStars'] as num?) ?? 0).toDouble();
      _total = ((data['totalReviews'] as num?) ?? 0).toInt();
      _reviews = items;
      if (myParentReview != null) {
        _stars = ((myParentReview['stars'] as num?) ?? 0).toInt();
        _commentCtrl.text = myParentReview['comment']?.toString() ?? '';
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_stars < 1 || _stars > 5) {
      Toast.error(context, 'Choisis une note entre 1 et 5');
      return;
    }
    setState(() => _submitting = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final ok = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      () => api.upsertLessonReview(
        lessonId: widget.lessonId,
        stars: _stars,
        comment: _commentCtrl.text.trim(),
        kidId: widget.kidId,
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok != null) {
      Toast.success(context, 'Avis enregistré');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis - ${widget.lessonTitle}'),
      ),
      body: _loading
          ? const Loading(message: 'Chargement des avis...')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note moyenne',
                          style: EduBridgeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text(
                              _total > 0 ? _average.toStringAsFixed(1) : '-',
                              style: EduBridgeTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($_total avis)',
                              style: EduBridgeTypography.bodySmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ton avis',
                          style: EduBridgeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StarRatingInput(
                          value: _stars,
                          onChanged: (v) => setState(() => _stars = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ajoute un commentaire (optionnel)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(_submitting ? 'Envoi...' : 'Envoyer / Mettre à jour'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Avis des parents',
                    style: EduBridgeTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_reviews.isEmpty)
                    GlassCard(
                      child: Text(
                        'Aucun avis pour le moment.',
                        style: EduBridgeTypography.bodyMedium.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ..._reviews.map((r) {
                      final stars = ((r['stars'] as num?) ?? 0).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r['parentName']?.toString().isNotEmpty == true
                                          ? r['parentName'].toString()
                                          : 'Parent',
                                      style: EduBridgeTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  StarRatingInput(value: stars, onChanged: null, size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (r['comment']?.toString() ?? '').isEmpty
                                    ? 'Sans commentaire'
                                    : r['comment'].toString(),
                                style: EduBridgeTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
