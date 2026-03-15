import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

/// BottomSheet moderne pour créer une live session
class LiveSessionFormBottomSheet extends StatefulWidget {
  final String classId;

  const LiveSessionFormBottomSheet({
    super.key,
    required this.classId,
  });

  @override
  State<LiveSessionFormBottomSheet> createState() =>
      _LiveSessionFormBottomSheetState();
}

class _LiveSessionFormBottomSheetState
    extends State<LiveSessionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingUrlController = TextEditingController();
  DateTime? _selectedScheduledDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedScheduledDate ?? now.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedScheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedScheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date et heure'),
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
      'scheduledAt': _selectedScheduledDate!.toIso8601String(),
      'meetingUrl': _meetingUrlController.text.trim(),
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
                      'Nouvelle Session Live',
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
                          hintText: 'e.g., Cours de mathématiques',
                          prefixIcon: Icon(Icons.video_call),
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
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Description de la session...',
                          prefixIcon: Icon(Icons.description),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Meeting URL field
                      TextFormField(
                        controller: _meetingUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de la réunion *',
                          hintText: 'https://meet.google.com/...',
                          prefixIcon: Icon(Icons.link),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'URL de la réunion est requise';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.hasScheme) {
                            return 'Veuillez entrer une URL valide';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Date & Time picker
                      InkWell(
                        onTap: _selectDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date et heure *',
                            prefixIcon: Icon(Icons.calendar_today),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                          child: Text(
                            _selectedScheduledDate != null
                                ? DateFormat('dd MMM yyyy à HH:mm', 'fr_FR')
                                    .format(_selectedScheduledDate!)
                                : 'Sélectionner une date et heure',
                            style: EduBridgeTypography.bodyMedium.copyWith(
                              color: _selectedScheduledDate != null
                                  ? EduBridgeColors.textPrimary
                                  : EduBridgeColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      // Info message
                      Container(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                        decoration: BoxDecoration(
                          color: EduBridgeColors.infoContainer,
                          borderRadius: BorderRadius.circular(
                            EduBridgeTheme.radiusMD,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: EduBridgeColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingSM),
                            Expanded(
                              child: Text(
                                'Les élèves recevront un rappel avant la session',
                                style: EduBridgeTypography.bodySmall.copyWith(
                                  color: EduBridgeColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      // Submit button
                      GradientButton(
                        text: 'Créer la session',
                        icon: Icons.video_call,
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
