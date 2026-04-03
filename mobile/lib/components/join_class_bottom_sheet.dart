import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/kids_provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';
import '../utils/error_handler.dart';

/// Met en majuscules et limite aux caractères du code classe.
class _ClassCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final capped = t.length > 10 ? t.substring(0, 10) : t;
    return TextEditingValue(
      text: capped,
      selection: TextSelection.collapsed(offset: capped.length),
    );
  }
}

/// Feuille pour saisir le code classe et choisir l'enfant à inscrire (compte parent).
class JoinClassBottomSheet extends StatefulWidget {
  final List<dynamic> kids;

  const JoinClassBottomSheet({super.key, required this.kids});

  @override
  State<JoinClassBottomSheet> createState() => _JoinClassBottomSheetState();
}

class _JoinClassBottomSheetState extends State<JoinClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _selectedKidId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kids.isNotEmpty) {
      _selectedKidId = widget.kids.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKidId == null || _selectedKidId!.isEmpty) {
      ErrorHandler.showError(context, Exception('Choisis un enfant'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<KidsProvider>(context, listen: false).joinClass(
        kidId: _selectedKidId!,
        classCode: _codeController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  Expanded(
                    child: Text(
                      'Rejoindre une classe',
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
                      Text(
                        'Demande le code à l’enseignant (ex. LSTUWO), puis choisis l’enfant concerné.',
                        style: EduBridgeTypography.bodyMedium.copyWith(
                          color: EduBridgeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingLG),
                      DropdownButtonFormField<String>(
                        value: _selectedKidId,
                        decoration: InputDecoration(
                          labelText: 'Enfant',
                          prefixIcon: const Icon(Icons.child_care_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              EduBridgeTheme.radiusMD,
                            ),
                          ),
                        ),
                        items: widget.kids.map((k) {
                          final id = k['id']?.toString() ?? '';
                          final name =
                              '${k['firstName'] ?? ''} ${k['lastName'] ?? ''}'
                                  .trim();
                          return DropdownMenuItem(
                            value: id,
                            child: Text(name.isEmpty ? id : name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedKidId = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Choisis un enfant' : null,
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      TextFormField(
                        controller: _codeController,
                        inputFormatters: [
                          _ClassCodeInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Code de la classe',
                          hintText: 'LSTUWO',
                          prefixIcon: const Icon(Icons.key_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              EduBridgeTheme.radiusMD,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Entre le code';
                          }
                          if (value.trim().length < 4) {
                            return 'Code trop court';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingXL),
                      GradientButton(
                        text: 'Rejoindre la classe',
                        icon: Icons.login_rounded,
                        onPressed: _isLoading ? null : _submit,
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
