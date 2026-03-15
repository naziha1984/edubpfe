import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/lessons_provider.dart';
import '../providers/subjects_provider.dart';
import '../models/lesson_model.dart';
import '../models/subject_model.dart';
import '../components/lesson_card.dart';
import '../components/lesson_form_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';

/// Écran de gestion des lessons par subject (CRUD admin)
class AdminLessonsScreen extends StatefulWidget {
  final SubjectModel subject;

  const AdminLessonsScreen({
    super.key,
    required this.subject,
  });

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les lessons au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LessonsProvider>(context, listen: false);
      provider.loadLessonsBySubject(widget.subject.id);
    });
  }

  Future<void> _showCreateDialog() async {
    final subjectsProvider = Provider.of<SubjectsProvider>(context, listen: false);
    
    // Charger les subjects si nécessaire
    if (subjectsProvider.subjects.isEmpty) {
      await subjectsProvider.loadSubjects();
    }

    final result = await showModalBottomSheet<LessonModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonFormBottomSheet(
        subjects: subjectsProvider.subjects,
        initialSubjectId: widget.subject.id,
      ),
    );

    if (result != null && mounted) {
      await _handleCreate(result);
    }
  }

  Future<void> _showEditDialog(LessonModel lesson) async {
    final subjectsProvider = Provider.of<SubjectsProvider>(context, listen: false);
    
    // Charger les subjects si nécessaire
    if (subjectsProvider.subjects.isEmpty) {
      await subjectsProvider.loadSubjects();
    }

    final result = await showModalBottomSheet<LessonModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonFormBottomSheet(
        lesson: lesson,
        subjects: subjectsProvider.subjects,
      ),
    );

    if (result != null && mounted) {
      await _handleUpdate(result);
    }
  }

  Future<void> _handleCreate(LessonModel lesson) async {
    final provider = Provider.of<LessonsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall<LessonModel>(
      context,
      () => provider.createLesson(lesson),
    );

    if (success != null && mounted) {
      Toast.success(context, 'Lesson created successfully!');
    }
  }

  Future<void> _handleUpdate(LessonModel lesson) async {
    final provider = Provider.of<LessonsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall<LessonModel>(
      context,
      () => provider.updateLesson(lesson),
    );

    if (success != null && mounted) {
      Toast.success(context, 'Lesson updated successfully!');
    }
  }

  Future<void> _handleDelete(LessonModel lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
          'Are you sure you want to delete "${lesson.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: EduBridgeColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<LessonsProvider>(context, listen: false);

      try {
        await provider.deleteLesson(lesson.id);
        if (mounted) {
          Toast.success(context, 'Lesson deleted successfully!');
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LessonsProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar avec Hero title
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
                      child: Hero(
                        tag: 'subject_title_${widget.subject.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subject.name,
                                style: EduBridgeTypography.headlineMedium.copyWith(
                                  color: EduBridgeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Lessons',
                                style: EduBridgeTypography.bodyMedium.copyWith(
                                  color: EduBridgeColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showCreateDialog,
                      color: EduBridgeColors.primary,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Lesson'),
        backgroundColor: EduBridgeColors.primary,
      ),
    );
  }

  Widget _buildContent(LessonsProvider provider) {
    if (provider.isLoading && provider.lessons.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (provider.error != null && provider.lessons.isEmpty) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Lessons',
        message: provider.error ?? 'Unknown error',
        onRetry: () => provider.loadLessonsBySubject(widget.subject.id),
      );
    }

    if (provider.lessons.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No Lessons',
        message: 'Create your first lesson for this subject',
        actionLabel: 'Create Lesson',
        onAction: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadLessonsBySubject(widget.subject.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: provider.lessons.length,
        itemBuilder: (context, index) {
          final lesson = provider.lessons[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
            child: LessonCard(
              lesson: lesson,
              index: index,
              onEdit: () => _showEditDialog(lesson),
              onDelete: () => _handleDelete(lesson),
            ),
          );
        },
      ),
    );
  }
}
