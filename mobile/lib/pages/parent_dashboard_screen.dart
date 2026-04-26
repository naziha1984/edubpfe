import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/conversation_model.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import '../providers/kids_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/api_service.dart';
import '../ui/dashboard/dashboard_header.dart';
import '../ui/dashboard/dashboard_kpi_card.dart';
import '../ui/dashboard/dashboard_motion.dart';
import '../ui/dashboard/dashboard_premium_states.dart';
import '../ui/dashboard/dashboard_responsive.dart';
import '../ui/dashboard/dashboard_scaffold.dart';
import '../ui/dashboard/dashboard_states.dart';
import '../ui/components/ayah_card.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/theme/edubridge_typography.dart';
import '../utils/app_router.dart';
import 'chat_detail_screen.dart';
import 'kids_list_page.dart';
import 'parent_teachers_list_screen.dart';
import 'verify_pin_page.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _bootstrapping = true;
  String? _error;
  String? _selectedKidId;

  List<Map<String, dynamic>> _notes = [];
  Map<String, dynamic>? _trackingOverview;
  List<LessonModel> _latestLessons = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _rewards;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _error = null;
    });
    final kidsProvider = Provider.of<KidsProvider>(context, listen: false);
    final notificationsProvider =
        Provider.of<NotificationsProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);

    try {
      await Future.wait([
        kidsProvider.loadKids(),
        notificationsProvider.load(),
        messagesProvider.loadConversations(),
      ]);
      if (kidsProvider.kids.isNotEmpty) {
        _selectedKidId = kidsProvider.kids.first['id']?.toString();
        if (_selectedKidId != null) {
          await _loadKidInsights(_selectedKidId!);
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    if (!mounted) return;
    setState(() => _bootstrapping = false);
  }

  Future<void> _loadKidInsights(String kidId) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final kidsProvider = Provider.of<KidsProvider>(context, listen: false);
    final kid = _findKidById(kidsProvider.kids, kidId);

    try {
      final notesFuture = api.getStudentNotes(kidId);
      final overviewFuture = api.getStudentTrackingOverview(kidId);
      final lessonsFuture = _loadLatestLessonsForKid(
        schoolLevel: _asInt(kid?['schoolLevel']),
      );

      final results = await Future.wait([notesFuture, overviewFuture, lessonsFuture]);
      _notes = (results[0] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _trackingOverview = Map<String, dynamic>.from(results[1] as Map);
      _latestLessons = results[2] as List<LessonModel>;
      _reviews = await _loadRecentReviews(_latestLessons);

      if (api.kidToken != null) {
        try {
          _rewards = await api.getKidRewards();
        } catch (_) {
          _rewards = null;
        }
      } else {
        _rewards = null;
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<List<LessonModel>> _loadLatestLessonsForKid({int? schoolLevel}) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final subjects = await api.getSubjects();
    final lessons = <LessonModel>[];

    for (final s in subjects.take(5)) {
      final subjectMap = Map<String, dynamic>.from(s as Map);
      final subjectId = subjectMap['id']?.toString();
      if (subjectId == null || subjectId.isEmpty) continue;
      try {
        final rows = await api.getLessons(subjectId, schoolLevel: schoolLevel);
        lessons.addAll(
          rows
              .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((l) => l.isActive),
        );
      } catch (_) {}
    }

    lessons.sort((a, b) {
      final da = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return lessons.take(8).toList();
  }

  Future<List<Map<String, dynamic>>> _loadRecentReviews(
    List<LessonModel> lessons,
  ) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final out = <Map<String, dynamic>>[];
    for (final l in lessons.take(3)) {
      try {
        final data = await api.getLessonReviews(l.id, limit: 6);
        final rows = (data['data'] as List?) ?? const [];
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row as Map);
          final comment = map['comment']?.toString() ?? '';
          if (comment.trim().isEmpty) continue;
          map['lessonTitle'] = l.title;
          out.add(map);
        }
      } catch (_) {}
    }
    out.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return out.take(6).toList();
  }

  Map<String, dynamic>? _findKidById(List<dynamic> kids, String? kidId) {
    if (kidId == null) return null;
    for (final kid in kids) {
      final map = Map<String, dynamic>.from(kid as Map);
      if (map['id']?.toString() == kidId) return map;
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  ConversationModel? _pickTeacherConversation(MessagesProvider provider) {
    for (final c in provider.conversations) {
      if (c.otherUserRole.toUpperCase() == 'TEACHER') return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final kidsProvider = Provider.of<KidsProvider>(context);
    final notificationsProvider = Provider.of<NotificationsProvider>(context);
    final messagesProvider = Provider.of<MessagesProvider>(context);

    if (!auth.isParent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppRouter.getHomePage(context)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedKid = _findKidById(kidsProvider.kids, _selectedKidId) ??
        (kidsProvider.kids.isNotEmpty
            ? Map<String, dynamic>.from(kidsProvider.kids.first as Map)
            : null);
    final teacherConversation = _pickTeacherConversation(messagesProvider);
    final kidName = selectedKid == null
        ? 'Votre enfant'
        : '${selectedKid['firstName'] ?? ''} ${selectedKid['lastName'] ?? ''}'
            .trim();
    final schoolLevel = _asInt(selectedKid?['schoolLevel']);

    return DashboardScaffold(
      navItems: const [
        DashboardNavItem(label: 'Overview', icon: Icons.dashboard_rounded),
        DashboardNavItem(label: 'Progress', icon: Icons.query_stats_rounded),
        DashboardNavItem(label: 'Lessons', icon: Icons.menu_book_rounded),
        DashboardNavItem(label: 'Messages', icon: Icons.forum_rounded),
      ],
      currentNavIndex: 0,
      header: DashboardHeader(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
          child: const Icon(Icons.family_restroom_rounded, color: EduBridgeColors.primary),
        ),
        title: 'Parent Dashboard',
        subtitle:
            'Bienvenue ${auth.user?.firstName ?? ''}. Vue claire et rassurante de la progression.',
        trailing: _profileMenu(auth),
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
              child: AyahCard(
                ayahText:
                    'يَرْفَعِ اللَّهُ الَّذِينَ آمَنُوا مِنكُمْ وَالَّذِينَ أُوتُوا الْعِلْمَ دَرَجَاتٍ',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
                child: DashboardSectionCard(
                  title: 'Information',
                  child: Text(
                    _error!,
                    style: EduBridgeTypography.bodyMedium.copyWith(
                      color: EduBridgeColors.error,
                    ),
                  ),
                ),
              ),
            DashboardEntrance(
              delayMs: 30,
              child: _buildTopWelcome(
                kidName: kidName,
                schoolLevel: schoolLevel,
                kids: kidsProvider.kids,
              ),
            ),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            DashboardEntrance(
              delayMs: 90,
              child: _buildSummaryCards(
                notificationsProvider: notificationsProvider,
                messagesProvider: messagesProvider,
                kidsCount: kidsProvider.kids.length,
              ),
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
                    _buildChildSummary(selectedKid),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildTeacherCard(
                      teacherConversation: teacherConversation,
                      selectedKid: selectedKid,
                    ),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildProgressSummary(selectedKid),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildGamificationSummary(selectedKid),
                  ],
                );
                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTeacherNotes(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildLessonsSection(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildReviewsSection(),
                    const SizedBox(height: EduBridgeTheme.spacingMD),
                    _buildNotificationsSection(notificationsProvider),
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
            if (_bootstrapping)
              const Padding(
                padding: EdgeInsets.only(top: EduBridgeTheme.spacingMD),
                child: DashboardLoadingBlock(height: 110),
              ),
            const SizedBox(height: EduBridgeTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _profileMenu(AuthProvider auth) {
    final initials = (auth.user?.firstName.isNotEmpty ?? false)
        ? auth.user!.firstName[0].toUpperCase()
        : 'P';
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
              Text('Se déconnecter'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        backgroundColor: EduBridgeColors.primary.withOpacity(0.14),
        child: Text(
          initials,
          style: EduBridgeTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: EduBridgeColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTopWelcome({
    required String kidName,
    required int? schoolLevel,
    required List<dynamic> kids,
  }) {
    return DashboardSectionCard(
      title: 'Top welcome section',
      action: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const KidsListPage()),
          );
        },
        icon: const Icon(Icons.manage_accounts_rounded),
        label: const Text('Gérer les enfants'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour 👋',
            style: EduBridgeTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Suivi de $kidName${schoolLevel != null ? ' • Niveau $schoolLevel' : ''}',
            style: EduBridgeTypography.bodyLarge.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('${kids.length} enfant(s)', Icons.child_care_rounded),
              _chip('Design premium', Icons.auto_awesome_rounded),
              _chip('Données temps réel', Icons.bolt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required NotificationsProvider notificationsProvider,
    required MessagesProvider messagesProvider,
    required int kidsCount,
  }) {
    return AdaptiveDashboardGrid(
      maxColumns: 3,
      children: [
        DashboardKpiCard(
          icon: Icons.notifications_active_rounded,
          label: 'Notifications non lues',
          value: '${notificationsProvider.unreadCount}',
          color: const Color(0xFF4F46E5),
          badgeCount: notificationsProvider.unreadCount,
        ),
        DashboardKpiCard(
          icon: Icons.mark_email_unread_rounded,
          label: 'Messages non lus',
          value: '${messagesProvider.totalUnread}',
          color: const Color(0xFF0EA5E9),
          badgeCount: messagesProvider.totalUnread,
        ),
        DashboardKpiCard(
          icon: Icons.groups_rounded,
          label: 'Enfants suivis',
          value: '$kidsCount',
          color: const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _buildChildSummary(Map<String, dynamic>? kid) {
    if (kid == null) {
      return const DashboardSectionCard(
        title: 'Child profile summary card',
        child: DashboardPremiumStateCard(
          icon: Icons.child_care_rounded,
          title: 'Aucun enfant',
          message: 'Ajoutez un enfant pour commencer un suivi pédagogique clair et rassurant.',
        ),
      );
    }
    final fullName = '${kid['firstName'] ?? ''} ${kid['lastName'] ?? ''}'.trim();
    final school = kid['school']?.toString();
    final grade = kid['grade']?.toString();
    final level = _asInt(kid['schoolLevel']);
    return DashboardSectionCard(
      title: 'Child profile summary card',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFFF4E8),
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'K',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
          ),
        ),
        title: Text(fullName, style: EduBridgeTypography.titleMedium),
        subtitle: Text(
          '${grade ?? 'Classe non définie'} • ${school ?? 'École non définie'}',
          style: EduBridgeTypography.bodyMedium.copyWith(color: EduBridgeColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: EduBridgeColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('Niveau ${level ?? '-'}'),
        ),
      ),
    );
  }

  Widget _buildTeacherCard({
    required ConversationModel? teacherConversation,
    required Map<String, dynamic>? selectedKid,
  }) {
    return DashboardSectionCard(
      title: 'Selected teacher card',
      action: TextButton.icon(
        onPressed: selectedKid == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ParentTeachersListScreen(
                      kidId: selectedKid['id']?.toString() ?? '',
                      kidName:
                          '${selectedKid['firstName'] ?? ''} ${selectedKid['lastName'] ?? ''}'
                              .trim(),
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.search_rounded),
        label: const Text('Choisir'),
      ),
      child: teacherConversation == null
          ? const DashboardPremiumStateCard(
              icon: Icons.school_rounded,
              title: 'Aucun enseignant sélectionné',
              message: 'Associez un enseignant pour activer le suivi académique et la messagerie directe.',
              variant: DashboardStateVariant.info,
            )
          : Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherConversation.otherUserName,
                        style: EduBridgeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disponible en message direct',
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChatDetailScreen(
                          conversationId: teacherConversation.id,
                          receiverId: teacherConversation.otherUserId,
                          title: teacherConversation.otherUserName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Contacter'),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressSummary(Map<String, dynamic>? selectedKid) {
    final latest = _asInt(_trackingOverview?['latestProgressPercent']) ?? 0;
    final avg = _asInt(_trackingOverview?['averageRecentProgress']) ?? 0;
    final totalNotes = _asInt(_trackingOverview?['totalNotes']) ?? _notes.length;
    final totalProgress = _asInt(_trackingOverview?['totalProgressEntries']) ?? 0;
    return DashboardSectionCard(
      title: 'Child progress summary',
      child: selectedKid == null
          ? const DashboardPremiumStateCard(
              icon: Icons.query_stats_rounded,
              title: 'Progression indisponible',
              message: 'Sélectionnez un enfant pour afficher des indicateurs de progression détaillés.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _miniMetric('Dernier score', '$latest%', Icons.trending_up_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniMetric('Moyenne récente', '$avg%', Icons.analytics_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _miniMetric('Notes enseignant', '$totalNotes', Icons.note_alt_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _miniMetric('Entrées progrès', '$totalProgress', Icons.auto_graph_rounded)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTeacherNotes() {
    return DashboardSectionCard(
      title: 'Teacher notes preview',
      child: _notes.isEmpty
          ? const DashboardPremiumStateCard(
              icon: Icons.sticky_note_2_rounded,
              title: 'Aucune note récente',
              message: 'Les retours pédagogiques de l’enseignant apparaîtront ici.',
            )
          : Column(
              children: _notes.take(3).map((n) {
                final rec = n['recommendations']?.toString();
                final behavior = n['behavior']?.toString();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rate_review_rounded),
                  title: Text(
                    (rec != null && rec.isNotEmpty)
                        ? rec
                        : (behavior != null && behavior.isNotEmpty)
                            ? behavior
                            : 'Retour enseignant',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatDate(n['createdAt']?.toString())),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLessonsSection() {
    return DashboardSectionCard(
      title: 'Latest lessons section',
      child: _latestLessons.isEmpty
          ? const DashboardNoLessonsState()
          : Column(
              children: _latestLessons.take(5).map((lesson) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 18,
                    child: Icon(Icons.play_lesson_rounded, size: 18),
                  ),
                  title: Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${lesson.language ?? 'FR'} • ${lesson.level ?? 'General'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDate(lesson.updatedAt?.toIso8601String() ?? lesson.createdAt?.toIso8601String()),
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReviewsSection() {
    return DashboardSectionCard(
      title: 'Reviews/comments history',
      child: _reviews.isEmpty
          ? const DashboardNoReviewsState()
          : Column(
              children: _reviews.take(4).map((r) {
                final stars = _asInt(r['stars']) ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EduBridgeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r['lessonTitle']?.toString() ?? 'Leçon'),
                          const Spacer(),
                          Text('★' * stars, style: const TextStyle(color: Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(r['comment']?.toString() ?? ''),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotificationsSection(NotificationsProvider provider) {
    return DashboardSectionCard(
      title: 'Notifications preview',
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

  Widget _buildGamificationSummary(Map<String, dynamic>? selectedKid) {
    final points = _asInt(_rewards?['totalPoints'] ?? _rewards?['points']) ?? 0;
    final badges = (_rewards?['badges'] is List) ? (_rewards!['badges'] as List).length : 0;
    final streak = _asInt(_rewards?['streak'] ?? _rewards?['currentStreak']) ?? 0;
    return DashboardSectionCard(
      title: 'Gamification summary',
      child: selectedKid == null
          ? const DashboardPremiumStateCard(
              icon: Icons.emoji_events_rounded,
              title: 'Gamification indisponible',
              message: 'Ajoutez un enfant pour activer les objectifs et récompenses éducatives.',
            )
          : (_rewards == null
              ? Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Activez la session enfant (PIN) pour voir points, badges et streak.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => VerifyPinPage(
                              kidId: selectedKid['id']?.toString() ?? '',
                              kidName:
                                  '${selectedKid['firstName'] ?? ''} ${selectedKid['lastName'] ?? ''}'
                                      .trim(),
                            ),
                          ),
                        ).then((_) => _bootstrap());
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Activer'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _miniMetric('Points', '$points', Icons.bolt_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _miniMetric('Badges', '$badges', Icons.verified_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _miniMetric('Streak', '$streak', Icons.local_fire_department_rounded)),
                  ],
                )),
    );
  }

  Widget _miniMetric(String label, String value, IconData icon) {
    return Container(
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
                Text(value, style: EduBridgeTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: EduBridgeTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EduBridgeColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: EduBridgeColors.primary),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('dd/MM • HH:mm').format(dt.toLocal());
  }
}
