import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../ui/theme/edubridge_colors.dart';
import '../../ui/theme/edubridge_typography.dart';
import '../../ui/theme/edubridge_theme.dart';
import '../../components/teacher_approval_badge.dart';
import '../../components/toast.dart';
import '../../utils/error_handler.dart';
import '../../components/cv_upload_field.dart';
import '../../utils/upload_url.dart';
import '../../providers/auth_provider.dart';
import 'dart:typed_data';

class TeacherCvCard extends StatefulWidget {
  const TeacherCvCard({
    super.key,
    this.cvUrl,
    this.approvalStatus,
    this.submittedAt,
  });

  final String? cvUrl;
  final String? approvalStatus;
  final DateTime? submittedAt;

  @override
  State<TeacherCvCard> createState() => _TeacherCvCardState();
}

class _TeacherCvCardState extends State<TeacherCvCard> {
  bool _uploading = false;
  String? _pickedFileName;
  String? _localError;

  bool get _hasCv => (widget.cvUrl ?? '').trim().isNotEmpty;

  String? get _displayFileName {
    if (_pickedFileName != null && _pickedFileName!.trim().isNotEmpty) {
      return _pickedFileName;
    }
    if (_hasCv) {
      final url = widget.cvUrl!.trim();
      final last = url.split('/').where((e) => e.isNotEmpty).lastOrNull;
      return (last ?? 'CV enregistré').toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final approvalStatus = widget.approvalStatus;
    final submittedAt = widget.submittedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'CV enseignant',
                style: EduBridgeTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: EduBridgeColors.textPrimary,
                ),
              ),
            ),
            TeacherApprovalBadge(status: approvalStatus),
          ],
        ),
        const SizedBox(height: EduBridgeTheme.spacingMD),

        if (_localError != null) ...[
          Text(
            _localError!,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
        ],

        if (submittedAt != null) ...[
          Text(
            'Soumis: ${submittedAt.toLocal()}',
            style: EduBridgeTypography.bodySmall.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
        ],

        CvUploadField(
          fileName: _uploading ? 'Upload en cours...' : _displayFileName,
          onPick: () async {
            await _pickAndUpload(context);
          },
          errorText: null,
        ),

        if (_hasCv) ...[
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _uploading
                      ? null
                      : () async {
                          final url = absoluteUploadUrl(widget.cvUrl!);
                          final uri = Uri.parse(url);
                          if (!await canLaunchUrl(uri)) {
                            Toast.error(context, 'Impossible d’ouvrir le CV');
                            return;
                          }
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open CV'),
                ),
              ),
            ],
          ),
        ],

        if (_uploading) ...[
          const SizedBox(height: EduBridgeTheme.spacingMD),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    if (_uploading) return;
    setState(() {
      _localError = null;
    });

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final name = file.name;
    final bytes = file.bytes;
    final size = file.size;

    if (bytes == null || bytes.isEmpty) {
      setState(() => _localError = 'Fichier introuvable (aucune donnée reçue).');
      return;
    }

    final Uint8List cvBytes = bytes;

    final lower = name.toLowerCase();
    final okExt =
        lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx');
    if (!okExt) {
      setState(() => _localError = 'Format invalide. Autorisé: PDF, DOC, DOCX.');
      return;
    }

    const int maxSize = 8 * 1024 * 1024; // 8MB (côté backend)
    if (size > maxSize) {
      setState(() => _localError = 'Fichier trop lourd (max 8MB).');
      return;
    }

    setState(() {
      _uploading = true;
      _pickedFileName = name;
      _localError = null;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final ok = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      () => api.updateTeacherCv(
        cvBytes: cvBytes,
        cvFileName: name,
      ),
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (ok != null) {
      Toast.success(context, 'CV mis à jour. En attente d’approbation.');
      await auth.loadProfile();
    }
  }
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}

