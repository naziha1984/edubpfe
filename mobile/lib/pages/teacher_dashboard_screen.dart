import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/teacher_approval_badge.dart';
import '../components/teacher_dashboard/teacher_cv_card.dart';
import '../models/assignment_model.dart';
import '../models/class_model.dart';
import '../models/conversation_model.dart';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import '../providers/assignments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/subjects_provider.dart';
import '../providers/teacher_provider.dart';
import '../services/api_service.dart';
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
import 'assignment_submissions_screen.dart';
import 'chat_detail_screen.dart';
import 'inbox_screen.dart';
import 'notifications_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_lesson_ratings_screen.dart';
import 'teacher_students_hub_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _loading = true;
  String? _error;

  List<LessonModel> _recentLessons = [];
  List<Map<String, dynamic>> _ratingsSummary = [];
  List<AssignmentModel> _assignmentsPreview = [];
  List<AssignmentSubmissionModel> _submissionPreview = [];
  ClassModel? _selectedClass;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    final notificationsProvider =
        Provider.of<NotificationsProvider>(context, listen: false);
    final subjectsProvider = Provider.of<SubjectsProvider>(context, listen: false);
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      await Future.wait([
        teacherProvider.loadStats(),
        messagesProvider.loadConversations(),
        notificationsProvider.load(),
        subjectsProvider.loadSubjects(),
      ]);
    } catch (e) {
      _error = e.toString();
    }

    if (!mounted) return;
    final classes = teacherProvider.classes;
    if (classes.isNotEmpty) _selectedClass = classes.first;
    final subjects = subjectsProvider.subjects;
    if (subjects.isNotEmpty) _selectedSubjectId = subjects.first.id;

    if (_selectedClass != null && _selectedSubjectId != null) {
      try {
        await teacherProvider.loadClassSubjectProgress(
          _selectedClass!.id,
          _selectedSubjectId!,
        );
      } catch (_) {}
    }

    try {
      if (_selectedSubjectId != null) {
        final lessons = await api.getLessons(_selectedSubjectId!);
        final mapped = lessons
            .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((l) => l.isActive)
            .toList();
        mapped.sort((a, b) {
          final da = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        _recentLessons = mapped.take(6).toList();
      }
    } catch (e) {
      _error ??= e.toString();
    }

    try {
      final data = await api.getTeacherLessonRatingsSummary();
      _ratingsSummary = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _error ??= e.toString();
    }

    try {
      if (_selectedClass != null) {
        await assignmentsProvider.loadAssignmentsByClass(_selectedClass!.id);
        final assignments = List<AssignmentModel>.from(assignmentsProvider.assignments);
        assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        _assignmentsPreview = assignments.take(3).toList();

        final now = DateTime.now();
        final picked = assignments.firstWhere(
          (a) => a.dueDate.isAfter(now),
          orElse: () => assignments.isNotEmpty
              ? assignments.first
              : AssignmentModel(
                  id: '',
                  classId: '',
                  teacherId: '',
                  title: '',
                  dueDate: now,
                ),
        );
        if (picked.id.isNotEmpty) {
          await assignmentsProvider.loadAssignmentSubmissions(picked.id);
          final subs = List<AssignmentSubmissionModel>.from(assignmentsProvider.submissions);
          subs.sort((a, b) {
            final da = a.submittedAt ?? a.updatedAt ?? a.createdAt ?? DateTime(1970);
            final db = b.submittedAt ?? b.updatedAt ?? b.createdAt ?? DateTime(1970);
            return db.compareTo(da);
          });
          _submissionPreview = subs.take(5).toList();
        }
      }
    } catch (e) {
      _error ??= e.toString();
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final messagesProvider = Provider.of<MessagesProvider>(context);
    final notificationsProvider = Provider.of<NotificationsProvider>(context);
    final user = auth.user;

    if (!auth.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppRouter.getHomePage(context)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DashboardScaffold(
      navItems: const [
        DashboardNavItem(label: 'Overview', icon: Icons.dashboard_rounded),
        DashboardNavItem(label: 'Classes', icon: Icons.class_rounded),
        DashboardNavItem(label: 'Students', icon: Icons.groups_2_rounded),
        DashboardNavItem(label: 'Messages', icon: Icons.forum_rounded),
      ],
      currentNavIndex: 0,
      header: DashboardHeader(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
          child: const Icon(Icons.school_rounded, color: EduBridgeColors.primary),
        ),
        title: 'Teacher Dashboard',
        subtitle:
            'Professional, modern and efficient cockpit for your classes and students.',
        badge: TeacherApprovalBadge(status: user?.approvalStatus),
        trailing: _profileMenu(auth),
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          children: [
            if (_error != null)
              _infoCard(_error!),
            DashboardEntrance(delayMs: 30, child: _buildHero(user)),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(
              delayMs: 90,
              child: _buildKpis(teacherProvider, messagesProvider, notificationsProvider),
            ),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(
              delayMs: 140,
              child: LayoutBuilder(
                builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileSummary(user, teacherProvider),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildCvCard(user),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildClassYearOverview(teacherProvider),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildProgressShortcut(teacherProvider),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildGamificationInsights(teacherProvider),
                  ],
                );
                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLessonsOverview(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildSubmissionsPreview(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildRatingsReviews(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildMessagesPreview(messagesProvider),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildNotificationsPreview(notificationsProvider),
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

  Widget _buildHero(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusXL),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331D4ED8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.workspace_premium_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${user?.firstName ?? 'Teacher'} 👋',
                  style: EduBridgeTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Strong overview, compact analytics, and clean activity flow.',
                  style: EduBridgeTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpis(
    TeacherProvider teacherProvider,
    MessagesProvider messagesProvider,
    NotificationsProvider notificationsProvider,
  ) {
    return AdaptiveDashboardGrid(
      maxColumns: 4,
      children: [
        DashboardKpiCard(
          icon: Icons.class_rounded,
          label: 'Classes',
          value: '${teacherProvider.totalClasses}',
          color: const Color(0xFF4F46E5),
        ),
        DashboardKpiCard(
          icon: Icons.groups_2_rounded,
          label: 'Students',
          value: '${teacherProvider.totalStudents}',
          color: const Color(0xFF0891B2),
        ),
        DashboardKpiCard(
          icon: Icons.mark_email_unread_rounded,
          label: 'Unread messages',
          value: '${messagesProvider.totalUnread}',
          color: const Color(0xFF16A34A),
          badgeCount: messagesProvider.totalUnread,
        ),
        DashboardKpiCard(
          icon: Icons.notifications_active_rounded,
          label: 'Unread notifications',
          value: '${notificationsProvider.unreadCount}',
          color: const Color(0xFFF59E0B),
          badgeCount: notificationsProvider.unreadCount,
        ),
      ],
    );
  }

  Widget _buildProfileSummary(UserModel? user, TeacherProvider provider) {
    return DashboardSectionCard(
      title: 'Profile summary',
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
            child: Text(
              (user?.firstName.isNotEmpty ?? false)
                  ? user!.firstName[0].toUpperCase()
                  : 'T',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: EduBridgeColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'Teacher', style: EduBridgeTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: EduBridgeTypography.bodySmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TeacherApprovalBadge(status: user?.approvalStatus),
              const SizedBox(height: 8),
              Text(
                '${provider.totalClasses} classes',
                style: EduBridgeTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCvCard(UserModel? user) {
    return DashboardSectionCard(
      title: 'CV upload/status card',
      child: TeacherCvCard(
        cvUrl: user?.cvUrl,
        approvalStatus: user?.approvalStatus,
        submittedAt: user?.submittedAt,
      ),
    );
  }

  Widget _buildClassYearOverview(TeacherProvider provider) {
    final classes = provider.classes;
    return DashboardSectionCard(
      title: 'Class/year overview',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TeacherClassesScreen()),
          );
        },
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Manage'),
      ),
      child: classes.isEmpty
          ? const DashboardPremiumStateCard(
              icon: Icons.class_outlined,
              title: 'No classes yet',
              message: 'Create your first class to start structured teaching workflows.',
            )
          : Column(
              children: classes.take(4).map((c) {
                final count = c.members?.length ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.school_rounded)),
                  title: Text(c.name),
                  subtitle: Text('Code: ${c.classCode}'),
                  trailing: Text('$count students'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildProgressShortcut(TeacherProvider provider) {
    final top = provider.sortedStudents.take(3).toList();
    return DashboardSectionCard(
      title: 'Notes/progress management shortcut',
      action: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TeacherStudentsHubScreen()),
          );
        },
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Open hub'),
      ),
      child: top.isEmpty
          ? const DashboardPremiumStateCard(
              icon: Icons.timeline_rounded,
              title: 'No progress data',
              message: 'Progress insights will appear once students start submitting work.',
            )
          : Column(
              children: top.map((s) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(s.kidName),
                  subtitle: Text('Avg score: ${s.avgScore.toStringAsFixed(1)}'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildGamificationInsights(TeacherProvider provider) {
    final students = provider.classProgress?.students ?? [];
    final active = students.where((s) => s.avgScore >= 60).length;
    final risk = students.where((s) => s.avgScore < 40).length;
    return DashboardSectionCard(
      title: 'Student engagement insights',
      child: Row(
        children: [
          Expanded(child: _metricTile('Active', '$active', Icons.local_fire_department_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _metricTile('Needs support', '$risk', Icons.flag_rounded)),
          const SizedBox(width: 10),
          Expanded(
            child: _metricTile(
              'Avg progress',
              '${provider.classProgress?.overallStats.overallCompletionRate.toStringAsFixed(0) ?? '0'}%',
              Icons.insights_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsOverview() {
    return DashboardSectionCard(
      title: 'Lessons overview',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TeacherClassesScreen()),
          );
        },
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Open lessons'),
      ),
      child: _recentLessons.isEmpty
          ? const DashboardNoLessonsState()
          : Column(
              children: _recentLessons.take(5).map((l) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 18,
                    child: Icon(Icons.play_lesson_rounded, size: 18),
                  ),
                  title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${l.language ?? 'FR'} • ${l.level ?? 'General'}'),
                  trailing: Text(
                    _formatDate(l.updatedAt?.toIso8601String() ?? l.createdAt?.toIso8601String()),
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSubmissionsPreview() {
    return DashboardSectionCard(
      title: 'Student homework submissions preview',
      action: TextButton.icon(
        onPressed: _assignmentsPreview.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AssignmentSubmissionsScreen(
                      assignmentId: _assignmentsPreview.first.id,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.assignment_turned_in_rounded),
        label: const Text('View all'),
      ),
      child: _submissionPreview.isEmpty
          ? const DashboardPremiumStateCard(
              icon: Icons.inbox_outlined,
              title: 'No submissions yet',
              message: 'Student homework submissions will appear after assignment activity.',
            )
          : Column(
              children: _submissionPreview.take(5).map((s) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 16),
                  ),
                  title: Text(s.kidName),
                  subtitle: Text(s.status.displayName),
                  trailing: Text(
                    s.score == null ? '-' : '${s.score!.toStringAsFixed(0)}%',
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRatingsReviews() {
    return DashboardSectionCard(
      title: 'Parent ratings and reviews',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TeacherLessonRatingsScreen()),
          );
        },
        icon: const Icon(Icons.reviews_rounded),
        label: const Text('Details'),
      ),
      child: _ratingsSummary.isEmpty
          ? const DashboardNoReviewsState()
          : Column(
              children: _ratingsSummary.take(5).map((r) {
                final stars = ((r['averageStars'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
                final count = (r['reviewCount'] as num?)?.toInt() ?? 0;
                final title = r['lessonTitle']?.toString() ?? 'Lesson';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$count reviews'),
                  trailing: Text(stars),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMessagesPreview(MessagesProvider provider) {
    final teacherConversations = provider.conversations;
    return DashboardSectionCard(
      title: 'Unread direct messages',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const InboxScreen()),
          );
        },
        icon: const Icon(Icons.forum_rounded),
        label: const Text('Inbox'),
      ),
      child: teacherConversations.isEmpty
          ? const DashboardNoMessagesState()
          : Column(
              children: teacherConversations.take(4).map((c) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Stack(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                      if (c.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${c.unreadCount}',
                              style: const TextStyle(fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(c.otherUserName.isEmpty ? 'Conversation' : c.otherUserName),
                  subtitle: Text(
                    c.lastMessage.isEmpty ? 'No message' : c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openConversation(c),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotificationsPreview(NotificationsProvider provider) {
    return DashboardSectionCard(
      title: 'Notifications preview',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
          );
        },
        icon: const Icon(Icons.notifications_rounded),
        label: const Text('Open'),
      ),
      child: provider.items.isEmpty
          ? const DashboardNoNotificationsState()
          : Column(
              children: provider.items.take(4).map((n) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    (n['isRead'] == true)
                        ? Icons.mark_email_read_rounded
                        : Icons.mark_email_unread_rounded,
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

  Widget _metricTile(String label, String value, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
        border: Border.all(color: EduBridgeColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: EduBridgeColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: EduBridgeTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: EduBridgeTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileMenu(AuthProvider auth) {
    final initial = (auth.user?.firstName.isNotEmpty ?? false)
        ? auth.user!.firstName[0].toUpperCase()
        : 'T';
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
          child: Row(
            children: [
              Icon(Icons.logout_rounded),
              SizedBox(width: 8),
              Text('Se deconnecter'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
        child: Text(
          initial,
          style: const TextStyle(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String message) {
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

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('dd/MM').format(dt.toLocal());
  }

  void _openConversation(ConversationModel c) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(
          conversationId: c.id,
          receiverId: c.otherUserId,
          title: c.otherUserName,
        ),
      ),
    );
  }
}
