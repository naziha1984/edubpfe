import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/assignments_provider.dart';
import '../components/assignment_card.dart';
import '../models/assignment_model.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';

/// Écran pour afficher les assignments d'un kid
class KidAssignmentsScreen extends StatefulWidget {
  const KidAssignmentsScreen({super.key});

  @override
  State<KidAssignmentsScreen> createState() => _KidAssignmentsScreenState();
}

class _KidAssignmentsScreenState extends State<KidAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les assignments au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AssignmentsProvider>(context, listen: false);
      provider.loadKidAssignments();
    });
  }

  Future<void> _handleStartAssignment(String assignmentId) async {
    final provider = Provider.of<AssignmentsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => provider.startAssignment(assignmentId),
    );

    if (success == true && mounted) {
      Toast.success(context, 'Devoir démarré!');
    }
  }

  Future<void> _handleSubmitAssignment(String assignmentId) async {
    // TODO: Intégrer avec le quiz si nécessaire
    final provider = Provider.of<AssignmentsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => provider.submitAssignment(assignmentId),
    );

    if (success == true && mounted) {
      Toast.success(context, 'Devoir soumis avec succès!');
    }
  }

  void _showActionDialog(AssignmentModel assignment) {
    final submission = assignment.submission;
    final status = submission?.status;

    if (status == SubmissionStatus.completed) {
      // Déjà terminé
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          assignment.title,
          style: EduBridgeTypography.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignment.description != null &&
                assignment.description!.isNotEmpty) ...[
              Text(
                assignment.description!,
                style: EduBridgeTypography.bodyMedium,
              ),
              const SizedBox(height: EduBridgeTheme.spacingMD),
            ],
            if (status == null || status == SubmissionStatus.assigned)
              Text(
                'Voulez-vous démarrer ce devoir?',
                style: EduBridgeTypography.bodyMedium,
              )
            else if (status == SubmissionStatus.inProgress)
              Text(
                'Voulez-vous soumettre ce devoir?',
                style: EduBridgeTypography.bodyMedium,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (status == null || status == SubmissionStatus.assigned) {
                _handleStartAssignment(assignment.id);
              } else if (status == SubmissionStatus.inProgress) {
                _handleSubmitAssignment(assignment.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EduBridgeColors.primary,
            ),
            child: Text(
              status == null || status == SubmissionStatus.assigned
                  ? 'Démarrer'
                  : 'Soumettre',
              style: const TextStyle(color: EduBridgeColors.textOnPrimary),
            ),
          ),
        ],
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
                      child: Text(
                        'Mes Devoirs',
                        style: EduBridgeTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EduBridgeColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: provider.isLoadingKidAssignments
                    ? const LoadingSkeleton(width: double.infinity, height: 200)
                    : provider.kidAssignmentsError != null
                        ? ErrorState(
                            message: provider.kidAssignmentsError!,
                            onRetry: () {
                              provider.loadKidAssignments();
                            },
                          )
                        : provider.kidAssignments.isEmpty
                            ? EmptyState(
                                icon: Icons.assignment_outlined,
                                title: 'Aucun devoir',
                                message:
                                    'Vous n\'avez pas encore de devoirs assignés',
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await provider.loadKidAssignments();
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    EduBridgeTheme.spacingLG,
                                  ),
                                  itemCount: provider.kidAssignments.length,
                                  itemBuilder: (context, index) {
                                    final assignment =
                                        provider.kidAssignments[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: EduBridgeTheme.spacingMD,
                                      ),
                                      child: AssignmentCard(
                                        assignment: assignment,
                                        index: index,
                                        showSubmissionStatus: true,
                                        onTap: () =>
                                            _showActionDialog(assignment),
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
    );
  }
}
