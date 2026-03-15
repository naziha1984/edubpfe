import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../models/class_model.dart';
import '../providers/teacher_provider.dart';
import '../ui/components/glass_card.dart';
import '../components/student_card.dart';
import '../components/add_student_bottom_sheet.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import 'class_progress_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_live_sessions_screen.dart';
import '../providers/subjects_provider.dart';
import 'package:flutter/services.dart';

/// Écran de détails d'une classe avec Tabs
class ClassDetailsScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailsScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Charger les détails de la classe au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      provider.loadClassDetails(widget.classModel.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copyClassCode() async {
    await Clipboard.setData(ClipboardData(text: widget.classModel.classCode));
    if (mounted) {
      Toast.success(context, 'Class code copied to clipboard!');
    }
  }

  Future<void> _shareClassCode() async {
    // TODO: Implement share functionality
    await _copyClassCode();
  }

  Future<void> _showAddStudentDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStudentBottomSheet(),
    );

    if (result != null && mounted) {
      await _handleAddStudent(result);
    }
  }

  Future<void> _handleAddStudent(String kidId) async {
    final provider = Provider.of<TeacherProvider>(context, listen: false);

    try {
      await provider.addStudentToClass(widget.classModel.id, kidId);
      if (mounted) {
        Toast.success(context, 'Student added successfully!');
      }
    } catch (e) {
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _handleRemoveStudent(String kidId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text(
          'Are you sure you want to remove this student from the class?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<TeacherProvider>(context, listen: false);

      try {
        await provider.removeStudentFromClass(widget.classModel.id, kidId);
        if (mounted) {
          Toast.success(context, 'Student removed successfully!');
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherProvider>(context);
    final classModel = provider.selectedClass ?? widget.classModel;

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
                            classModel.name,
                            style: EduBridgeTypography.headlineSmall.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (classModel.description != null &&
                              classModel.description!.isNotEmpty)
                            Text(
                              classModel.description!,
                              style: EduBridgeTypography.bodySmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Class Code Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EduBridgeTheme.spacingLG,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                  child: Row(
                    children: [
                      Icon(
                        Icons.vpn_key,
                        color: EduBridgeColors.primary,
                      ),
                      const SizedBox(width: EduBridgeTheme.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Code',
                              style: EduBridgeTypography.labelSmall.copyWith(
                                color: EduBridgeColors.textSecondary,
                              ),
                            ),
                            Text(
                              classModel.classCode,
                              style: EduBridgeTypography.titleMedium.copyWith(
                                color: EduBridgeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyClassCode,
                        color: EduBridgeColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _shareClassCode,
                        color: EduBridgeColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: EduBridgeTheme.spacingMD),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: EduBridgeColors.primary,
                unselectedLabelColor: EduBridgeColors.textSecondary,
                indicatorColor: EduBridgeColors.primary,
                tabs: const [
                  Tab(text: 'Students', icon: Icon(Icons.people)),
                  Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
                  Tab(text: 'Live', icon: Icon(Icons.video_call)),
                  Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
                ],
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentsTab(provider, classModel),
                    _buildAssignmentsTab(),
                    _buildLiveSessionsTab(),
                    _buildProgressTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsTab(TeacherProvider provider, ClassModel classModel) {
    if (provider.isLoadingClasses) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    final members = classModel.members ?? [];

    if (members.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No Students',
        message: 'Add students to this class',
        actionLabel: 'Add Student',
        onAction: _showAddStudentDialog,
      );
    }

    return Column(
      children: [
        // Add Student Button
        Padding(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddStudentDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduBridgeColors.primary,
                foregroundColor: EduBridgeColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: EduBridgeTheme.spacingMD,
                ),
              ),
            ),
          ),
        ),
        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: EduBridgeTheme.spacingLG,
            ),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
                child: StudentCard(
                  member: member,
                  onRemove: () => _handleRemoveStudent(member.kidId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    return TeacherAssignmentsScreen(classModel: widget.classModel);
  }

  Widget _buildLiveSessionsTab() {
    return TeacherLiveSessionsScreen(classModel: widget.classModel);
  }

  Widget _buildProgressTab() {
    return ClassProgressScreen(classModel: widget.classModel);
  }
}
