import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/teacher_provider.dart';
import '../models/class_model.dart';
import '../components/class_card.dart';
import '../components/class_form_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import 'class_details_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Écran de gestion des classes (CRUD teacher)
class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les classes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      provider.loadClasses();
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showModalBottomSheet<ClassModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClassFormBottomSheet(),
    );

    if (result != null && mounted) {
      await _handleCreate(result);
    }
  }

  Future<void> _handleCreate(ClassModel classModel) async {
    final provider = Provider.of<TeacherProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => provider.createClass(classModel),
    );

    if (success == true && mounted) {
      Toast.success(context, 'Class created successfully!');
    }
  }

  Future<void> _copyClassCode(String classCode) async {
    await Clipboard.setData(ClipboardData(text: classCode));
    if (mounted) {
      Toast.success(context, 'Class code copied to clipboard!');
    }
  }

  Future<void> _shareClassCode(String classCode) async {
    // TODO: Implement share functionality
    // For now, just copy to clipboard
    await _copyClassCode(classCode);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherProvider>(context);

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
                        'My Classes',
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
        label: const Text('Create Class'),
        backgroundColor: EduBridgeColors.primary,
      ),
    );
  }

  Widget _buildContent(TeacherProvider provider) {
    if (provider.isLoadingClasses && provider.classes.isEmpty) {
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

    if (provider.classesError != null && provider.classes.isEmpty) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Classes',
        message: provider.classesError ?? 'Unknown error',
        onRetry: () => provider.loadClasses(),
      );
    }

    if (provider.classes.isEmpty) {
      return EmptyState(
        icon: Icons.class_outlined,
        title: 'No Classes',
        message: 'Create your first class to get started',
        actionLabel: 'Create Class',
        onAction: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadClasses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: provider.classes.length,
        itemBuilder: (context, index) {
          final classModel = provider.classes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
            child: ClassCard(
              classModel: classModel,
              index: index,
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.fadeSlideRoute(
                    ClassDetailsScreen(classModel: classModel),
                  ),
                );
              },
              onCopyCode: () => _copyClassCode(classModel.classCode),
              onShareCode: () => _shareClassCode(classModel.classCode),
            ),
          );
        },
      ),
    );
  }
}
