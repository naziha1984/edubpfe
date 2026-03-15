import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../providers/teacher_provider.dart';
import '../providers/subjects_provider.dart';
import '../components/student_progress_card.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../utils/error_handler.dart';

/// Écran de suivi de progression avec sélecteur de matière
class ClassProgressScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassProgressScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassProgressScreen> createState() => _ClassProgressScreenState();
}

class _ClassProgressScreenState extends State<ClassProgressScreen> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    // Charger les subjects au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjectsProvider = Provider.of<SubjectsProvider>(context, listen: false);
      if (subjectsProvider.subjects.isEmpty) {
        subjectsProvider.loadSubjects();
      }
    });
  }

  void _loadProgress() {
    if (_selectedSubjectId != null) {
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
      teacherProvider.loadClassSubjectProgress(
        widget.classModel.id,
        _selectedSubjectId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsProvider = Provider.of<SubjectsProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);

    return Column(
      children: [
        // Subject Selector
        Padding(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Subject',
                style: EduBridgeTypography.titleMedium.copyWith(
                  color: EduBridgeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: EduBridgeTheme.spacingSM),
              GlassCard(
                padding: EdgeInsets.zero,
                child: DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    hintText: 'Choose a subject',
                    prefixIcon: const Icon(Icons.subject),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(
                      EduBridgeTheme.spacingMD,
                    ),
                  ),
                  items: subjectsProvider.subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;
                    });
                    if (value != null) {
                      _loadProgress();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _selectedSubjectId == null
              ? const Center(
                  child: EmptyState(
                    icon: Icons.subject_outlined,
                    title: 'Select a Subject',
                    message: 'Choose a subject to view student progress',
                  ),
                )
              : _buildProgressContent(teacherProvider),
        ),
      ],
    );
  }

  Widget _buildProgressContent(TeacherProvider provider) {
    if (provider.isLoadingProgress) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (provider.progressError != null) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Progress',
        message: provider.progressError ?? 'Unknown error',
        onRetry: _loadProgress,
      );
    }

    final progress = provider.classProgress;
    if (progress == null || progress.students.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.trending_up_outlined,
          title: 'No Progress Data',
          message: 'No student progress data available for this subject',
        ),
      );
    }

    return Column(
      children: [
        // Overall Stats
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EduBridgeTheme.spacingLG,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average Score',
                    '${progress.overallStats.averageScore.toStringAsFixed(1)}%',
                    Icons.assessment,
                    EduBridgeColors.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: EduBridgeColors.textTertiary.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completion',
                    '${progress.overallStats.overallCompletionRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    EduBridgeColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: EduBridgeColors.textTertiary.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Students',
                    '${progress.overallStats.totalKids}',
                    Icons.people,
                    EduBridgeColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Sort Options
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EduBridgeTheme.spacingLG,
          ),
          child: Row(
            children: [
              Text(
                'Sort by:',
                style: EduBridgeTypography.labelMedium.copyWith(
                  color: EduBridgeColors.textSecondary,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingSM),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'best',
                      label: Text('Best'),
                      icon: Icon(Icons.arrow_upward, size: 16),
                    ),
                    ButtonSegment(
                      value: 'worst',
                      label: Text('Worst'),
                      icon: Icon(Icons.arrow_downward, size: 16),
                    ),
                    ButtonSegment(
                      value: 'name',
                      label: Text('Name'),
                      icon: Icon(Icons.sort_by_alpha, size: 16),
                    ),
                  ],
                  selected: {provider.sortBy},
                  onSelectionChanged: (Set<String> newSelection) {
                    provider.setSortBy(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),
        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: EduBridgeTheme.spacingLG,
            ),
            itemCount: provider.sortedStudents.length,
            itemBuilder: (context, index) {
              final student = provider.sortedStudents[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
                child: StudentProgressCard(
                  student: student,
                  index: index,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: EduBridgeTheme.spacingXS),
        Text(
          value,
          style: EduBridgeTypography.titleMedium.copyWith(
            color: EduBridgeColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: EduBridgeTypography.labelSmall.copyWith(
            color: EduBridgeColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
