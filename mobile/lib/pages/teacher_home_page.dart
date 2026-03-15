import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../providers/auth_provider.dart';
import '../utils/app_router.dart';
import 'login_page.dart';
import 'classes_page.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Protection : Seuls les TEACHER peuvent accéder à cette page
    if (!authProvider.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('⚠️ [TeacherHomePage] Access denied for role: ${authProvider.userRole}');
        debugPrint('⚠️ [TeacherHomePage] Redirecting to appropriate home page');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppRouter.getHomePage(context),
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Teacher Dashboard',
                      style: EduBridgeTypography.headlineMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        authProvider.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user?.firstName ?? 'Teacher'}!',
                              style: EduBridgeTypography.headlineSmall.copyWith(
                                color: EduBridgeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Teacher Panel',
                              style: EduBridgeTypography.bodyLarge.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: EduBridgeColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'TEACHER',
                                style: EduBridgeTypography.labelMedium.copyWith(
                                  color: EduBridgeColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Teacher Features
                      Text(
                        'My Classes',
                        style: EduBridgeTypography.titleLarge.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Classes Management
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        onTap: () {
                          // Navigate to classes page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClassesPage(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EduBridgeColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.class_,
                                color: EduBridgeColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manage Classes',
                                    style: EduBridgeTypography.titleMedium.copyWith(
                                      color: EduBridgeColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Create and manage your classes',
                                    style: EduBridgeTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Students
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        onTap: () {
                          // TODO: Navigate to students
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Students Management - Coming Soon'),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EduBridgeColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school,
                                color: EduBridgeColors.secondary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Students',
                                    style: EduBridgeTypography.titleMedium.copyWith(
                                      color: EduBridgeColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'View and manage your students',
                                    style: EduBridgeTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ],
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
