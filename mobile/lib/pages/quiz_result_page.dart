import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/kpi_card.dart';

class QuizResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  final String lessonName;

  const QuizResultPage({
    super.key,
    required this.result,
    required this.lessonName,
  });

  @override
  Widget build(BuildContext context) {
    final score = result['score'] ?? 0;
    final totalQuestions = result['totalQuestions'] ?? 1;
    final percentage = result['percentage'] ?? 0;
    final passed = result['passed'] ?? false;
    final xpEarned = result['xpEarned'] ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  color: EduBridgeColors.textPrimary,
                ),
                const SizedBox(height: 24),
                // Result Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: passed
                        ? EduBridgeColors.success.withOpacity(0.1)
                        : EduBridgeColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    size: 80,
                    color: passed ? EduBridgeColors.success : EduBridgeColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  passed ? 'Congratulations!' : 'Keep Trying!',
                  style: EduBridgeTypography.displaySmall.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lessonName,
                  style: EduBridgeTypography.bodyLarge.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                // Score Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      KPICard(
                        title: 'Score',
                        value: '$score / $totalQuestions',
                        icon: Icons.star,
                        gradient: EduBridgeColors.primaryGradient,
                      ),
                      const SizedBox(height: 16),
                      KPICard(
                        title: 'Percentage',
                        value: '$percentage%',
                        icon: Icons.percent,
                        gradient: EduBridgeColors.accentGradient,
                      ),
                      if (xpEarned > 0) ...[
                        const SizedBox(height: 16),
                        KPICard(
                          title: 'XP Earned',
                          value: '$xpEarned',
                          icon: Icons.emoji_events,
                          gradient: LinearGradient(
                            colors: [
                              EduBridgeColors.warning,
                              EduBridgeColors.success,
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Back to Lessons',
                  icon: Icons.arrow_back,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
