import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../models/class_model.dart';
import '../providers/assignments_provider.dart';
import '../components/assignment_card.dart';
import '../components/assignment_form_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import 'assignment_submissions_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Écran de gestion des assignments d'une classe (teacher)
class TeacherAssignmentsScreen extends StatefulWidget {
  final ClassModel classModel;

  const TeacherAssignmentsScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les assignments au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AssignmentsProvider>(context, listen: false);
      provider.loadAssignmentsByClass(widget.classModel.id);
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignmentFormBottomSheet(
        classId: widget.classModel.id,
      ),
    );

    if (result != null && mounted) {
      await _handleCreate(result);
    }
  }

  Future<void> _handleCreate(Map<String, dynamic> data) async {
    final provider = Provider.of<AssignmentsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => provider.createAssignment(data),
    );

    if (success == true && mounted) {
      Toast.success(context, 'Assignment created successfully!');
    }
  }

  void _viewSubmissions(assignmentId) {
    Navigator.push(
      context,
      PageTransitions.fadeSlideRoute(
        AssignmentSubmissionsScreen(assignmentId: assignmentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssignmentsProvider>(context);

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devoirs',
                            style: EduBridgeTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: EduBridgeColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.classModel.name,
                            style: EduBridgeTypography.bodyMedium.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
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
                child: provider.isLoadingAssignments
                    ? const LoadingSkeleton(width: double.infinity, height: 200)
                    : provider.assignmentsError != null
                        ? ErrorState(
                            message: provider.assignmentsError!,
                            onRetry: () {
                              provider.loadAssignmentsByClass(
                                  widget.classModel.id);
                            },
                          )
                        : provider.assignments.isEmpty
                            ? EmptyState(
                                icon: Icons.assignment_outlined,
                                title: 'Aucun devoir',
                                message:
                                    'Créez votre premier devoir pour cette classe',
                                actionLabel: 'Créer un devoir',
                                onAction: _showCreateDialog,
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await provider.loadAssignmentsByClass(
                                      widget.classModel.id);
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    EduBridgeTheme.spacingLG,
                                  ),
                                  itemCount: provider.assignments.length,
                                  itemBuilder: (context, index) {
                                    final assignment =
                                        provider.assignments[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: EduBridgeTheme.spacingMD,
                                      ),
                                      child: AssignmentCard(
                                        assignment: assignment,
                                        index: index,
                                        onTap: () =>
                                            _viewSubmissions(assignment.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: EduBridgeColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau devoir'),
      ),
    );
  }
}
