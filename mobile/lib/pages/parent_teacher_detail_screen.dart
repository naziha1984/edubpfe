import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../components/loading.dart';
import '../components/toast.dart';
import '../utils/error_handler.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';

class ParentTeacherDetailScreen extends StatefulWidget {
  const ParentTeacherDetailScreen({
    super.key,
    required this.kidId,
    required this.kidName,
    required this.teacherId,
  });

  final String kidId;
  final String kidName;
  final String teacherId;

  @override
  State<ParentTeacherDetailScreen> createState() => _ParentTeacherDetailScreenState();
}

class _ParentTeacherDetailScreenState extends State<ParentTeacherDetailScreen> {
  Map<String, dynamic>? _teacher;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      () => api.getTeacherPublicDetails(widget.teacherId),
    );
    if (!mounted) return;
    setState(() {
      _teacher = data;
      _loading = false;
    });
  }

  Future<void> _selectTeacher() async {
    setState(() => _submitting = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final ok = await ErrorHandler.handleApiCall<Map<String, dynamic>>(
      context,
      () => api.selectTeacherForKid(
        kidId: widget.kidId,
        teacherId: widget.teacherId,
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok != null) {
      Toast.success(context, 'Enseignant sélectionné pour ${widget.kidName}');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Loading(message: 'Chargement du profil enseignant...'),
      );
    }
    final teacher = _teacher;
    if (teacher == null) {
      return const Scaffold(
        body: Center(child: Text('Enseignant introuvable')),
      );
    }
    final fullName = teacher['fullName']?.toString() ?? '';
    final specialty = teacher['specialty']?.toString() ?? '';
    final bio = teacher['bio']?.toString() ?? '';
    final photo = teacher['profilePhotoUrl']?.toString();
    final rating = (teacher['rating'] is num)
        ? (teacher['rating'] as num).toDouble()
        : 0.0;
    final ratingCount = (teacher['ratingCount'] is num)
        ? (teacher['ratingCount'] as num).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail enseignant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: EduBridgeColors.primary.withOpacity(0.12),
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? const Icon(Icons.school_rounded, size: 36)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: EduBridgeTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: EduBridgeTypography.bodyMedium.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        ratingCount > 0 ? rating.toStringAsFixed(1) : '-',
                        style: EduBridgeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($ratingCount)',
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bio',
                      style: EduBridgeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(bio, style: EduBridgeTypography.bodyMedium),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            GradientButton(
              text: _submitting ? 'Sélection en cours...' : 'Sélectionner pour ${widget.kidName}',
              icon: Icons.check_circle_outline,
              onPressed: _submitting ? null : _selectTeacher,
            ),
          ],
        ),
      ),
    );
  }
}
