import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/assignments_provider.dart';
import '../models/assignment_model.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';

/// Écran pour afficher les soumissions d'un assignment (teacher)
class AssignmentSubmissionsScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les soumissions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AssignmentsProvider>(context, listen: false);
      provider.loadAssignmentSubmissions(widget.assignmentId);
    });
  }

  Color _getStatusColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.assigned:
        return EduBridgeColors.warning;
      case SubmissionStatus.inProgress:
        return EduBridgeColors.info;
      case SubmissionStatus.completed:
        return EduBridgeColors.success;
    }
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
                        'Soumissions',
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
                child: provider.isLoadingSubmissions
                    ? const LoadingSkeleton(width: double.infinity, height: 200)
                    : provider.submissionsError != null
                        ? ErrorState(
                            message: provider.submissionsError!,
                            onRetry: () {
                              provider.loadAssignmentSubmissions(
                                  widget.assignmentId);
                            },
                          )
                        : provider.submissions.isEmpty
                            ? EmptyState(
                                icon: Icons.assignment_outlined,
                                title: 'Aucune soumission',
                                message:
                                    'Aucun élève n\'a encore soumis ce devoir',
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await provider.loadAssignmentSubmissions(
                                      widget.assignmentId);
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    EduBridgeTheme.spacingLG,
                                  ),
                                  itemCount: provider.submissions.length,
                                  itemBuilder: (context, index) {
                                    final submission =
                                        provider.submissions[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: EduBridgeTheme.spacingMD,
                                      ),
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(
                                          EduBridgeTheme.spacingMD,
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  EduBridgeColors.primary
                                                      .withOpacity(0.2),
                                              child: Text(
                                                submission.kidName.isNotEmpty
                                                    ? submission.kidName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: EduBridgeTypography
                                                    .titleMedium
                                                    .copyWith(
                                                  color: EduBridgeColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: EduBridgeTheme.spacingMD),
                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    submission.kidName,
                                                    style: EduBridgeTypography
                                                        .titleMedium
                                                        .copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: EduBridgeColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              EduBridgeTheme
                                                                  .spacingSM,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _getStatusColor(
                                                                  submission
                                                                      .status)
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            EduBridgeTheme
                                                                .radiusSM,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          submission.status
                                                              .displayName,
                                                          style: EduBridgeTypography
                                                              .labelSmall
                                                              .copyWith(
                                                            color: _getStatusColor(
                                                                submission
                                                                    .status),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      if (submission.score !=
                                                          null) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        Icon(
                                                          Icons.star,
                                                          size: 16,
                                                          color: EduBridgeColors
                                                              .warning,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${submission.score!.toStringAsFixed(1)}/100',
                                                          style: EduBridgeTypography
                                                              .bodySmall
                                                              .copyWith(
                                                            color: EduBridgeColors
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (submission.startedAt !=
                                                      null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Démarré: ${DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(submission.startedAt!)}',
                                                      style: EduBridgeTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: EduBridgeColors
                                                            .textTertiary,
                                                      ),
                                                    ),
                                                  ],
                                                  if (submission.submittedAt !=
                                                      null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Soumis: ${DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(submission.submittedAt!)}',
                                                      style: EduBridgeTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: EduBridgeColors
                                                            .textTertiary,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
