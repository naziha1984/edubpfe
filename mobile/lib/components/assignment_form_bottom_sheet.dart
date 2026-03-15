import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

/// BottomSheet moderne pour créer un assignment
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Note: Pour charger les lessons, il faudrait d'abord sélectionner un subject
    // Pour l'instant, on permet de créer un assignment sans lesson (optionnel)
  }

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

    if (picked != null) {
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: EduBridgeColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = <String, dynamic>{
      'classId': widget.classId,
      'title': _titleController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_selectedLessonId != null) 'lessonId': _selectedLessonId,
      'dueDate': _selectedDueDate!.toIso8601String(),
    };

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: EduBridgeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EduBridgeTheme.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: EduBridgeTheme.spacingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EduBridgeColors.textTertiary,
                borderRadius: BorderRadius.circular(EduBridgeTheme.radiusFull),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nouveau Devoir',
                      style: EduBridgeTypography.headlineSmall.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: EduBridgeColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Form
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
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          hintText: 'e.g., Exercices de mathématiques',
                          prefixIcon: Icon(Icons.assignment),
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
                      // Lesson field (text input for now - can be improved with subject/lesson selector)
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'ID Leçon (optionnel)',
                          hintText: 'Entrez l\'ID de la leçon si disponible',
                          prefixIcon: Icon(Icons.book),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedLessonId = value.trim().isEmpty ? null : value.trim();
                          });
                        },
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Instructions pour les élèves...',
                          prefixIcon: Icon(Icons.description),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Due date picker
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'échéance *',
                            prefixIcon: Icon(Icons.calendar_today),
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
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      // Submit button
                      GradientButton(
                        text: 'Créer le devoir',
                        icon: Icons.add,
                        onPressed: _isLoading ? null : _handleSubmit,
                        isLoading: _isLoading,
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
