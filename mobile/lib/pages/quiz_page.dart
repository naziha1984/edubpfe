import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../providers/quiz_provider.dart';
import '../utils/error_handler.dart';
import 'quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final String kidId;
  final String kidName;
  final String lessonId;
  final String lessonName;

  const QuizPage({
    super.key,
    required this.kidId,
    required this.kidName,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _ready = false;
  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final qp = Provider.of<QuizProvider>(context, listen: false);

    final sessionOk = await ErrorHandler.handleApiCall<bool>(
      context,
      () async {
        await qp.createSession(
          kidId: widget.kidId,
          lessonId: widget.lessonId,
        );
        return true;
      },
    );
    if (!mounted || sessionOk != true) return;

    final sid = qp.currentSession?['id']?.toString();
    if (sid == null || sid.isEmpty) return;

    final raw = await ErrorHandler.handleApiCall<List<dynamic>>(
      context,
      () => qp.loadQuizQuestionsForSession(sid),
    );
    if (!mounted) return;

    setState(() {
      _questions = (raw ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _ready = true;
    });
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty) return;

    if (_selectedAnswers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer every question'),
          backgroundColor: EduBridgeColors.warning,
        ),
      );
      return;
    }

    final answers = _questions.map((q) {
      final idx = (q['questionIndex'] as num?)?.toInt() ?? 0;
      return {
        'questionIndex': idx,
        'selectedAnswer': _selectedAnswers[idx],
      };
    }).toList();

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final rawSessionId = quizProvider.currentSession?['id'];
    final sessionId = rawSessionId?.toString();

    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session not found'),
          backgroundColor: EduBridgeColors.error,
        ),
      );
      return;
    }

    final success = await ErrorHandler.handleApiCall(
      context,
      () => quizProvider.submitQuiz(
        sessionId: sessionId,
        answers: answers,
      ),
    );

    if (mounted && success == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultPage(
            result: quizProvider.quizResult!,
            lessonName: widget.lessonName,
          ),
        ),
      );
    }
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
          child: !(_ready && !quizProvider.isLoading)
              ? const Loading(message: 'Loading quiz...')
              : _questions.isEmpty
                  ? _buildNoQuestions(context)
                  : Column(
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
                                      widget.lessonName,
                                      style: EduBridgeTypography.headlineSmall
                                          .copyWith(
                                        color: EduBridgeColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Quiz',
                                      style: EduBridgeTypography.bodyMedium
                                          .copyWith(
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
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _questions.length,
                            itemBuilder: (context, i) {
                              return _buildQuestionCard(_questions[i]);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GradientButton(
                            text: 'Submit Quiz',
                            icon: Icons.check,
                            onPressed: _submitQuiz,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildNoQuestions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 64, color: EduBridgeColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No quiz for this lesson',
            textAlign: TextAlign.center,
            style: EduBridgeTypography.titleLarge.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An admin or teacher must add quiz questions to this lesson in the database.',
            textAlign: TextAlign.center,
            style: EduBridgeTypography.bodyMedium.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final index = (q['questionIndex'] as num?)?.toInt() ?? 0;
    final question = q['question']?.toString() ?? '';
    final rawOptions = q['options'];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList()
        : <String>[];

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}',
            style: EduBridgeTypography.labelMedium.copyWith(
              color: EduBridgeColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: EduBridgeTypography.titleMedium.copyWith(
              color: EduBridgeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            return RadioListTile<int>(
              title: Text(option),
              value: optionIndex,
              groupValue: _selectedAnswers[index],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedAnswers[index] = value;
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
