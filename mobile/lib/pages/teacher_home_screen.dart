import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/gradient_page_shell.dart';
import '../providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import '../utils/app_router.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import 'teacher_classes_screen.dart';
import 'teacher_students_hub_screen.dart';
import 'teacher_courses_screen.dart';
import 'notifications_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Écran d'accueil Teacher moderne avec KPIs
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les stats au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
      teacherProvider.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final user = authProvider.user;

    // Protection : Seuls les TEACHER peuvent accéder
    if (!authProvider.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      backgroundColor: Colors.transparent,
      body: GradientPageShell(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Dashboard',
                          style: EduBridgeTypography.headlineMedium.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, ${user?.firstName ?? 'Teacher'}!',
                          style: EduBridgeTypography.bodyMedium.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      color: EduBridgeColors.textPrimary,
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
                      color: EduBridgeColors.textPrimary,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KPIs Cards
                      _buildKPIsSection(teacherProvider),
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      // Quick Actions
                      _buildQuickActionsSection(context),
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

  Widget _buildKPIsSection(TeacherProvider teacherProvider) {
    if (teacherProvider.isLoadingStats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          LoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ],
      );
    }

    if (teacherProvider.statsError != null) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Stats',
        message: teacherProvider.statsError ?? 'Unknown error',
        onRetry: () => teacherProvider.loadStats(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Classes KPI
        _buildKPICard(
          icon: Icons.class_,
          title: 'Total Classes',
          value: teacherProvider.totalClasses.toString(),
          color: EduBridgeColors.primary,
          gradient: EduBridgeColors.primaryGradient,
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Total Students KPI
        _buildKPICard(
          icon: Icons.people,
          title: 'Total Students',
          value: teacherProvider.totalStudents.toString(),
          color: EduBridgeColors.secondary,
          gradient: EduBridgeColors.accentGradient,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: Icon(
                  icon,
                  color: EduBridgeColors.textOnPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Text(
            value,
            style: EduBridgeTypography.displaySmall.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: EduBridgeTypography.bodyMedium.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: EduBridgeTypography.titleLarge.copyWith(
            color: EduBridgeColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Manage Classes
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fadeSlideRoute(
                const TeacherClassesScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.class_,
                  color: EduBridgeColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
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
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: EduBridgeColors.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fadeSlideRoute(
                const TeacherStudentsHubScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: EduBridgeColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Add students to your classes (child ID)',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: EduBridgeColors.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fadeSlideRoute(
                const TeacherCoursesScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: EduBridgeColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Courses & lessons',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Create subjects and lesson content',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: EduBridgeColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
