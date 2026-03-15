import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

/// BottomSheet moderne pour créer/éditer un subject
class SubjectFormBottomSheet extends StatefulWidget {
  final SubjectModel? subject; // null = create, non-null = edit

  const SubjectFormBottomSheet({
    super.key,
    this.subject,
  });

  @override
  State<SubjectFormBottomSheet> createState() =>
      _SubjectFormBottomSheetState();
}

class _SubjectFormBottomSheetState extends State<SubjectFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si on édite, pré-remplir les champs
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _descriptionController.text = widget.subject!.description ?? '';
      _codeController.text = widget.subject!.code ?? '';
      _isActive = widget.subject!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Le parent doit gérer l'appel API et la fermeture
    final subject = SubjectModel(
      id: widget.subject?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      code: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      isActive: _isActive,
    );

    Navigator.pop(context, subject);
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
                      widget.subject == null
                          ? 'Create Subject'
                          : 'Edit Subject',
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
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          hintText: 'e.g., Mathematics',
                          prefixIcon: const Icon(Icons.subject),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Code field
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Code',
                          hintText: 'e.g., MATH',
                          prefixIcon: const Icon(Icons.code),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the subject',
                          prefixIcon: const Icon(Icons.description),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      // Active toggle
                      Container(
                        padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
                        decoration: BoxDecoration(
                          color: EduBridgeColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            EduBridgeTheme.radiusMD,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.toggle_on,
                              color: EduBridgeColors.primary,
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingSM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: EduBridgeTypography.labelMedium
                                        .copyWith(
                                      color: EduBridgeColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _isActive ? 'Active' : 'Inactive',
                                    style: EduBridgeTypography.bodySmall
                                        .copyWith(
                                      color: EduBridgeColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              activeColor: EduBridgeColors.success,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      // Submit button
                      GradientButton(
                        text: widget.subject == null ? 'Create' : 'Update',
                        icon: widget.subject == null
                            ? Icons.add
                            : Icons.save,
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
