import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../ui/components/ayah_card.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../utils/error_handler.dart';
import 'admin_subjects_screen.dart';
import 'kid_rewards_screen.dart';
import 'quiz_page.dart';
import 'lesson_reviews_screen.dart';
import 'teacher_courses_screen.dart';

class LessonsPage extends StatefulWidget {
  final String kidId;
  final String kidName;
  final String subjectId;
  final String subjectName;
  final int? schoolLevel;

  const LessonsPage({
    super.key,
    required this.kidId,
    required this.kidName,
    required this.subjectId,
    required this.subjectName,
    this.schoolLevel,
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
      () => quizProvider.loadLessons(
        widget.subjectId,
        schoolLevel: widget.schoolLevel,
      ),
    );
  }

  void _openLessonsManagementByRole() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isTeacher) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const TeacherCoursesScreen()),
      );
      return;
    }
    if (auth.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const AdminSubjectsScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pour ajouter des leçons compatibles avec la matière, connecte-toi avec un compte enseignant ou administrateur.',
        ),
      ),
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
                    IconButton(
                      tooltip: 'Gaming',
                      icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const KidRewardsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AyahCard(
                  ayahText:
                      'هَلْ يَسْتَوِي الَّذِينَ يَعْلَمُونَ وَالَّذِينَ لَا يَعْلَمُونَ',
                ),
              ),
              Expanded(
                child: quizProvider.isLoading
                    ? const Loading()
                    : quizProvider.lessons.isEmpty
                        ? EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'Aucune leçon',
                            message:
                                'Cette matière ne contient pas encore de leçons. Tu peux ouvrir le gaming, ou ajouter des leçons via un compte enseignant/admin.',
                            action: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const KidRewardsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.emoji_events_outlined),
                                  label: const Text('Voir gaming'),
                                ),
                                FilledButton.icon(
                                  onPressed: _openLessonsManagementByRole,
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  label: const Text('Ajouter des leçons'),
                                ),
                              ],
                            ),
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
                                      IconButton(
                                        tooltip: 'Noter la leçon',
                                        icon: const Icon(Icons.rate_review_outlined),
                                        onPressed: () {
                                          final lid = lesson['id']?.toString();
                                          final ltitle =
                                              lesson['title']?.toString() ?? 'Leçon';
                                          if (lid == null || lid.isEmpty) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) => LessonReviewsScreen(
                                                lessonId: lid,
                                                lessonTitle: ltitle,
                                                kidId: widget.kidId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
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
