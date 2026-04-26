import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/gradient_page_shell.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/subjects_provider.dart';
import '../providers/assignments_provider.dart';
import '../services/api_service.dart';
import '../utils/app_router.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/unread_badge.dart';
import '../components/empty_state.dart';
import '../components/teacher_approval_badge.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import '../models/student_progress_model.dart';
import '../components/teacher_dashboard/dashboard_section.dart';
import '../components/teacher_dashboard/teacher_cv_card.dart';
import 'teacher_classes_screen.dart';
import 'teacher_students_hub_screen.dart';
import 'teacher_courses_screen.dart';
import 'assignment_submissions_screen.dart';
import 'notifications_screen.dart';
import 'inbox_screen.dart';
import 'chat_detail_screen.dart';
import '../ui/transitions/page_transitions.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_lesson_ratings_screen.dart';


/// Écran d'accueil Teacher moderne avec KPIs
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  bool _bootstrapping = true;
  String? _bootError;

  // Aperçu des leçons
  List<LessonModel> _recentLessons = [];
  bool _loadingLessons = true;

  // Avis et notes des parents (sur les leçons de l'enseignant)
  List<Map<String, dynamic>> _ratingsSummary = [];
  bool _loadingRatings = true;

  // Aperçu des devoirs et remises (pour une classe sélectionnée)
  List<AssignmentModel> _assignmentsPreview = [];
  List<AssignmentSubmissionModel> _submissionPreview = [];
  bool _loadingAssignments = true;
  bool _loadingSubmissions = true;

  ClassModel? _selectedClass;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _bootError = null;
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
      // Le dashboard garde une partie fonctionnelle.
      _bootError = e.toString();
    }

    if (!mounted) return;

    final classes = teacherProvider.classes;
    if (classes.isNotEmpty) _selectedClass = classes.first;

    final subjects = subjectsProvider.subjects;
    if (subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    // Charger un aperçu de progression (meilleurs élèves) si possible.
    if (_selectedClass != null && _selectedSubjectId != null) {
      try {
        await teacherProvider.loadClassSubjectProgress(
          _selectedClass!.id,
          _selectedSubjectId!,
        );
      } catch (_) {}
    }

    // Charger un aperçu des leçons.
    setState(() => _loadingLessons = true);
    if (_selectedSubjectId != null) {
      try {
        final lessonsJson = await api.getLessons(_selectedSubjectId!);
        final lessons = lessonsJson
            .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        lessons.sort((a, b) {
          final ua = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final ub = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ub.compareTo(ua);
        });
        _recentLessons = lessons.where((l) => l.isActive).take(6).toList();
      } catch (e) {
        _bootError ??= e.toString();
      }
    }
    setState(() => _loadingLessons = false);

    // Charger le résumé des notes.
    setState(() => _loadingRatings = true);
    try {
      final data = await api.getTeacherLessonRatingsSummary();
      _ratingsSummary = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _ratingsSummary.sort((a, b) {
        final ra = (a['averageStars'] as num?)?.toDouble() ?? 0;
        final rb = (b['averageStars'] as num?)?.toDouble() ?? 0;
        return rb.compareTo(ra);
      });
    } catch (e) {
      _bootError ??= e.toString();
    }
    setState(() => _loadingRatings = false);

    // Charger l'aperçu des devoirs et des remises.
    setState(() => _loadingAssignments = true);
    if (_selectedClass != null) {
      try {
        await assignmentsProvider.loadAssignmentsByClass(_selectedClass!.id);
        final assignments = List<AssignmentModel>.from(
          assignmentsProvider.assignments,
        );
        assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        _assignmentsPreview = assignments.take(3).toList();

        final now = DateTime.now();
        final upcoming =
            assignments.where((a) => a.dueDate.isAfter(now)).toList();
        final picked =
            (upcoming.isNotEmpty ? upcoming.first : assignments.isNotEmpty ? assignments.first : null);

        if (picked != null) {
          setState(() => _loadingSubmissions = true);
          await assignmentsProvider.loadAssignmentSubmissions(picked.id);
          final subs = List<AssignmentSubmissionModel>.from(
            assignmentsProvider.submissions,
          );
          subs.sort((a, b) {
            final ad = a.submittedAt ?? a.updatedAt ?? a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.submittedAt ?? b.updatedAt ?? b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          _submissionPreview = subs.take(4).toList();
          setState(() => _loadingSubmissions = false);
        }
      } catch (e) {
        _bootError ??= e.toString();
      }
    }

    if (!mounted) return;
    setState(() {
      _loadingAssignments = false;
      _loadingSubmissions = false;
      _bootstrapping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final messagesProvider = Provider.of<MessagesProvider>(context);
    final user = authProvider.user;
    final avatarInitials = user?.firstName.isNotEmpty == true
        ? user!.firstName[0].toUpperCase()
        : 'T';

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

    final notificationsProvider =
        Provider.of<NotificationsProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientPageShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;

              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSummarySection(user, teacherProvider),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  GlassCard(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                    child: TeacherCvCard(
                      cvUrl: user?.cvUrl,
                      approvalStatus: user?.approvalStatus,
                      submittedAt: user?.submittedAt,
                    ),
                  ),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildNotificationsSection(notificationsProvider),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildMessagesSection(messagesProvider),
                ],
              );

              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLessonOverviewSection(),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildStudentSubmissionsSection(),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildParentRatingsSection(),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildNotesProgressSection(teacherProvider),
                  const SizedBox(height: EduBridgeTheme.spacingMD),
                  _buildGamificationInsightsSection(teacherProvider),
                ],
              );

              return Column(
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
                                'Teacher Dashboard',
                                style: EduBridgeTypography.headlineMedium.copyWith(
                                  color: EduBridgeColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome back, ${user?.firstName ?? 'Teacher'}!',
                                style: EduBridgeTypography.bodyMedium.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TeacherApprovalBadge(status: user?.approvalStatus),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: UnreadBadge(
                            count: notificationsProvider.unreadCount,
                            child: const Icon(Icons.notifications_outlined),
                          ),
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
                          icon: UnreadBadge(
                            count: messagesProvider.totalUnread,
                            child: const Icon(Icons.mail_outline_rounded),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const InboxScreen(),
                              ),
                            );
                          },
                          color: EduBridgeColors.textPrimary,
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                      child: _bootstrapping
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildKPIsSection(teacherProvider),
                                const SizedBox(height: EduBridgeTheme.spacingXL),
                                _buildQuickActionsSection(context),
                              ],
                            )
                          : isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: left),
                                    const SizedBox(width: 18),
                                    Expanded(child: right),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    left,
                                    const SizedBox(height: EduBridgeTheme.spacingMD),
                                    right,
                                  ],
                                ),
                    ),
                  ),

                  if (_bootError != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: EduBridgeTheme.spacingLG,
                        left: 12,
                        right: 12,
                      ),
                      child: Text(
                        'Some data could not be loaded (see console for details).',
                        textAlign: TextAlign.center,
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummarySection(
    UserModel? user,
    TeacherProvider teacherProvider,
  ) {
    final initials = user?.firstName.isNotEmpty == true
        ? user!.firstName[0].toUpperCase()
        : 'T';

    return DashboardSection(
      title: 'Profile summary',
      child: teacherProvider.isLoadingStats
          ? Column(
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 86,
                  borderRadius:
                      BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 64,
                  borderRadius:
                      BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: EduBridgeColors.primary.withOpacity(0.18),
                      child: Text(
                        initials,
                        style: EduBridgeTypography.titleMedium.copyWith(
                          color: EduBridgeColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: EduBridgeTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Teacher',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: EduBridgeTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: EduBridgeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enseignant • ${_selectedClass?.name ?? '—'}',
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EduBridgeTheme.spacingMD),
                Row(
                  children: [
                    Expanded(
                      child: _miniKpi(
                        icon: Icons.class_rounded,
                        label: 'Classes',
                        value: teacherProvider.totalClasses.toString(),
                        color: EduBridgeColors.primary,
                      ),
                    ),
                    const SizedBox(width: EduBridgeTheme.spacingMD),
                    Expanded(
                      child: _miniKpi(
                        icon: Icons.people_alt_rounded,
                        label: 'Students',
                        value: teacherProvider.totalStudents.toString(),
                        color: EduBridgeColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _miniKpi({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: EduBridgeTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: EduBridgeColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(NotificationsProvider provider) {
    return DashboardSection(
      title: 'Notifications',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          );
        },
        child: Text(
          'All',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications',
                  message: 'You will see relevant updates here.',
                  actionLabel: 'Refresh',
                  onAction: () {
                    provider.load();
                  },
                )
              : Column(
                  children: provider.items.take(3).map(_notificationRow).toList(),
                ),
    );
  }

  Widget _notificationRow(Map<String, dynamic> n) {
    final unread = n['status']?.toString() == 'UNREAD';
    final id = n['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
        enableHover: false,
        onTap: unread && id.isNotEmpty
            ? () {
                Provider.of<NotificationsProvider>(context, listen: false)
                    .markRead(id);
              }
            : null,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unread ? EduBridgeColors.primary : EduBridgeColors.textTertiary,
              ),
            ),
            const SizedBox(width: EduBridgeTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EduBridgeTypography.titleSmall.copyWith(
                      fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                      color: EduBridgeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection(MessagesProvider provider) {
    return DashboardSection(
      title: 'Direct messages',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const InboxScreen()),
          );
        },
        child: Text(
          'Inbox',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: provider.loadingConversations
          ? const Center(child: CircularProgressIndicator())
          : provider.conversations.isEmpty
              ? EmptyState(
                  icon: Icons.mail_outline_rounded,
                  title: 'No messages',
                  message: 'Your conversations will appear here.',
                  actionLabel: 'Open',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const InboxScreen(),
                      ),
                    );
                  },
                )
              : Column(
                  children: provider.conversations.take(3).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                        enableHover: false,
                        onTap: () {
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
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  EduBridgeColors.secondary.withOpacity(0.14),
                              child: Text(
                                c.otherUserName.isNotEmpty
                                    ? c.otherUserName[0].toUpperCase()
                                    : '?',
                                style: EduBridgeTypography.titleMedium.copyWith(
                                  color: EduBridgeColors.secondary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.otherUserName.isNotEmpty
                                        ? c.otherUserName
                                        : 'Conversation',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: EduBridgeTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: EduBridgeColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.lastMessage.isEmpty
                                        ? 'Aucun message'
                                        : c.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: EduBridgeTypography.bodySmall.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (c.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(
                                    EduBridgeTheme.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildLessonOverviewSection() {
    return DashboardSection(
      title: 'Lesson overview',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlideRoute(const TeacherCoursesScreen()),
          );
        },
        child: Text(
          'Courses & lessons',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _loadingLessons
          ? Column(
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 86,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 86,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ],
            )
          : _recentLessons.isEmpty
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No lessons found',
                  message: 'Create or publish lessons to see them here.',
                  actionLabel: 'Open courses',
                  onAction: () {
                    Navigator.push(
                      context,
                      PageTransitions.fadeSlideRoute(
                        const TeacherCoursesScreen(),
                      ),
                    );
                  },
                )
              : Column(
                  children: _recentLessons.take(4).toList().asMap().entries.map((entry) {
                    final lesson = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                        enableHover: false,
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(EduBridgeTheme.spacingSM),
                              decoration: BoxDecoration(
                                color: EduBridgeColors.primary.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(EduBridgeTheme.radiusMD),
                              ),
                              child: const Icon(
                                Icons.play_lesson_rounded,
                                color: EduBridgeColors.primary,
                              ),
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: EduBridgeTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: EduBridgeColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated: ${DateFormat('dd/MM/yyyy').format(lesson.updatedAt ?? lesson.createdAt ?? DateTime.now())}',
                                    style: EduBridgeTypography.bodySmall.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: EduBridgeColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildStudentSubmissionsSection() {
    final selected = _selectedClass;
    return DashboardSection(
      title: 'Student submissions',
      action: TextButton(
        onPressed: selected == null
            ? null
            : () {
                Navigator.push(
                  context,
                  PageTransitions.fadeSlideRoute(
                    TeacherAssignmentsScreen(classModel: selected),
                  ),
                );
              },
        child: Text(
          'Assignments',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _loadingAssignments
          ? Column(
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 92,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 92,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ],
            )
          : selected == null
              ? EmptyState(
                  icon: Icons.class_rounded,
                  title: 'No class selected',
                  message: 'Create a class first.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Class: ${selected.name}',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    if (_assignmentsPreview.isEmpty)
                      EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No assignments yet',
                        message:
                            'Create your first assignment for this class.',
                      )
                    else
                      Column(
                        children: _assignmentsPreview.map((a) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.all(
                                EduBridgeTheme.spacingMD,
                              ),
                              enableHover: false,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      EduBridgeTheme.spacingSM,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EduBridgeColors.secondary.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(EduBridgeTheme.radiusMD),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_rounded,
                                      color: EduBridgeColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: EduBridgeTheme.spacingMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              EduBridgeTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: EduBridgeColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Due: ${DateFormat('dd/MM/yyyy').format(a.dueDate)}',
                                          style: EduBridgeTypography.bodySmall.copyWith(
                                            color: EduBridgeColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageTransitions.fadeSlideRoute(
                                          AssignmentSubmissionsScreen(
                                            assignmentId: a.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    Text(
                      'Latest submissions',
                      style: EduBridgeTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: EduBridgeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _loadingSubmissions
                        ? const Center(child: CircularProgressIndicator())
                        : _submissionPreview.isEmpty
                            ? Text(
                                'No submissions to preview yet.',
                                style: EduBridgeTypography.bodySmall.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : Column(
                                children: _submissionPreview.map((s) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(
                                        EduBridgeTheme.spacingMD,
                                      ),
                                      enableHover: false,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                EduBridgeColors.primary.withOpacity(0.14),
                                            child: Text(
                                              s.kidName.isNotEmpty
                                                  ? s.kidName[0].toUpperCase()
                                                  : '?',
                                              style: EduBridgeTypography.titleMedium.copyWith(
                                                color: EduBridgeColors.primary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: EduBridgeTheme.spacingMD),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.kidName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      EduBridgeTypography.titleSmall.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: EduBridgeColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  s.submittedAt != null
                                                      ? 'Submitted: ${DateFormat('dd/MM/yyyy HH:mm').format(s.submittedAt!)}'
                                                      : 'Status: ${s.status.displayName}',
                                                  style:
                                                      EduBridgeTypography.bodySmall.copyWith(
                                                    color: EduBridgeColors.textSecondary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (s.score != null) ...[
                                            const SizedBox(width: 10),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              s.score!.toStringAsFixed(1),
                                              style:
                                                  EduBridgeTypography.bodySmall.copyWith(
                                                color: EduBridgeColors.textSecondary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                  ],
                ),
    );
  }

  Widget _buildParentRatingsSection() {
    return DashboardSection(
      title: 'Parent reviews & ratings',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlideRoute(const TeacherLessonRatingsScreen()),
          );
        },
        child: Text(
          'Details',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _loadingRatings
          ? Column(
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 86,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 86,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ],
            )
          : _ratingsSummary.isEmpty
              ? EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'No ratings yet',
                  message: 'Parents will rate your lessons here.',
                )
              : Column(
                  children: _ratingsSummary.take(5).map((item) {
                    final title = item['lessonTitle']?.toString() ?? '';
                    final avg =
                        (item['averageStars'] as num?)?.toDouble() ?? 0;
                    final total =
                        (item['totalReviews'] as num?)?.toInt() ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                        enableHover: false,
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(EduBridgeTheme.spacingSM),
                              decoration: BoxDecoration(
                                color: EduBridgeColors.warning.withOpacity(0.14),
                                borderRadius:
                                    BorderRadius.circular(EduBridgeTheme.radiusMD),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        EduBridgeTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: EduBridgeColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avg.toStringAsFixed(1)} / 5.0 • $total avis',
                                    style:
                                        EduBridgeTypography.bodySmall.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: EduBridgeColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildNotesProgressSection(TeacherProvider teacherProvider) {
    final classProgress = teacherProvider.classProgress;

    return DashboardSection(
      title: 'Notes & progress',
      action: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlideRoute(const TeacherStudentsHubScreen()),
          );
        },
        child: Text(
          'Manage',
          style: EduBridgeTypography.labelLarge.copyWith(
            color: EduBridgeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: teacherProvider.isLoadingProgress
          ? Column(
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 96,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 96,
                  borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                ),
              ],
            )
          : classProgress == null || classProgress.students.isEmpty
              ? EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No progress data',
                  message:
                      'Progress analytics will appear here once lessons are completed.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Top learners (avg score)',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...teacherProvider.sortedStudents.take(3).map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                          enableHover: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        EduBridgeColors.accent.withOpacity(0.16),
                                    child: Text(
                                      s.kidName.isNotEmpty
                                          ? s.kidName[0].toUpperCase()
                                          : '?',
                                      style: EduBridgeTypography.titleMedium.copyWith(
                                        color: EduBridgeColors.accent,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: EduBridgeTheme.spacingMD),
                                  Expanded(
                                    child: Text(
                                      s.kidName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          EduBridgeTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: EduBridgeColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${s.avgScore.toStringAsFixed(1)}%',
                                    style: EduBridgeTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: EduBridgeColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  EduBridgeTheme.radiusSM,
                                ),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  backgroundColor: EduBridgeColors.surfaceVariant,
                                  value: s.completionRate / 100,
                                  valueColor: AlwaysStoppedAnimation<Color>(s.levelColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${s.completedLessons}/${s.totalLessons} lessons • ${s.level}',
                                style: EduBridgeTypography.bodySmall.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }

  Widget _buildGamificationInsightsSection(TeacherProvider teacherProvider) {
    final overall = teacherProvider.classProgress?.overallStats;
    final students = teacherProvider.classProgress?.students ?? [];

    return DashboardSection(
      title: 'Gamification insights',
      child: teacherProvider.isLoadingProgress
          ? const Center(child: CircularProgressIndicator())
          : overall == null
              ? Text(
                  'Not enough data yet.',
                  style: EduBridgeTypography.bodySmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _insightChip(
                            icon: Icons.score_rounded,
                            label: 'Avg score',
                            value: '${overall.averageScore.toStringAsFixed(1)}%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _insightChip(
                            icon: Icons.school_rounded,
                            label: 'Completion',
                            value:
                                '${overall.overallCompletionRate.toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _levelDistribution(students),
                  ],
                ),
    );
  }

  Widget _insightChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      enableHover: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
            decoration: BoxDecoration(
              color: EduBridgeColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            ),
            child: Icon(icon, color: EduBridgeColors.primary),
          ),
          const SizedBox(width: EduBridgeTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: EduBridgeTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: EduBridgeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: EduBridgeTypography.bodySmall.copyWith(
                    color: EduBridgeColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelDistribution(List<StudentProgressModel> students) {
    final counts = <String, int>{};
    for (final s in students) {
      counts[s.level] = (counts[s.level] ?? 0) + 1;
    }

    final ordered = [
      'Excellent',
      'Good',
      'Average',
      'Needs Improvement'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning levels',
          style: EduBridgeTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w900,
            color: EduBridgeColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...ordered.map((lvl) {
          final count = counts[lvl] ?? 0;
          final color = (lvl == 'Excellent')
              ? EduBridgeColors.success
              : (lvl == 'Good')
                  ? EduBridgeColors.primary
                  : (lvl == 'Average')
                      ? EduBridgeColors.warning
                      : EduBridgeColors.error;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
              enableHover: false,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  Expanded(
                    child: Text(
                      lvl,
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: EduBridgeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: EduBridgeColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
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
        // Indicateur du nombre total de classes
        _buildKPICard(
          icon: Icons.class_,
          title: 'Total Classes',
          value: teacherProvider.totalClasses.toString(),
          color: EduBridgeColors.primary,
          gradient: EduBridgeColors.primaryGradient,
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Indicateur du nombre total d'élèves
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
        // Accès à la gestion des classes
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
