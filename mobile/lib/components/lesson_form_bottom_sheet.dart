import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lesson_model.dart';
import '../models/subject_model.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

class LessonFormResult {
  final LessonModel lesson;
  final List<PlatformFile> files;

  const LessonFormResult({
    required this.lesson,
    this.files = const [],
  });
}

/// BottomSheet moderne pour créer/éditer une lesson avec editor et preview
class LessonFormBottomSheet extends StatefulWidget {
  final LessonModel? lesson; // null = create, non-null = edit
  final List<SubjectModel> subjects; // Liste des subjects pour le dropdown
  final String? initialSubjectId; // Subject ID initial (pour create depuis subject)

  const LessonFormBottomSheet({
    super.key,
    this.lesson,
    required this.subjects,
    this.initialSubjectId,
  });

  @override
  State<LessonFormBottomSheet> createState() =>
      _LessonFormBottomSheetState();
}

class _LessonFormBottomSheetState extends State<LessonFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _orderController = TextEditingController();
  final _levelController = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedLanguage;
  bool _isActive = true;
  bool _isLoading = false;
  bool _showPreview = false;
  final List<PlatformFile> _pickedFiles = [];

  @override
  void initState() {
    super.initState();
    // Si on édite, pré-remplir les champs
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _descriptionController.text = widget.lesson!.description ?? '';
      _contentController.text = widget.lesson!.content ?? '';
      _orderController.text = widget.lesson!.order?.toString() ?? '';
      _levelController.text = widget.lesson!.level ?? '';
      _selectedSubjectId = widget.lesson!.subjectId;
      _selectedLanguage = widget.lesson!.language;
      _isActive = widget.lesson!.isActive;
    } else if (widget.initialSubjectId != null) {
      _selectedSubjectId = widget.initialSubjectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _orderController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFiles.addAll(result.files);
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

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: EduBridgeColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Le parent doit gérer l'appel API et la fermeture
    final lesson = LessonModel(
      id: widget.lesson?.id ?? '',
      subjectId: _selectedSubjectId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      content: _contentController.text.trim().isEmpty
          ? null
          : _contentController.text.trim(),
      order: _orderController.text.trim().isEmpty
          ? null
          : int.tryParse(_orderController.text.trim()),
      level: _levelController.text.trim().isEmpty
          ? null
          : _levelController.text.trim(),
      language: _selectedLanguage,
      isActive: _isActive,
    );

    Navigator.pop(
      context,
      LessonFormResult(lesson: lesson, files: List.from(_pickedFiles)),
    );
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
                    child: Hero(
                      tag: widget.lesson != null
                          ? 'lesson_title_${widget.lesson!.id}'
                          : 'lesson_form_title',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.lesson == null
                              ? 'Create Lesson'
                              : 'Edit Lesson',
                          style: EduBridgeTypography.headlineSmall.copyWith(
                            color: EduBridgeColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
            // Tabs: Editor / Preview
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: EduBridgeTheme.spacingLG,
              ),
              decoration: BoxDecoration(
                color: EduBridgeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      'Editor',
                      Icons.edit,
                      !_showPreview,
                      () => setState(() => _showPreview = false),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'Preview',
                      Icons.preview,
                      _showPreview,
                      () => setState(() => _showPreview = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EduBridgeTheme.spacingMD),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: EduBridgeTheme.spacingLG,
                ),
                child: _showPreview ? _buildPreview() : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: EduBridgeTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? EduBridgeColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? EduBridgeColors.textOnPrimary
                  : EduBridgeColors.textSecondary,
            ),
            const SizedBox(width: EduBridgeTheme.spacingXS),
            Text(
              label,
              style: EduBridgeTypography.labelMedium.copyWith(
                color: isSelected
                    ? EduBridgeColors.textOnPrimary
                    : EduBridgeColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subject dropdown
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: InputDecoration(
              labelText: 'Subject *',
              prefixIcon: const Icon(Icons.subject),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            items: widget.subjects.map((subject) {
              return DropdownMenuItem(
                value: subject.id,
                child: Text(subject.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubjectId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a subject';
              }
              return null;
            },
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g., Introduction to Algebra',
              prefixIcon: Icon(Icons.title),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Order field
          TextFormField(
            controller: _orderController,
            decoration: const InputDecoration(
              labelText: 'Order',
              hintText: 'e.g., 1',
              prefixIcon: Icon(Icons.sort),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.trim().isNotEmpty &&
                  int.tryParse(value.trim()) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Level field
          TextFormField(
            controller: _levelController,
            decoration: const InputDecoration(
              labelText: 'Level',
              hintText: 'e.g., Beginner, Intermediate, Advanced',
              prefixIcon: Icon(Icons.trending_up),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Language field (dropdown)
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Language',
              prefixIcon: Icon(Icons.language),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'fr', child: Text('French')),
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              DropdownMenuItem(value: 'es', child: Text('Spanish')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value;
              });
            },
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Ajouter des fichiers (PDF, Word, image, etc.)'),
          ),
          if (_pickedFiles.isNotEmpty) ...[
            const SizedBox(height: EduBridgeTheme.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_pickedFiles.length, (index) {
                final file = _pickedFiles[index];
                return Chip(
                  label: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () => _removeFile(index),
                );
              }),
            ),
          ],
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the lesson',
              prefixIcon: Icon(Icons.description),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Content field (textarea)
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Lesson content...',
              prefixIcon: Icon(Icons.article),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
          // Active toggle
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            decoration: BoxDecoration(
              color: EduBridgeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
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
                        style: EduBridgeTypography.labelMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: EduBridgeTypography.bodySmall.copyWith(
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
            text: widget.lesson == null ? 'Create' : 'Update',
            icon: widget.lesson == null ? Icons.add : Icons.save,
            onPressed: _isLoading ? null : _handleSubmit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: EduBridgeTheme.spacingLG),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subject preview
        if (_selectedSubjectId != null) ...[
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            decoration: BoxDecoration(
              color: EduBridgeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            ),
            child: Row(
              children: [
                const Icon(Icons.subject, color: EduBridgeColors.primary),
                const SizedBox(width: EduBridgeTheme.spacingSM),
                Text(
                  'Subject: ${widget.subjects.firstWhere((s) => s.id == _selectedSubjectId, orElse: () => widget.subjects.first).name}',
                  style: EduBridgeTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
        ],
        // Title preview
        if (_titleController.text.isNotEmpty) ...[
          Text(
            _titleController.text,
            style: EduBridgeTypography.headlineSmall.copyWith(
              color: EduBridgeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
        ],
        // Description preview
        if (_descriptionController.text.isNotEmpty) ...[
          Text(
            _descriptionController.text,
            style: EduBridgeTypography.bodyMedium.copyWith(
              color: EduBridgeColors.textSecondary,
            ),
          ),
          const SizedBox(height: EduBridgeTheme.spacingMD),
        ],
        // Content preview
        if (_contentController.text.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
            decoration: BoxDecoration(
              color: EduBridgeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            ),
            child: Text(
              _contentController.text,
              style: EduBridgeTypography.bodyMedium,
            ),
          ),
        ],
        // Order preview
        if (_orderController.text.isNotEmpty) ...[
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
            decoration: BoxDecoration(
              color: EduBridgeColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusSM),
            ),
            child: Text(
              'Order: ${_orderController.text}',
              style: EduBridgeTypography.bodySmall,
            ),
          ),
        ],
        // Level preview
        if (_levelController.text.isNotEmpty) ...[
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
            decoration: BoxDecoration(
              color: EduBridgeColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusSM),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, size: 16, color: EduBridgeColors.secondary),
                const SizedBox(width: EduBridgeTheme.spacingXS),
                Text(
                  'Level: ${_levelController.text}',
                  style: EduBridgeTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
        // Language preview
        if (_selectedLanguage != null) ...[
          const SizedBox(height: EduBridgeTheme.spacingMD),
          Container(
            padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
            decoration: BoxDecoration(
              color: EduBridgeColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(EduBridgeTheme.radiusSM),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, size: 16, color: EduBridgeColors.accent),
                const SizedBox(width: EduBridgeTheme.spacingXS),
                Text(
                  'Language: ${_selectedLanguage == 'en' ? 'English' : _selectedLanguage == 'fr' ? 'French' : _selectedLanguage == 'ar' ? 'Arabic' : _selectedLanguage == 'es' ? 'Spanish' : _selectedLanguage}',
                  style: EduBridgeTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
        // Status preview
        const SizedBox(height: EduBridgeTheme.spacingMD),
        Container(
          padding: const EdgeInsets.all(EduBridgeTheme.spacingSM),
          decoration: BoxDecoration(
            color: _isActive
                ? EduBridgeColors.success.withOpacity(0.1)
                : EduBridgeColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusSM),
          ),
          child: Text(
            'Status: ${_isActive ? 'Active' : 'Inactive'}',
            style: EduBridgeTypography.bodySmall.copyWith(
              color: _isActive
                  ? EduBridgeColors.success
                  : EduBridgeColors.error,
            ),
          ),
        ),
        const SizedBox(height: EduBridgeTheme.spacingXL),
        // Submit button
        GradientButton(
          text: widget.lesson == null ? 'Create' : 'Update',
          icon: widget.lesson == null ? Icons.add : Icons.save,
          onPressed: _isLoading ? null : _handleSubmit,
          isLoading: _isLoading,
        ),
        const SizedBox(height: EduBridgeTheme.spacingLG),
      ],
    );
  }
}
