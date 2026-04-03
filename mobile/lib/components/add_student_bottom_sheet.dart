import 'package:flutter/material.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';

/// Bottom sheet : l’enseignant ajoute un élève avec son identifiant enfant.
/// Le parent peut aussi faire rejoindre l’enfant avec le code de classe (app parent).
class AddStudentBottomSheet extends StatefulWidget {
  const AddStudentBottomSheet({super.key});

  @override
  State<AddStudentBottomSheet> createState() => _AddStudentBottomSheetState();
}

class _AddStudentBottomSheetState extends State<AddStudentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kidIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _kidIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Navigator.pop(context, _kidIdController.text.trim());
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
                      'Ajouter un élève',
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
                      // Kid ID field
                      TextFormField(
                        controller: _kidIdController,
                        decoration: const InputDecoration(
                          labelText: 'Identifiant élève *',
                          hintText: 'Collez l’ID communiqué par le parent',
                          prefixIcon: Icon(Icons.badge_outlined),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L’identifiant est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
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
                                'Astuce : le parent peut aussi faire rejoindre l’enfant depuis son appli avec le code de la classe. L’ID s’affiche sur la fiche enfant côté parent (copier/coller).',
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
                        text: 'Ajouter à la classe',
                        icon: Icons.person_add,
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
