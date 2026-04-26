import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../components/teacher_approval_badge.dart';
import 'admin_teacher_request_detail_screen.dart';

class AdminTeacherRequestsScreen extends StatefulWidget {
  const AdminTeacherRequestsScreen({super.key});

  @override
  State<AdminTeacherRequestsScreen> createState() => _AdminTeacherRequestsScreenState();
}

class _AdminTeacherRequestsScreenState extends State<AdminTeacherRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadPendingTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Requests'),
      ),
      body: RefreshIndicator(
        onRefresh: () => admin.loadPendingTeachers(),
        child: admin.isLoadingPendingTeachers
            ? const Center(child: CircularProgressIndicator())
            : admin.pendingTeachersError != null
                ? ErrorState(
                    icon: Icons.error_outline,
                    title: 'Error',
                    message: admin.pendingTeachersError!,
                    onRetry: admin.loadPendingTeachers,
                  )
                : admin.pendingTeachers.isEmpty
                    ? const EmptyState(
                        icon: Icons.verified_user_outlined,
                        title: 'No pending teachers',
                        message: 'All teacher requests are already reviewed.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                        itemCount: admin.pendingTeachers.length,
                        itemBuilder: (context, index) {
                          final t = admin.pendingTeachers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
                            child: GlassCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => AdminTeacherRequestDetailScreen(
                                      teacherId: t.id,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
                                    child: const Icon(Icons.school_rounded),
                                  ),
                                  const SizedBox(width: EduBridgeTheme.spacingMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.fullName,
                                          style: EduBridgeTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          t.email,
                                          style: EduBridgeTypography.bodySmall.copyWith(
                                            color: EduBridgeColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TeacherApprovalBadge(status: t.approvalStatus),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
