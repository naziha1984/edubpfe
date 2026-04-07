import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../providers/quiz_provider.dart';
import '../utils/error_handler.dart';
import 'lessons_page.dart';
import 'kid_rewards_screen.dart';

class SubjectsPage extends StatefulWidget {
  final String kidId;
  final String kidName;

  const SubjectsPage({
    super.key,
    required this.kidId,
    required this.kidName,
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await ErrorHandler.handleApiCall(
      context,
      () => quizProvider.loadSubjects(),
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
                      tooltip: 'Retour',
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Matières',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Récompenses',
                      icon: const Icon(Icons.star_rounded, color: Colors.amber),
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
              Expanded(
                child: quizProvider.isLoading
                    ? const Loading()
                    : quizProvider.subjects.isEmpty
                        ? const EmptyState(
                            icon: Icons.book_outlined,
                            title: 'Aucune matière',
                            message:
                                'Les matières et leçons sont créées par un enseignant ou un administrateur. '
                                'Connecte-toi avec un compte enseignant ou admin pour les ajouter.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSubjects,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: quizProvider.subjects.length,
                              itemBuilder: (context, index) {
                                final subject = quizProvider.subjects[index];
                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  onTap: () {
                                    final sid = subject['id']?.toString();
                                    final sname =
                                        subject['name']?.toString() ?? 'Matière';
                                    if (sid == null || sid.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Matière invalide (identifiant manquant)',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LessonsPage(
                                          kidId: widget.kidId,
                                          kidName: widget.kidName,
                                          subjectId: sid,
                                          subjectName: sname,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: EduBridgeColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.book,
                                          color: Colors.white,
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
                                              subject['name'] ?? 'Subject',
                                              style: EduBridgeTypography.titleLarge
                                                  .copyWith(
                                                color: EduBridgeColors.textPrimary,
                                              ),
                                            ),
                                            if (subject['description'] != null)
                                              Text(
                                                subject['description'],
                                                style: EduBridgeTypography.bodyMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios),
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
