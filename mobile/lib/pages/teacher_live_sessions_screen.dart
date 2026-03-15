import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../models/class_model.dart';
import '../providers/live_sessions_provider.dart';
import '../components/live_session_card.dart';
import '../components/live_session_form_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';

/// Écran de gestion des live sessions d'une classe (teacher)
class TeacherLiveSessionsScreen extends StatefulWidget {
  final ClassModel classModel;

  const TeacherLiveSessionsScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<TeacherLiveSessionsScreen> createState() =>
      _TeacherLiveSessionsScreenState();
}

class _TeacherLiveSessionsScreenState
    extends State<TeacherLiveSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les live sessions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<LiveSessionsProvider>(context, listen: false);
      provider.loadLiveSessionsByClass(widget.classModel.id);
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiveSessionFormBottomSheet(
        classId: widget.classModel.id,
      ),
    );

    if (result != null && mounted) {
      await _handleCreate(result);
    }
  }

  Future<void> _handleCreate(Map<String, dynamic> data) async {
    final provider =
        Provider.of<LiveSessionsProvider>(context, listen: false);

    final success = await ErrorHandler.handleApiCall(
      context,
      () => provider.createLiveSession(widget.classModel.id, data),
    );

    if (success == true && mounted) {
      Toast.success(context, 'Session live créée avec succès!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LiveSessionsProvider>(context);

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
                            'Sessions Live',
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
                child: provider.isLoadingLiveSessions
                    ? const LoadingSkeleton(width: double.infinity, height: 200)
                    : provider.liveSessionsError != null
                        ? ErrorState(
                            message: provider.liveSessionsError!,
                            onRetry: () {
                              provider.loadLiveSessionsByClass(
                                  widget.classModel.id);
                            },
                          )
                        : provider.liveSessions.isEmpty
                            ? EmptyState(
                                icon: Icons.video_call_outlined,
                                title: 'Aucune session live',
                                message:
                                    'Créez votre première session live pour cette classe',
                                actionLabel: 'Créer une session',
                                onAction: _showCreateDialog,
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await provider.loadLiveSessionsByClass(
                                      widget.classModel.id);
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    EduBridgeTheme.spacingLG,
                                  ),
                                  itemCount: provider.liveSessions.length,
                                  itemBuilder: (context, index) {
                                    final session =
                                        provider.liveSessions[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: EduBridgeTheme.spacingMD,
                                      ),
                                      child: LiveSessionCard(
                                        session: session,
                                        index: index,
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
        icon: const Icon(Icons.video_call),
        label: const Text('Nouvelle session'),
      ),
    );
  }
}
