import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/admin_provider.dart';
import '../services/admin_service.dart';
import '../services/api_service.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/glass_card.dart';
import '../components/teacher_approval_badge.dart';
import '../components/toast.dart';

class AdminTeacherRequestDetailScreen extends StatefulWidget {
  const AdminTeacherRequestDetailScreen({
    super.key,
    required this.teacherId,
  });

  final String teacherId;

  @override
  State<AdminTeacherRequestDetailScreen> createState() =>
      _AdminTeacherRequestDetailScreenState();
}

class _AdminTeacherRequestDetailScreenState
    extends State<AdminTeacherRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          .loadTeacherDetails(widget.teacherId);
    });
  }

  Future<void> _openCv(String? cvUrl) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final adminService = AdminService(api);
    final resolved = adminService.resolveFileUrl(cvUrl);
    if (resolved.isEmpty) {
      Toast.error(context, 'CV introuvable');
      return;
    }
    final uri = Uri.parse(resolved);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      Toast.error(context, 'Impossible d’ouvrir le CV');
    }
  }

  Future<void> _accept() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final ok = await admin.acceptTeacher(widget.teacherId);
    if (!mounted) return;
    if (ok) {
      Toast.success(context, 'Enseignant accepté');
    } else {
      Toast.error(context, admin.teacherDecisionError ?? 'Action échouée');
    }
  }

  Future<void> _reject() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject teacher'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional rejection reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    if (!mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final ok = await admin.rejectTeacher(widget.teacherId, reason: reason);
    if (!mounted) return;
    if (ok) {
      Toast.success(context, 'Enseignant rejeté');
    } else {
      Toast.error(context, admin.teacherDecisionError ?? 'Action échouée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final t = admin.teacherDetails;
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Request Detail')),
      body: admin.isLoadingTeacherDetails
          ? const Center(child: CircularProgressIndicator())
          : t == null
              ? Center(
                  child: Text(
                    admin.teacherDetailsError ?? 'Teacher not found',
                    style: EduBridgeTypography.bodyLarge,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t.fullName,
                                  style: EduBridgeTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TeacherApprovalBadge(status: t.approvalStatus),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(t.email, style: EduBridgeTypography.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Submitted: ${t.submittedAt?.toLocal().toString() ?? '-'}',
                              style: EduBridgeTypography.bodySmall,
                            ),
                            if ((t.rejectionReason ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${t.rejectionReason}',
                                style: EduBridgeTypography.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _openCv(t.cvUrl),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Open CV'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingLG),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: admin.isSubmittingTeacherDecision ? null : _accept,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: admin.isSubmittingTeacherDecision ? null : _reject,
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
