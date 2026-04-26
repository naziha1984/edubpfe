import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/admin_dashboard/admin_stat_card.dart';
import '../components/admin_dashboard/dashboard_section.dart';
import '../components/admin_dashboard/status_chip.dart';
import '../components/error_state.dart';
import '../components/teacher_approval_badge.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/loading_skeleton.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/transitions/page_transitions.dart';
import '../utils/app_router.dart';
import 'admin_lesson_monitoring_screen.dart';
import 'admin_subjects_screen.dart';
import 'admin_teacher_request_detail_screen.dart';
import 'admin_teacher_requests_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _teacherSearchCtrl = TextEditingController();
  final _lessonSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadDashboardOverview();
      admin.loadTeachers();
      admin.loadAdminLessons();
      admin.loadNotificationsOverview();
    });
  }

  @override
  void dispose() {
    _teacherSearchCtrl.dispose();
    _lessonSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final user = authProvider.user;
    final avatarInitials = user?.firstName.isNotEmpty == true
        ? user!.firstName[0].toUpperCase()
        : 'A';

    if (!authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppRouter.getHomePage(context)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: EduBridgeTypography.headlineMedium.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Professional control center for approvals, moderation, and platform activity.',
                            style: EduBridgeTypography.bodyMedium.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Welcome back, ${user?.firstName ?? 'Admin'}!',
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Profil',
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            EduBridgeColors.primary.withOpacity(0.18),
                        child: Text(
                          avatarInitials,
                          style: EduBridgeTypography.bodySmall.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          authProvider.logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Se déconnecter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      admin.loadDashboardOverview(),
                      admin.loadTeachers(),
                      admin.loadAdminLessons(),
                      admin.loadNotificationsOverview(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopStats(admin),
                        const SizedBox(height: EduBridgeTheme.spacingLG),
                        _buildQuickActions(context),
                        const SizedBox(height: EduBridgeTheme.spacingLG),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 1100;
                            final left = Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTeacherApprovalSection(admin),
                                const SizedBox(height: EduBridgeTheme.spacingLG),
                                _buildNotificationsSection(admin),
                              ],
                            );
                            final right = Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLessonModerationSection(context, admin),
                                const SizedBox(height: EduBridgeTheme.spacingLG),
                                _buildActivitySection(admin),
                              ],
                            );
                            if (!wide) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [left, const SizedBox(height: 16), right],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 16),
                                Expanded(child: right),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStats(AdminProvider admin) {
    final data = admin.dashboardOverview;
    if (admin.isLoadingDashboardOverview && data == null) {
      return GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          6,
          (_) => LoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (admin.dashboardOverviewError != null && data == null) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error loading dashboard',
        message: admin.dashboardOverviewError!,
        onRetry: admin.loadDashboardOverview,
      );
    }

    final tiles = [
      AdminStatCard(
        icon: Icons.people_alt_rounded,
        label: 'Total Users',
        value: '${data?['totalUsers'] ?? 0}',
        color: EduBridgeColors.primary,
      ),
      AdminStatCard(
        icon: Icons.pending_actions_rounded,
        label: 'Pending Teachers',
        value: '${data?['pendingTeachers'] ?? 0}',
        color: EduBridgeColors.warning,
      ),
      AdminStatCard(
        icon: Icons.menu_book_rounded,
        label: 'Total Lessons',
        value: '${data?['totalLessons'] ?? 0}',
        color: EduBridgeColors.secondary,
      ),
      AdminStatCard(
        icon: Icons.flag_outlined,
        label: 'Flagged Lessons',
        value: '${data?['flaggedLessons'] ?? 0}',
        color: const Color(0xFFF59E0B),
      ),
      AdminStatCard(
        icon: Icons.visibility_off_outlined,
        label: 'Hidden Lessons',
        value: '${data?['hiddenLessons'] ?? 0}',
        color: EduBridgeColors.error,
      ),
      AdminStatCard(
        icon: Icons.notifications_active_outlined,
        label: 'Unread Notifications',
        value: '${data?['unreadNotifications'] ?? 0}',
        color: EduBridgeColors.accent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100 ? 3 : width >= 700 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width >= 700 ? 1.8 : 2.1,
          ),
          itemBuilder: (_, index) => tiles[index],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _actionTile(
        icon: Icons.verified_user_outlined,
        title: 'Teacher Requests',
        subtitle: 'Approve teachers and review CVs',
        color: EduBridgeColors.warning,
        onTap: () => Navigator.push(
          context,
          PageTransitions.fadeSlideRoute(const AdminTeacherRequestsScreen()),
        ),
      ),
      _actionTile(
        icon: Icons.play_lesson_outlined,
        title: 'Lesson Monitoring',
        subtitle: 'Moderate flagged, hidden, and approved content',
        color: EduBridgeColors.secondary,
        onTap: () => Navigator.push(
          context,
          PageTransitions.fadeSlideRoute(const AdminLessonMonitoringScreen()),
        ),
      ),
      _actionTile(
        icon: Icons.people_outline_rounded,
        title: 'User Management',
        subtitle: 'Inspect users and roles',
        color: EduBridgeColors.primary,
        onTap: () => Navigator.push(
          context,
          PageTransitions.fadeSlideRoute(const AdminUsersScreen()),
        ),
      ),
      _actionTile(
        icon: Icons.subject_rounded,
        title: 'Subjects',
        subtitle: 'Manage school catalog and lessons structure',
        color: EduBridgeColors.accent,
        onTap: () => Navigator.push(
          context,
          PageTransitions.fadeSlideRoute(const AdminSubjectsScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemBuilder: (_, index) => actions[index],
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: EduBridgeTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: EduBridgeTypography.titleMedium.copyWith(
                    color: EduBridgeColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: EduBridgeTypography.bodySmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Widget _buildTeacherApprovalSection(AdminProvider admin) {
    return AdminDashboardSection(
      title: 'Teacher registration approval',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlideRoute(const AdminTeacherRequestsScreen()),
          );
        },
        child: const Text('Open queue'),
      ),
      child: Column(
        children: [
          TextField(
            controller: _teacherSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search teacher by name or email',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  _teacherSearchCtrl.clear();
                  admin.setTeacherSearchQuery('');
                  admin.loadTeachers();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            onSubmitted: (value) {
              admin.setTeacherSearchQuery(value.trim());
              admin.loadTeachers();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: admin.teacherStatusFilter,
            decoration: const InputDecoration(labelText: 'Teacher status'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
              DropdownMenuItem<String?>(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem<String?>(value: 'ACCEPTED', child: Text('Accepted')),
              DropdownMenuItem<String?>(value: 'REJECTED', child: Text('Rejected')),
            ],
            onChanged: (value) {
              admin.setTeacherStatusFilter(value);
              admin.loadTeachers();
            },
          ),
          const SizedBox(height: 14),
          if (admin.isLoadingTeachers)
            const Center(child: CircularProgressIndicator())
          else if (admin.teachersError != null)
            ErrorState(
              icon: Icons.error_outline,
              title: 'Error loading teachers',
              message: admin.teachersError!,
              onRetry: admin.loadTeachers,
            )
          else if (admin.teachers.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No teachers match the current filters.')),
            )
          else
            ...admin.teachers.take(6).map((teacher) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AdminTeacherRequestDetailScreen(teacherId: teacher.id),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            EduBridgeColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.school_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.fullName,
                              style: EduBridgeTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: EduBridgeColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              teacher.email,
                              style: EduBridgeTypography.bodySmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TeacherApprovalBadge(status: teacher.approvalStatus),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLessonModerationSection(
    BuildContext context,
    AdminProvider admin,
  ) {
    return AdminDashboardSection(
      title: 'Lesson monitoring / moderation',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlideRoute(const AdminLessonMonitoringScreen()),
          );
        },
        child: const Text('Open monitor'),
      ),
      child: Column(
        children: [
          TextField(
            controller: _lessonSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search lesson title / description',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  _lessonSearchCtrl.clear();
                  admin.setLessonSearchQuery('');
                  admin.loadAdminLessons();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            onSubmitted: (value) {
              admin.setLessonSearchQuery(value.trim());
              admin.loadAdminLessons();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: admin.lessonStatusFilter,
            decoration: const InputDecoration(labelText: 'Lesson status'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
              DropdownMenuItem<String?>(value: 'APPROVED', child: Text('Approved')),
              DropdownMenuItem<String?>(value: 'FLAGGED', child: Text('Flagged')),
              DropdownMenuItem<String?>(value: 'HIDDEN', child: Text('Hidden')),
            ],
            onChanged: (value) {
              admin.setLessonStatusFilter(value);
              admin.loadAdminLessons();
            },
          ),
          const SizedBox(height: 14),
          if (admin.isLoadingAdminLessons)
            const Center(child: CircularProgressIndicator())
          else if (admin.adminLessonsError != null)
            ErrorState(
              icon: Icons.error_outline,
              title: 'Error loading lessons',
              message: admin.adminLessonsError!,
              onRetry: admin.loadAdminLessons,
            )
          else if (admin.adminLessons.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No lessons match the current filters.')),
            )
          else
            ...admin.adminLessons.take(6).map((lesson) {
              final status =
                  lesson['moderationStatus']?.toString() ?? 'APPROVED';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransitions.fadeSlideRoute(
                        const AdminLessonMonitoringScreen(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson['title']?.toString() ?? 'Lesson',
                              style: EduBridgeTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: EduBridgeColors.textPrimary,
                              ),
                            ),
                          ),
                          _buildLessonStatus(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metaChip(lesson['teacherName']?.toString() ?? 'Teacher'),
                          _metaChip(lesson['subjectName']?.toString() ?? 'Subject'),
                          if ((lesson['level']?.toString() ?? '').isNotEmpty)
                            _metaChip(lesson['level'].toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(AdminProvider admin) {
    final overview = admin.notificationsOverview;
    final items = (overview?['items'] as List?) ?? const [];
    return AdminDashboardSection(
      title: 'Notifications overview',
      child: admin.isLoadingNotificationsOverview && overview == null
          ? const Center(child: CircularProgressIndicator())
          : admin.notificationsOverviewError != null && overview == null
              ? ErrorState(
                  icon: Icons.error_outline,
                  title: 'Error loading notifications',
                  message: admin.notificationsOverviewError!,
                  onRetry: admin.loadNotificationsOverview,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unread notifications: ${overview?['unreadCount'] ?? 0}',
                      style: EduBridgeTypography.bodyMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.take(5).map((item) {
                      final notification = Map<String, dynamic>.from(item as Map);
                      final unread =
                          notification['status']?.toString() == 'UNREAD';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: unread
                                      ? EduBridgeColors.primary
                                      : EduBridgeColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title']?.toString() ?? '',
                                      style: EduBridgeTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: EduBridgeColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message']?.toString() ?? '',
                                      style: EduBridgeTypography.bodySmall.copyWith(
                                        color: EduBridgeColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildActivitySection(AdminProvider admin) {
    final overview = admin.dashboardOverview;
    final recentTeachers = (overview?['recentTeachers'] as List?) ?? const [];
    final recentLessons = (overview?['recentLessons'] as List?) ?? const [];

    return AdminDashboardSection(
      title: 'Platform activity overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent teacher registrations',
            style: EduBridgeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: EduBridgeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (recentTeachers.isEmpty)
            Text(
              'No teacher activity yet.',
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            )
          else
            ...recentTeachers.take(4).map((item) {
              final teacher = Map<String, dynamic>.from(item as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'.trim(),
                        style: EduBridgeTypography.bodyMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TeacherApprovalBadge(
                      status: teacher['approvalStatus']?.toString(),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          Text(
            'Recent lessons',
            style: EduBridgeTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: EduBridgeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (recentLessons.isEmpty)
            Text(
              'No lesson activity yet.',
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            )
          else
            ...recentLessons.take(5).map((item) {
              final lesson = Map<String, dynamic>.from(item as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['title']?.toString() ?? 'Lesson',
                              style: EduBridgeTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: EduBridgeColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lesson['teacherName'] ?? 'Teacher'} • ${lesson['subjectName'] ?? 'Subject'}',
                              style: EduBridgeTypography.bodySmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildLessonStatus(
                        lesson['moderationStatus']?.toString() ?? 'APPROVED',
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EduBridgeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: EduBridgeTypography.labelSmall.copyWith(
          color: EduBridgeColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLessonStatus(String status) {
    switch (status) {
      case 'FLAGGED':
        return const AdminStatusChip(
          label: 'Flagged',
          backgroundColor: Color(0xFFFEF3C7),
          foregroundColor: Color(0xFF92400E),
        );
      case 'HIDDEN':
        return const AdminStatusChip(
          label: 'Hidden',
          backgroundColor: Color(0xFFFEE2E2),
          foregroundColor: Color(0xFF991B1B),
        );
      default:
        return const AdminStatusChip(
          label: 'Approved',
          backgroundColor: Color(0xFFDCFCE7),
          foregroundColor: Color(0xFF166534),
        );
    }
  }
}

