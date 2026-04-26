import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/admin_dashboard/dashboard_section.dart';
import '../components/admin_dashboard/status_chip.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../providers/admin_provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/theme/edubridge_typography.dart';

class AdminLessonMonitoringScreen extends StatefulWidget {
  const AdminLessonMonitoringScreen({super.key});

  @override
  State<AdminLessonMonitoringScreen> createState() =>
      _AdminLessonMonitoringScreenState();
}

class _AdminLessonMonitoringScreenState
    extends State<AdminLessonMonitoringScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAdminLessons();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _moderate(String lessonId, String currentStatus) async {
    final noteCtrl = TextEditingController();
    String selected = currentStatus;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Moderate lesson'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                items: const [
                  DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                  DropdownMenuItem(value: 'FLAGGED', child: Text('Flagged')),
                  DropdownMenuItem(value: 'HIDDEN', child: Text('Hidden')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => selected = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Moderation status',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Internal moderation note',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'status': selected,
                'note': noteCtrl.text.trim(),
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final ok = await admin.moderateLesson(
      lessonId,
      status: result['status']!,
      moderationNote: result['note'],
    );
    if (!mounted) return;
    if (ok) {
      Toast.success(context, 'Lesson moderation updated');
    } else {
      Toast.error(context, admin.lessonModerationError ?? 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
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
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Lesson monitoring',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: EduBridgeColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => admin.loadAdminLessons(),
                  child: ListView(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                    children: [
                      AdminDashboardSection(
                        title: 'Filters',
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search by lesson title or description',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
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
                              decoration: const InputDecoration(
                                labelText: 'Moderation status',
                              ),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All statuses'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'APPROVED',
                                  child: Text('Approved'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'FLAGGED',
                                  child: Text('Flagged'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'HIDDEN',
                                  child: Text('Hidden'),
                                ),
                              ],
                              onChanged: (value) {
                                admin.setLessonStatusFilter(value);
                                admin.loadAdminLessons();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingLG),
                      if (admin.isLoadingAdminLessons)
                        const Center(child: CircularProgressIndicator())
                      else if (admin.adminLessonsError != null)
                        ErrorState(
                          icon: Icons.error_outline,
                          title: 'Error loading lessons',
                          message: admin.adminLessonsError!,
                          onRetry: () => admin.loadAdminLessons(),
                        )
                      else if (admin.adminLessons.isEmpty)
                        const EmptyState(
                          icon: Icons.play_lesson_outlined,
                          title: 'No lessons found',
                          message: 'No lessons match the current filters.',
                        )
                      else
                        ...admin.adminLessons.map((lesson) {
                          final status =
                              lesson['moderationStatus']?.toString() ?? 'APPROVED';
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: EduBridgeTheme.spacingMD,
                            ),
                            child: AdminDashboardSection(
                              title: lesson['title']?.toString() ?? 'Lesson',
                              action: TextButton(
                                onPressed: () => _moderate(
                                  lesson['id'].toString(),
                                  status,
                                ),
                                child: const Text('Moderate'),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildStatusChip(status),
                                      _metaChip(
                                        Icons.person_outline_rounded,
                                        lesson['teacherName']?.toString() ?? 'Teacher',
                                      ),
                                      _metaChip(
                                        Icons.menu_book_rounded,
                                        lesson['subjectName']?.toString() ?? 'Subject',
                                      ),
                                      if ((lesson['level']?.toString() ?? '').isNotEmpty)
                                        _metaChip(
                                          Icons.school_outlined,
                                          lesson['level'].toString(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    lesson['description']?.toString().isNotEmpty == true
                                        ? lesson['description'].toString()
                                        : 'No description.',
                                    style: EduBridgeTypography.bodySmall.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  if ((lesson['moderationNote']?.toString() ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Note: ${lesson['moderationNote']}',
                                      style: EduBridgeTypography.bodySmall.copyWith(
                                        color: EduBridgeColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
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

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EduBridgeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EduBridgeColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: EduBridgeTypography.labelSmall.copyWith(
              color: EduBridgeColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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

