import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/teacher_approval_badge.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../ui/dashboard/dashboard_header.dart';
import '../ui/dashboard/dashboard_kpi_card.dart';
import '../ui/dashboard/dashboard_motion.dart';
import '../ui/dashboard/dashboard_premium_states.dart';
import '../ui/dashboard/dashboard_responsive.dart';
import '../ui/dashboard/dashboard_scaffold.dart';
import '../ui/dashboard/dashboard_states.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/theme/edubridge_typography.dart';
import '../utils/app_router.dart';
import 'admin_lesson_monitoring_screen.dart';
import 'admin_teacher_request_detail_screen.dart';
import 'admin_teacher_requests_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _teacherSearchCtrl = TextEditingController();
  final TextEditingController _lessonSearchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _teacherSearchCtrl.dispose();
    _lessonSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final admin = Provider.of<AdminProvider>(context, listen: false);
    try {
      await Future.wait([
        admin.loadDashboardOverview(),
        admin.loadPendingTeachers(),
        admin.loadTeachers(),
        admin.loadAdminLessons(),
        admin.loadNotificationsOverview(),
      ]);
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final user = auth.user;

    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppRouter.getHomePage(context)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = admin.pendingTeachers.length;
    final overview = admin.dashboardOverview ?? const <String, dynamic>{};
    final notifications = admin.notificationsOverview ?? const <String, dynamic>{};

    return DashboardScaffold(
      navItems: const [
        DashboardNavItem(label: 'Overview', icon: Icons.dashboard_rounded),
        DashboardNavItem(label: 'Approvals', icon: Icons.verified_user_rounded),
        DashboardNavItem(label: 'Moderation', icon: Icons.gavel_rounded),
        DashboardNavItem(label: 'Users', icon: Icons.manage_accounts_rounded),
      ],
      currentNavIndex: 0,
      header: DashboardHeader(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
          child: const Icon(Icons.admin_panel_settings_rounded, color: EduBridgeColors.primary),
        ),
        title: 'Admin Dashboard',
        subtitle:
            'Premium control center for approvals, moderation, and platform governance.',
        badge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD97706).withOpacity(0.24)),
          ),
          child: Text(
            '$pending pending approvals',
            style: EduBridgeTypography.labelMedium.copyWith(
              color: const Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing: _profileMenu(auth),
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          children: [
            if (_error != null) _errorCard(_error!),
            DashboardEntrance(delayMs: 30, child: _buildTopHero(overview)),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(
              delayMs: 90,
              child: _buildOverviewCards(overview, pending, notifications),
            ),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(delayMs: 120, child: _buildQuickActions()),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(
              delayMs: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPendingApprovals(admin),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildTeacherManagement(admin),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildNotificationsPreview(admin),
                  ],
                );
                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLessonModeration(admin),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildActivityFeed(admin),
                  ],
                );
                if (!wide) {
                  return Column(children: [left, const SizedBox(height: 12), right]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: left),
                    const SizedBox(width: EduBridgeTheme.spacingMD),
                    Expanded(flex: 12, child: right),
                  ],
                );
                },
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: EduBridgeTheme.spacingMD),
                child: DashboardLoadingBlock(height: 100),
              ),
            const SizedBox(height: EduBridgeTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHero(Map<String, dynamic> overview) {
    final users = overview['totalUsers'] ?? 0;
    final lessons = overview['totalLessons'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strong platform visibility',
                  style: EduBridgeTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$users users • $lessons lessons monitored',
                  style: EduBridgeTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(
    Map<String, dynamic> overview,
    int pending,
    Map<String, dynamic> notifications,
  ) {
    final cards = [
      DashboardKpiCard(
        icon: Icons.people_alt_rounded,
        label: 'Total users',
        value: '${overview['totalUsers'] ?? 0}',
        color: const Color(0xFF4F46E5),
      ),
      DashboardKpiCard(
        icon: Icons.pending_actions_rounded,
        label: 'Pending teachers',
        value: '$pending',
        color: const Color(0xFFD97706),
        badgeCount: pending,
      ),
      DashboardKpiCard(
        icon: Icons.menu_book_rounded,
        label: 'Total lessons',
        value: '${overview['totalLessons'] ?? 0}',
        color: const Color(0xFF0891B2),
      ),
      DashboardKpiCard(
        icon: Icons.flag_rounded,
        label: 'Flagged lessons',
        value: '${overview['flaggedLessons'] ?? 0}',
        color: const Color(0xFFDC2626),
      ),
      DashboardKpiCard(
        icon: Icons.visibility_off_rounded,
        label: 'Hidden lessons',
        value: '${overview['hiddenLessons'] ?? 0}',
        color: const Color(0xFFB91C1C),
      ),
      DashboardKpiCard(
        icon: Icons.notifications_active_rounded,
        label: 'Unread notifications',
        value: '${notifications['unreadCount'] ?? 0}',
        color: const Color(0xFF7C3AED),
        badgeCount: (notifications['unreadCount'] as num?)?.toInt() ?? 0,
      ),
    ];
    return AdaptiveDashboardGrid(
      maxColumns: 3,
      children: cards,
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: EduBridgeTheme.spacingMD,
      runSpacing: EduBridgeTheme.spacingMD,
      children: [
        _actionTile(
          icon: Icons.verified_user_outlined,
          title: 'Teacher approvals',
          subtitle: 'Pending requests & CV review',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AdminTeacherRequestsScreen()),
          ),
        ),
        _actionTile(
          icon: Icons.play_lesson_outlined,
          title: 'Lesson moderation',
          subtitle: 'Monitor and moderate lesson quality',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AdminLessonMonitoringScreen()),
          ),
        ),
        _actionTile(
          icon: Icons.manage_accounts_rounded,
          title: 'User management',
          subtitle: 'Global user controls and filters',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AdminUsersScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovals(AdminProvider admin) {
    return _section(
      title: 'Pending teacher approvals',
      action: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AdminTeacherRequestsScreen()),
        ),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open queue'),
      ),
      child: admin.pendingTeachers.isEmpty
          ? const DashboardPremiumStateCard(
              icon: Icons.verified_rounded,
              title: 'No pending approvals',
              message: 'Great work. Teacher approval queue is fully up to date.',
              variant: DashboardStateVariant.success,
            )
          : Column(
              children: admin.pendingTeachers.take(5).map((t) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                  title: Text(t.fullName),
                  subtitle: Text(t.email),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AdminTeacherRequestDetailScreen(teacherId: t.id),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTeacherManagement(AdminProvider admin) {
    return _section(
      title: 'Teacher status management',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _teacherSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search teacher by name/email',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _teacherSearchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _teacherSearchCtrl.clear();
                              admin.setTeacherSearchQuery('');
                              admin.loadTeachers();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (v) {
                    admin.setTeacherSearchQuery(v);
                    setState(() {});
                  },
                  onSubmitted: (_) => admin.loadTeachers(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String?>(
                  value: admin.teacherStatusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem<String?>(value: 'ACCEPTED', child: Text('Accepted')),
                    DropdownMenuItem<String?>(value: 'REJECTED', child: Text('Rejected')),
                  ],
                  onChanged: (v) {
                    admin.setTeacherStatusFilter(v);
                    admin.loadTeachers();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardAnimatedSwitcher(
            child: admin.teachers.isEmpty
                ? const DashboardPremiumStateCard(
                    icon: Icons.groups_rounded,
                    title: 'No matching teachers',
                    message: 'No teacher matches current filters. Try broadening search criteria.',
                  )
                : Column(
                    children: admin.teachers.take(6).map((teacher) {
                      return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EduBridgeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person_rounded, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacher.fullName, style: EduBridgeTypography.titleSmall),
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
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonModeration(AdminProvider admin) {
    return _section(
      title: 'Lesson monitoring / moderation',
      action: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AdminLessonMonitoringScreen()),
        ),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open moderation'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lessonSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search lesson title/description',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _lessonSearchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _lessonSearchCtrl.clear();
                              admin.setLessonSearchQuery('');
                              admin.loadAdminLessons();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (v) {
                    admin.setLessonSearchQuery(v);
                    setState(() {});
                  },
                  onSubmitted: (_) => admin.loadAdminLessons(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String?>(
                  value: admin.lessonStatusFilter,
                  decoration: const InputDecoration(labelText: 'Lesson status'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(value: 'APPROVED', child: Text('Approved')),
                    DropdownMenuItem<String?>(value: 'FLAGGED', child: Text('Flagged')),
                    DropdownMenuItem<String?>(value: 'HIDDEN', child: Text('Hidden')),
                  ],
                  onChanged: (v) {
                    admin.setLessonStatusFilter(v);
                    admin.loadAdminLessons();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardAnimatedSwitcher(
            child: admin.adminLessons.isEmpty
                ? const DashboardPremiumStateCard(
                    icon: Icons.auto_stories_rounded,
                    title: 'No matching lessons',
                    message: 'No lesson matches current moderation filters. Adjust filters to continue.',
                  )
                : Column(
                    children: admin.adminLessons.take(6).map((lesson) {
                      final status = lesson['moderationStatus']?.toString() ?? 'APPROVED';
                      return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                    border: Border.all(color: EduBridgeColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson['title']?.toString() ?? 'Lesson',
                              style: EduBridgeTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _statusBadge(status),
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
                            _metaChip(lesson['level']!.toString()),
                        ],
                      ),
                    ],
                  ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPreview(AdminProvider admin) {
    final overview = admin.notificationsOverview;
    final items = (overview?['latest'] as List?) ?? const [];
    return _section(
      title: 'Notifications preview',
      child: items.isEmpty
          ? const DashboardNoNotificationsState()
          : Column(
              children: items.take(5).map((item) {
                final n = Map<String, dynamic>.from(item as Map);
                final unread = n['status']?.toString() == 'UNREAD';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    unread ? Icons.mark_email_unread_rounded : Icons.mark_email_read_rounded,
                  ),
                  title: Text(n['title']?.toString() ?? 'Notification'),
                  subtitle: Text(
                    n['message']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActivityFeed(AdminProvider admin) {
    final overview = admin.dashboardOverview;
    final recentTeachers =
        (overview?['recentTeacherRegistrations'] as List?) ?? const [];
    final recentLessons = (overview?['recentLessons'] as List?) ?? const [];
    return _section(
      title: 'Activity feed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent teacher registrations',
            style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (recentTeachers.isEmpty)
            Text(
              'No teacher activity yet.',
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            )
          else
            ...recentTeachers.take(4).map((item) {
              final t = Map<String, dynamic>.from(item as Map);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add_alt_rounded),
                title: Text(
                  '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim(),
                ),
                trailing: TeacherApprovalBadge(status: t['approvalStatus']?.toString()),
              );
            }),
          const SizedBox(height: 14),
          Text(
            'Recent lessons',
            style: EduBridgeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (recentLessons.isEmpty)
            Text(
              'No lesson activity yet.',
              style: EduBridgeTypography.bodySmall.copyWith(
                color: EduBridgeColors.textSecondary,
              ),
            )
          else
            ...recentLessons.take(4).map((item) {
              final lesson = Map<String, dynamic>.from(item as Map);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_rounded),
                title: Text(lesson['title']?.toString() ?? 'Lesson'),
                subtitle: Text(
                  '${lesson['teacherName'] ?? 'Teacher'} • ${lesson['subjectName'] ?? 'Subject'}',
                ),
                trailing: _statusBadge(
                  lesson['moderationStatus']?.toString() ?? 'APPROVED',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        border: Border.all(color: EduBridgeColors.border),
        boxShadow: EduBridgeColors.cardShadowLayered,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EduBridgeTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 320,
      child: DashboardPressable(
        onTap: onTap,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
          child: InkWell(
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
            onTap: onTap,
            child: Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
            decoration: BoxDecoration(
              border: Border.all(color: EduBridgeColors.border),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
              boxShadow: EduBridgeColors.cardShadowLayered,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
                  child: Icon(icon, color: EduBridgeColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: EduBridgeTypography.titleSmall),
                      const SizedBox(height: 3),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    final isFlagged = s == 'FLAGGED';
    final isHidden = s == 'HIDDEN';
    final bg = isFlagged
        ? const Color(0xFFFEF3C7)
        : isHidden
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDCFCE7);
    final fg = isFlagged
        ? const Color(0xFF92400E)
        : isHidden
            ? const Color(0xFF991B1B)
            : const Color(0xFF166534);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        s,
        style: EduBridgeTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EduBridgeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: EduBridgeTypography.labelSmall),
    );
  }

  Widget _profileMenu(AuthProvider auth) {
    final initials = (auth.user?.firstName.isNotEmpty ?? false)
        ? auth.user!.firstName[0].toUpperCase()
        : 'A';
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          auth.logout();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AppRouter.getHomePage(context)),
            (_) => false,
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Text('Se deconnecter'),
        ),
      ],
      child: CircleAvatar(
        backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
        child: Text(
          initials,
          style: const TextStyle(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          message,
          style: EduBridgeTypography.bodyMedium.copyWith(color: const Color(0xFF991B1B)),
        ),
      ),
    );
  }
}
