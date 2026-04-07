import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../providers/quiz_provider.dart';
import '../utils/error_handler.dart';
import 'quiz_page.dart';

class LessonsPage extends StatefulWidget {
  final String kidId;
  final String kidName;
  final String subjectId;
  final String subjectName;

  const LessonsPage({
    super.key,
    required this.kidId,
    required this.kidName,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await ErrorHandler.handleApiCall(
      context,
      () => quizProvider.loadLessons(widget.subjectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subjectName,
                            style: EduBridgeTypography.headlineMedium.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lessons',
                            style: EduBridgeTypography.bodyMedium.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: quizProvider.isLoading
                    ? const Loading()
                    : quizProvider.lessons.isEmpty
                        ? const EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'Aucune leçon',
                            message:
                                'Ajoute des leçons pour cette matière avec un compte enseignant ou administrateur.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLessons,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: quizProvider.lessons.length,
                              itemBuilder: (context, index) {
                                final lesson = quizProvider.lessons[index];
                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  onTap: () {
                                    final lid = lesson['id']?.toString();
                                    final ltitle =
                                        lesson['title']?.toString() ?? 'Leçon';
                                    if (lid == null || lid.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Leçon invalide (identifiant manquant)',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizPage(
                                          kidId: widget.kidId,
                                          kidName: widget.kidName,
                                          lessonId: lid,
                                          lessonName: ltitle,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: EduBridgeColors.accent
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.school,
                                          color: EduBridgeColors.accent,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson['title'] ?? 'Lesson',
                                              style: EduBridgeTypography.titleLarge
                                                  .copyWith(
                                                color: EduBridgeColors.textPrimary,
                                              ),
                                            ),
                                            if (lesson['description'] != null)
                                              Text(
                                                lesson['description'],
                                                style: EduBridgeTypography.bodyMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.play_arrow),
                                    ],
                                  ),
                                );
                              },
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
