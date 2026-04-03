import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

/// Résultat du formulaire : champs JSON + fichiers à envoyer en multipart.
class AssignmentFormResult {
  final Map<String, dynamic> data;
  final List<PlatformFile> files;

  const AssignmentFormResult({
    required this.data,
    this.files = const [],
  });
}

/// Bottom sheet : nouveau devoir + pièces jointes (PDF, images, Word, vidéos, etc.)
class AssignmentFormBottomSheet extends StatefulWidget {
  final String classId;

  const AssignmentFormBottomSheet({
    super.key,
    required this.classId,
  });

  @override
  State<AssignmentFormBottomSheet> createState() =>
      _AssignmentFormBottomSheetState();
}

class _AssignmentFormBottomSheetState
    extends State<AssignmentFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  String? _selectedLessonId;
  final List<PlatformFile> _pickedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final f in result.files) {
          _pickedFiles.add(f);
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _pickedFiles.removeAt(index));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis une date d\'échéance'),
          backgroundColor: EduBridgeColors.error,
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'classId': widget.classId,
      'title': _titleController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_selectedLessonId != null && _selectedLessonId!.trim().isNotEmpty)
        'lessonId': _selectedLessonId,
      'dueDate': _selectedDueDate!.toIso8601String(),
    };

    if (!mounted) return;
    Navigator.pop(
      context,
      AssignmentFormResult(data: data, files: List.from(_pickedFiles)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            EduBridgeColors.secondaryContainer.withOpacity(0.5),
            EduBridgeColors.surface,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EduBridgeTheme.radiusXL + 8),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: EduBridgeTheme.spacingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EduBridgeColors.textTertiary,
                borderRadius: BorderRadius.circular(EduBridgeTheme.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EduBridgeColors.accentContainer,
                      borderRadius:
                          BorderRadius.circular(EduBridgeTheme.radiusMD),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: EduBridgeColors.accentDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveau devoir',
                          style:
                              EduBridgeTypography.headlineSmall.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ajoute des fichiers pour les élèves',
                          style: EduBridgeTypography.bodySmall.copyWith(
                            color: EduBridgeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: EduBridgeColors.textSecondary,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: EduBridgeTheme.spacingLG,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          hintText: 'Ex. Exercices de maths',
                          prefixIcon: Icon(Icons.edit_rounded),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre est requis';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'ID leçon (optionnel)',
                          hintText: 'Coller l’ID si tu en as un',
                          prefixIcon: Icon(Icons.menu_book_rounded),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedLessonId = value.trim().isEmpty
                                ? null
                                : value.trim();
                          });
                        },
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Consignes, liens utiles...',
                          prefixIcon: Icon(Icons.notes_rounded),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      InkWell(
                        onTap: _selectDueDate,
                        borderRadius:
                            BorderRadius.circular(EduBridgeTheme.radiusMD),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'échéance *',
                            prefixIcon: Icon(Icons.event_rounded),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                          child: Text(
                            _selectedDueDate != null
                                ? DateFormat('dd MMM yyyy à HH:mm', 'fr_FR')
                                    .format(_selectedDueDate!)
                                : 'Sélectionner une date',
                            style: EduBridgeTypography.bodyMedium.copyWith(
                              color: _selectedDueDate != null
                                  ? EduBridgeColors.textPrimary
                                  : EduBridgeColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingLG),
                      Text(
                        'Fichiers (PDF, Word, images, vidéos...)',
                        style: EduBridgeTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingSM),
                      Material(
                        color: EduBridgeColors.accentContainer.withOpacity(0.35),
                        borderRadius:
                            BorderRadius.circular(EduBridgeTheme.radiusLG),
                        child: InkWell(
                          onTap: _pickFiles,
                          borderRadius:
                              BorderRadius.circular(EduBridgeTheme.radiusLG),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                EduBridgeTheme.radiusLG,
                              ),
                              border: Border.all(
                                color: EduBridgeColors.accent.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_rounded,
                                        color: EduBridgeColors.secondaryDark,
                                        size: 28),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Touche pour ajouter des fichiers',
                                        textAlign: TextAlign.center,
                                        style: EduBridgeTypography.bodyMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: EduBridgeColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Plusieurs fichiers possibles · max ~80 Mo chacun',
                                  style: EduBridgeTypography.labelSmall.copyWith(
                                    color: EduBridgeColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_pickedFiles.isNotEmpty) ...[
                        const SizedBox(height: EduBridgeTheme.spacingMD),
                        ...List.generate(_pickedFiles.length, (index) {
                          final f = _pickedFiles[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  EduBridgeColors.primaryContainer,
                              child: Icon(
                                Icons.insert_drive_file_rounded,
                                color: EduBridgeColors.primaryDark,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: EduBridgeTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: f.size > 0
                                ? Text(
                                    '${(f.size / 1024).toStringAsFixed(1)} Ko',
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => _removeFile(index),
                              color: EduBridgeColors.error,
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      GradientButton(
                        text: 'Créer le devoir',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: _handleSubmit,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingLG),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
