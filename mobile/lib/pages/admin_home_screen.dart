import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/app_router.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import 'admin_users_screen.dart';
import '../ui/transitions/page_transitions.dart';
import 'admin_subjects_screen.dart';

/// Écran d'accueil Admin moderne avec KPIs
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les stats au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.user;

    // Protection : Seuls les ADMIN peuvent accéder
    if (!authProvider.isAdmin) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
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
                          'Admin Dashboard',
                          style: EduBridgeTypography.headlineMedium.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, ${user?.firstName ?? 'Admin'}!',
                          style: EduBridgeTypography.bodyMedium.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                        ),
                      ],
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
                      _buildKPIsSection(adminProvider),
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

  Widget _buildKPIsSection(AdminProvider adminProvider) {
    if (adminProvider.isLoadingStats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              Expanded(
                child: LoadingSkeleton(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (adminProvider.statsError != null) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Stats',
        message: adminProvider.statsError ?? 'Unknown error',
        onRetry: () => adminProvider.loadStats(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Users KPI
        _buildKPICard(
          icon: Icons.people,
          title: 'Total Users',
          value: adminProvider.totalUsers.toString(),
          color: EduBridgeColors.primary,
          gradient: EduBridgeColors.primaryGradient,
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Subjects & Lessons KPIs
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                icon: Icons.subject,
                title: 'Subjects',
                value: adminProvider.totalSubjects.toString(),
                color: EduBridgeColors.secondary,
                gradient: EduBridgeColors.accentGradient,
              ),
            ),
            const SizedBox(width: EduBridgeTheme.spacingMD),
            Expanded(
              child: _buildKPICard(
                icon: Icons.menu_book,
                title: 'Lessons',
                value: adminProvider.totalLessons.toString(),
                color: EduBridgeColors.accent,
                gradient: const LinearGradient(
                  colors: [EduBridgeColors.accent, EduBridgeColors.secondary],
                ),
              ),
            ),
          ],
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
        // User Management
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fadeSlideRoute(
                const AdminUsersScreen(),
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
                  Icons.people,
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
                      'User Management',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage users, roles, and permissions',
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
        const SizedBox(height: EduBridgeTheme.spacingSM),
        // Subjects Management
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.fadeSlideRoute(
                const AdminSubjectsScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.subject,
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
                      'Manage Subjects',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Create and manage subjects',
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
        const SizedBox(height: EduBridgeTheme.spacingSM),
        // System Settings (placeholder)
        GlassCard(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('System Settings - Coming Soon'),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                decoration: BoxDecoration(
                  color: EduBridgeColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.settings,
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
                      'System Settings',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Configure system-wide settings',
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
