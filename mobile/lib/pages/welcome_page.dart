import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget _buildLogo() {
    // Try to load logo from assets, fallback to icon
    try {
      return Image.asset(
        'assets/images/logo.png',
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.school,
            size: 80,
            color: EduBridgeColors.primary,
          );
        },
      );
    } catch (e) {
      return Icon(
        Icons.school,
        size: 80,
        color: EduBridgeColors.primary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: EduBridgeColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _buildLogo(),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Welcome to',
                  style: EduBridgeTypography.headlineSmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EduBridge',
                  style: EduBridgeTypography.displaySmall.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your gateway to personalized learning',
                  style: EduBridgeTypography.bodyLarge.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Buttons
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GradientButton(
                        text: 'Get Started',
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        text: 'Sign In',
                        gradient: LinearGradient(
                          colors: [
                            EduBridgeColors.surface,
                            EduBridgeColors.surface,
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
