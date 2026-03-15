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
  bool _sessionCreated = false;
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => quizProvider.createSession(
        kidId: widget.kidId,
        lessonId: widget.lessonId,
      ),
    );

    if (mounted && success == true) {
      setState(() {
        _sessionCreated = true;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer at least one question'),
          backgroundColor: EduBridgeColors.warning,
        ),
      );
      return;
    }

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final sessionId = quizProvider.currentSession?['id'];

    if (sessionId == null) {
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
        answers: _answers,
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
          child: quizProvider.isLoading || !_sessionCreated
              ? const Loading(message: 'Loading quiz...')
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
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Mock questions - in real app, fetch from API
                          _buildQuestion(
                            index: 0,
                            question: 'What is 2 + 2?',
                            options: ['3', '4', '5', '6'],
                            correctAnswer: 1,
                          ),
                          _buildQuestion(
                            index: 1,
                            question: 'What is the capital of France?',
                            options: ['London', 'Berlin', 'Paris', 'Madrid'],
                            correctAnswer: 2,
                          ),
                        ],
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

  Widget _buildQuestion({
    required int index,
    required String question,
    required List<String> options,
    required int correctAnswer,
  }) {
    int? selectedAnswer;

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
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value;
                  _answers.removeWhere((a) => a['questionIndex'] == index);
                  _answers.add({
                    'questionIndex': index,
                    'selectedAnswer': value,
                  });
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
