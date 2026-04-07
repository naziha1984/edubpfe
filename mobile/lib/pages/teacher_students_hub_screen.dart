import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import '../utils/app_router.dart';
import '../components/add_student_bottom_sheet.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import 'class_details_screen.dart';
import '../ui/transitions/page_transitions.dart';

/// Hub to add students: list classes and shortcut to add by kid ID.
class TeacherStudentsHubScreen extends StatefulWidget {
  const TeacherStudentsHubScreen({super.key});

  @override
  State<TeacherStudentsHubScreen> createState() =>
      _TeacherStudentsHubScreenState();
}

class _TeacherStudentsHubScreenState extends State<TeacherStudentsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<TeacherProvider>(context, listen: false);
      p.loadClasses();
    });
  }

  Future<void> _addStudentToClass(String classId) async {
    final kidId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddStudentBottomSheet(),
    );
    if (!mounted || kidId == null || kidId.isEmpty) return;

    final provider = Provider.of<TeacherProvider>(context, listen: false);
    final ok = await ErrorHandler.handleApiCall<bool>(
      context,
      () async {
        await provider.addStudentToClass(classId, kidId.trim());
        return true;
      },
    );
    if (ok == true && mounted) {
      Toast.success(context, 'Student added successfully!');
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

    final provider = Provider.of<TeacherProvider>(context);

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
                            'Students',
                            style: EduBridgeTypography.headlineMedium.copyWith(
                              color: EduBridgeColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Use the child ID from the parent app, or open a class.',
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(context, provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TeacherProvider provider) {
    if (provider.isLoadingClasses && provider.classes.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 88,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (provider.classesError != null && provider.classes.isEmpty) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error loading classes',
        message: provider.classesError ?? 'Unknown error',
        onRetry: () => provider.loadClasses(),
      );
    }

    if (provider.classes.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No classes yet',
        message:
            'Create a class first, then add students here or from class details.',
        actionLabel: 'Back',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadClasses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          EduBridgeTheme.spacingLG,
          0,
          EduBridgeTheme.spacingLG,
          EduBridgeTheme.spacingLG,
        ),
        itemCount: provider.classes.length,
        itemBuilder: (context, index) {
          final c = provider.classes[index];
          final n = c.members?.length ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
            child: GlassCard(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.fadeSlideRoute(
                    ClassDetailsScreen(classModel: c, initialTabIndex: 0),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: EduBridgeColors.secondary.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(EduBridgeTheme.radiusMD),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: EduBridgeColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: EduBridgeTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: EduBridgeTypography.titleMedium.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$n student${n == 1 ? '' : 's'}',
                          style: EduBridgeTypography.bodySmall.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add student',
                    icon: const Icon(Icons.person_add_alt_1),
                    color: EduBridgeColors.primary,
                    onPressed: () => _addStudentToClass(c.id),
                  ),
                  const Icon(
                    Icons.chevron_right,
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
