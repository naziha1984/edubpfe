import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../components/loading.dart';
import '../components/cv_upload_field.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import '../ui/transitions/page_transitions.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../components/toast.dart';
import 'login_page_v2.dart';

/// Page d'inscription — design ludique et moderne, adapté aux familles et aux enfants.
class RegisterPageV2 extends StatefulWidget {
  const RegisterPageV2({super.key});

  @override
  State<RegisterPageV2> createState() => _RegisterPageV2State();
}

class _RegisterPageV2State extends State<RegisterPageV2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'PARENT';
  Uint8List? _cvBytes;
  String? _cvFileName;
  String? _cvError;

  // Couleurs « arc-en-ciel doux » — complètent le design system
  static const Color _sunshine = Color(0xFFFFD166);
  static const Color _bubbleMint = Color(0xFF95E8D7);
  static const Color _bubblePink = Color(0xFFFFB4C8);
  static const Color _skyTint = Color(0xFFE8F4FF);
  static const Color _creamCard = Color(0xFFFFFDF8);

  late AnimationController _bobbleController;

  @override
  void initState() {
    super.initState();
    _bobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobbleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'TEACHER' && (_cvBytes == null || _cvFileName == null)) {
        setState(() {
          _cvError = 'Le CV est obligatoire pour un enseignant';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _cvError = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await ErrorHandler.handleApiCall(
        context,
        () => authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: _selectedRole,
          cvBytes: _cvBytes,
          cvFileName: _cvFileName,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success == true) {
          if (_selectedRole == 'TEACHER') {
            Toast.success(
              context,
              'Inscription envoyée. CV téléversé, en attente de validation admin.',
            );
          } else {
            Toast.success(context, 'Inscription réussie !');
          }
          Navigator.pushReplacement(
            context,
            PageTransitions.fadeSlideRoute(
              const LoginPageV2(),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickCvFile() async {
    setState(() {
      _cvError = null;
    });
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _cvError = 'Impossible de lire le fichier sélectionné';
      });
      return;
    }
    const maxBytes = 8 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      setState(() {
        _cvError = 'Le CV dépasse 8 MB';
      });
      return;
    }
    setState(() {
      _cvBytes = bytes;
      _cvFileName = file.name;
      _cvError = null;
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransitions.fadeSlideRoute(const LoginPageV2()),
      (route) => false,
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: EduBridgeTypography.bodyMedium.copyWith(
        color: EduBridgeColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: EduBridgeTypography.bodyMedium.copyWith(
        color: EduBridgeColors.textTertiary,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: EduBridgeColors.secondary,
        size: 22,
      ),
      filled: true,
      fillColor: _skyTint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: EduBridgeColors.secondary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: EduBridgeColors.secondary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: EduBridgeColors.error.withOpacity(0.8),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: EduBridgeColors.error, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required String role,
    required Color accent,
  }) {
    final isSelected = _selectedRole == role;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      transform: Matrix4.diagonal3Values(
        isSelected ? 1.02 : 1.0,
        isSelected ? 1.02 : 1.0,
        1,
      ),
      transformAlignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedRole = role;
            if (role != 'TEACHER') {
              _cvError = null;
            }
          }),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.35),
                        EduBridgeColors.primaryContainer,
                      ],
                    )
                  : null,
              color: isSelected ? null : EduBridgeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? accent : EduBridgeColors.surfaceDim,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? accent : EduBridgeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: EduBridgeTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? EduBridgeColors.textPrimary
                        : EduBridgeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: EduBridgeTypography.labelSmall.copyWith(
                    color: EduBridgeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorativeBlob({
    required double size,
    required Color color,
    required Alignment alignment,
  }) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Loading(message: 'Création du compte...'),
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFB8E8FF),
                    EduBridgeColors.accentContainer.withOpacity(0.9),
                    EduBridgeColors.secondaryContainer.withOpacity(0.85),
                    const Color(0xFFFFF0F5),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          _decorativeBlob(
            size: 140,
            color: Colors.white.withOpacity(0.35),
            alignment: const Alignment(-1.15, -0.55),
          ),
          _decorativeBlob(
            size: 100,
            color: _sunshine.withOpacity(0.45),
            alignment: const Alignment(1.2, -0.2),
          ),
          _decorativeBlob(
            size: 90,
            color: _bubbleMint.withOpacity(0.4),
            alignment: const Alignment(1.1, 0.85),
          ),
          _decorativeBlob(
            size: 76,
            color: _bubblePink.withOpacity(0.35),
            alignment: const Alignment(-0.95, 0.75),
          ),
          AnimatedBuilder(
            animation: _bobbleController,
            builder: (context, child) {
              final t = _bobbleController.value;
              return Positioned(
                top: topInset + 52 + (t * 6),
                right: 28,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.08 + (t * 0.04),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 36,
                      color: _sunshine.withOpacity(0.85),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.92),
                          foregroundColor: EduBridgeColors.secondaryDark,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On crée ton compte',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rejoins EduBridge pour apprendre en s\'amusant',
                        style: EduBridgeTypography.bodyLarge.copyWith(
                          color: EduBridgeColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _creamCard,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A5B21B6),
                          blurRadius: 24,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      textInputAction: TextInputAction.next,
                                      style: EduBridgeTypography.bodyLarge,
                                      decoration: _inputDecoration(
                                        labelText: 'Prénom',
                                        prefixIcon: Icons.sentiment_satisfied_alt_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'C\'est obligatoire';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      textInputAction: TextInputAction.next,
                                      style: EduBridgeTypography.bodyLarge,
                                      decoration: _inputDecoration(
                                        labelText: 'Nom',
                                        prefixIcon: Icons.badge_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'C\'est obligatoire';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Tu t\'inscris comme',
                                style: EduBridgeTypography.titleSmall.copyWith(
                                  color: EduBridgeColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildRoleCard(
                                      label: 'Parent',
                                      subtitle: 'Accompagner l\'enfant',
                                      icon: Icons.family_restroom_rounded,
                                      role: 'PARENT',
                                      accent: EduBridgeColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildRoleCard(
                                      label: 'Enseignant',
                                      subtitle: 'Encadrer les élèves',
                                      icon: Icons.school_rounded,
                                      role: 'TEACHER',
                                      accent: EduBridgeColors.accentDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedRole == 'TEACHER') ...[
                                const SizedBox(height: 14),
                                CvUploadField(
                                  fileName: _cvFileName,
                                  errorText: _cvError,
                                  onPick: _pickCvFile,
                                  onClear: () {
                                    setState(() {
                                      _cvBytes = null;
                                      _cvFileName = null;
                                      _cvError = null;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: EduBridgeTypography.bodyLarge,
                                decoration: _inputDecoration(
                                  labelText: 'Email',
                                  hintText: 'toi@exemple.fr',
                                  prefixIcon: Icons.mark_email_unread_rounded,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entre ton email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: EduBridgeTypography.bodyLarge,
                                decoration: _inputDecoration(
                                  labelText: 'Mot de passe',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: EduBridgeColors.textTertiary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Un mot de passe, s\'il te plaît';
                                  }
                                  if (value.length < 6) {
                                    return 'Au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: EduBridgeTypography.bodyLarge,
                                decoration: _inputDecoration(
                                  labelText: 'Confirmer',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.verified_user_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: EduBridgeColors.textTertiary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirme le mot de passe';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Les deux ne matchent pas';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      EduBridgeColors.primary,
                                      EduBridgeColors.secondary,
                                    ],
                                  ),
                                  boxShadow: EduBridgeColors.shadowPrimary,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _handleRegister,
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      height: 56,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'C\'est parti !',
                                        style: EduBridgeTypography.titleMedium
                                            .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _goToLogin,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: EduBridgeTypography.bodyMedium
                                              .copyWith(
                                            color: EduBridgeColors.textSecondary,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Déjà un compte ? '),
                                            TextSpan(
                                              text: 'Se connecter',
                                              style: EduBridgeTypography.bodyMedium
                                                  .copyWith(
                                                color: EduBridgeColors.secondaryDark,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
