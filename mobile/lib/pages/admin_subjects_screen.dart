import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/subjects_provider.dart';
import '../models/subject_model.dart';
import '../components/subject_card.dart';
import '../components/subject_form_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../ui/components/gradient_button.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import 'admin_lessons_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Écran de gestion des subjects (CRUD admin)
class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les subjects au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SubjectsProvider>(context, listen: false);
      provider.loadSubjects();
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showModalBottomSheet<SubjectModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubjectFormBottomSheet(),
    );

    if (result != null && mounted) {
      await _handleCreate(result);
    }
  }

  Future<void> _showEditDialog(SubjectModel subject) async {
    final result = await showModalBottomSheet<SubjectModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubjectFormBottomSheet(subject: subject),
    );

    if (result != null && mounted) {
      await _handleUpdate(result);
    }
  }

  Future<void> _handleCreate(SubjectModel subject) async {
    final provider = Provider.of<SubjectsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall<SubjectModel>(
      context,
      () => provider.createSubject(subject),
    );

    if (success != null && mounted) {
      Toast.success(context, 'Subject created successfully!');
    }
  }

  Future<void> _handleUpdate(SubjectModel subject) async {
    final provider = Provider.of<SubjectsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall<SubjectModel>(
      context,
      () => provider.updateSubject(subject),
    );

    if (success != null && mounted) {
      Toast.success(context, 'Subject updated successfully!');
    }
  }

  Future<void> _handleDelete(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? This action cannot be undone.',
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
      final provider = Provider.of<SubjectsProvider>(context, listen: false);

      try {
        await provider.deleteSubject(subject.id);
        if (mounted) {
          Toast.success(context, 'Subject deleted successfully!');
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectsProvider>(context);

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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Manage Subjects',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.bold,
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
        label: const Text('Create Subject'),
        backgroundColor: EduBridgeColors.primary,
      ),
    );
  }

  Widget _buildContent(SubjectsProvider provider) {
    if (provider.isLoading && provider.subjects.isEmpty) {
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

    if (provider.error != null && provider.subjects.isEmpty) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Subjects',
        message: provider.error ?? 'Unknown error',
        onRetry: () => provider.loadSubjects(),
      );
    }

    if (provider.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.subject_outlined,
        title: 'No Subjects',
        message: 'Create your first subject to get started',
        actionLabel: 'Create Subject',
        onAction: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSubjects(),
      child: ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: provider.subjects.length,
        itemBuilder: (context, index) {
          final subject = provider.subjects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: SubjectCard(
            subject: subject,
            onTap: () {
              Navigator.push(
                context,
                PageTransitions.fadeSlideRoute(
                  AdminLessonsScreen(subject: subject),
                ),
              );
            },
            onEdit: () => _showEditDialog(subject),
            onDelete: () => _handleDelete(subject),
          ),
          );
        },
      ),
    );
  }
}
