import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../providers/auth_provider.dart';
import '../providers/subjects_provider.dart';
import '../utils/app_router.dart';
import '../models/subject_model.dart';
import '../components/subject_form_bottom_sheet.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import 'admin_lessons_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Matières + leçons : même flux que l’admin, autorisé côté API pour les enseignants.
class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = Provider.of<SubjectsProvider>(context, listen: false);
      sp.loadSubjects();
    });
  }

  Future<void> _showCreateSubject() async {
    final result = await showModalBottomSheet<SubjectModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubjectFormBottomSheet(),
    );
    if (result == null || !mounted) return;

    final sp = Provider.of<SubjectsProvider>(context, listen: false);
    final ok = await ErrorHandler.handleApiCall(
      context,
      () => sp.createSubject(result),
    );
    if (ok != null && mounted) {
      Toast.success(context, 'Subject created!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => AppRouter.getHomePage(c)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subjects = Provider.of<SubjectsProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Courses & lessons',
                            style: EduBridgeTypography.headlineMedium.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Add a subject, then open it to create lessons.',
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showCreateSubject,
                      color: EduBridgeColors.primary,
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList(context, subjects)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSubject,
        icon: const Icon(Icons.library_add_outlined),
        label: const Text('New subject'),
        backgroundColor: EduBridgeColors.primary,
      ),
    );
  }

  Widget _buildList(BuildContext context, SubjectsProvider sp) {
    if (sp.isLoading && sp.subjects.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 72,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (sp.error != null && sp.subjects.isEmpty) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error loading subjects',
        message: sp.error ?? 'Unknown error',
        onRetry: () => sp.loadSubjects(),
      );
    }

    if (sp.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        message: 'Create a subject, then add lessons inside it.',
        actionLabel: 'Create subject',
        onAction: _showCreateSubject,
      );
    }

    return RefreshIndicator(
      onRefresh: () => sp.loadSubjects(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          EduBridgeTheme.spacingLG,
          0,
          EduBridgeTheme.spacingLG,
          88,
        ),
        itemCount: sp.subjects.length,
        itemBuilder: (context, index) {
          final s = sp.subjects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
            child: GlassCard(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.fadeSlideRoute(AdminLessonsScreen(subject: s)),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: EduBridgeColors.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(EduBridgeTheme.radiusMD),
                    ),
                    child: const Icon(
                      Icons.topic_outlined,
                      color: EduBridgeColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: EduBridgeTypography.titleMedium.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (s.description != null &&
                            s.description!.isNotEmpty)
                          Text(
                            s.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }
}
