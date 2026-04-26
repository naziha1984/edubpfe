import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../components/loading.dart';
import '../providers/auth_provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/transitions/page_transitions.dart';
import '../utils/app_router.dart';
import '../utils/error_handler.dart';
import 'register_page_v2.dart';

class LoginPageV2 extends StatefulWidget {
  const LoginPageV2({super.key});

  @override
  State<LoginPageV2> createState() => _LoginPageV2State();
}

class _LoginPageV2State extends State<LoginPageV2>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _ctaOpacity;
  late final Animation<Offset> _ctaSlide;
  late final AnimationController _breathController;
  late final Animation<double> _logoBreath;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDarkMode = false;
  // 'fr' ou 'ar'
  String _lang = 'fr';

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.10, 0.26, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.10, 0.26, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.22, 0.38, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.22, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _formOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.36, 0.66, curve: Curves.easeOutCubic),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.36, 0.66, curve: Curves.easeOutCubic),
      ),
    );

    _ctaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.62, 0.90, curve: Curves.easeOutCubic),
      ),
    );
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.62, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _logoBreath = Tween<double>(begin: 0.985, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _breathController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await ErrorHandler.handleApiCall(
        context,
        () => authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success == true) {
          HapticFeedback.mediumImpact();
          AppRouter.navigateAfterLogin(context);
        }
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$label sera bientôt disponible.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isWide = screen.width >= 900;
    final isAr = _lang == 'ar';
    final textDir = isAr ? TextDirection.rtl : TextDirection.ltr;
    final bgColor =
        _isDarkMode ? EduBridgeColors.darkBackground : EduBridgeColors.background;
    final primaryTextColor = _isDarkMode
        ? EduBridgeColors.darkTextPrimary
        : EduBridgeColors.textPrimary;
    final secondaryTextColor = _isDarkMode
        ? EduBridgeColors.darkTextSecondary
        : EduBridgeColors.textSecondary;
    final titlePrimary = isAr ? 'مرحباً بعودتك' : 'Welcome Back 👋';
    final titleSecondary = 'مرحبا بعودتك';
    final subtitle = isAr
        ? 'Welcome Back 👋'
        : 'Connectez-vous pour continuer votre expérience EduBridge avec une interface claire, moderne et professionnelle.';
    final emailLabel = isAr ? 'البريد الإلكتروني' : 'Email';
    final passwordLabel = isAr ? 'كلمة المرور' : 'Mot de passe';
    final forgotLabel = isAr ? 'هل نسيت كلمة المرور؟' : 'Forgot password?';
    final loginLabel = isAr ? 'تسجيل الدخول' : 'Connexion';
    final signupLabel = isAr ? 'إنشاء حساب' : 'S’inscrire';
    final orLabel = isAr ? 'أو متابعة باستخدام' : 'or continue with';
    final googleLabel = isAr ? 'متابعة باستخدام Google' : 'Continuer avec Google';
    final hintEmail = 'admin@edubridge.com';
    final hintPassword = '••••••••';

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: textDir,
        child: Stack(
          children: [
            Positioned.fill(
              child: _LoginPremiumBackground(isDarkMode: _isDarkMode),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _PremiumLoginCard(
                          isDarkMode: _isDarkMode,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    _IconGhostButton(
                                      icon: Icons.arrow_back_rounded,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    const Spacer(),
                                    _TopLangDarkControls(
                                      lang: _lang,
                                      isDarkMode: _isDarkMode,
                                      onLangChanged: (value) {
                                        setState(() => _lang = value);
                                      },
                                      onDarkChanged: (value) {
                                        setState(() => _isDarkMode = value);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _logoOpacity,
                                  child: SlideTransition(
                                    position: _logoSlide,
                                    child: ScaleTransition(
                                      scale: _logoBreath,
                                      child: _LoginHeroBadge(isDarkMode: _isDarkMode),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FadeTransition(
                                  opacity: _titleOpacity,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: Text(
                                      titlePrimary,
                                      key: ValueKey<String>('title_$titlePrimary'),
                                      textAlign: TextAlign.center,
                                      style: EduBridgeTypography.headlineMedium.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FadeTransition(
                                  opacity: _titleOpacity,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    child: Text(
                                      titleSecondary,
                                      key: ValueKey<String>('sub_$titleSecondary'),
                                      textAlign: TextAlign.center,
                                      style: EduBridgeTypography.arabicTitle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeTransition(
                                  opacity: _formOpacity,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    child: Text(
                                      subtitle,
                                      key: ValueKey<String>('desc_$subtitle'),
                                      textAlign: TextAlign.center,
                                      style: EduBridgeTypography.bodyMedium.copyWith(
                                        color: secondaryTextColor,
                                        height: 1.55,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                FadeTransition(
                                  opacity: _formOpacity,
                                  child: SlideTransition(
                                    position: _formSlide,
                                    child: Column(
                                      children: [
                                        _PremiumTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          keyboardType: TextInputType.emailAddress,
                                          isDarkMode: _isDarkMode,
                                          enabled: !_isLoading,
                                          label: emailLabel,
                                          hint: hintEmail,
                                          icon: Icons.mail_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return isAr
                                                  ? 'الرجاء إدخال البريد الإلكتروني'
                                                  : 'Entrez votre email';
                                            }
                                            if (!value.contains('@')) {
                                              return isAr
                                                  ? 'بريد إلكتروني غير صالح'
                                                  : 'Email invalide';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _PremiumTextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocusNode,
                                          isDarkMode: _isDarkMode,
                                          enabled: !_isLoading,
                                          label: passwordLabel,
                                          hint: hintPassword,
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _handleLogin(),
                                          suffix: IconButton(
                                            splashRadius: 18,
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: _isDarkMode
                                                  ? EduBridgeColors.darkTextTertiary
                                                  : EduBridgeColors.textTertiary,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return isAr
                                                  ? 'الرجاء إدخال كلمة المرور'
                                                  : 'Entrez votre mot de passe';
                                            }
                                            if (value.length < 6) {
                                              return isAr
                                                  ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
                                                  : 'Au moins 6 caractères';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => _showComingSoon(
                                              isAr
                                                  ? 'استعادة كلمة المرور'
                                                  : 'La récupération du mot de passe',
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: _isDarkMode
                                                  ? EduBridgeColors.primaryLight
                                                  : EduBridgeColors.primaryDark,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 2,
                                                vertical: 6,
                                              ),
                                              textStyle: EduBridgeTypography
                                                  .labelLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            child: Text(forgotLabel),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FadeTransition(
                                  opacity: _ctaOpacity,
                                  child: SlideTransition(
                                    position: _ctaSlide,
                                    child: Column(
                                      children: [
                                        _GradientActionButton(
                                          isDarkMode: _isDarkMode,
                                          isLoading: _isLoading,
                                          label: loginLabel,
                                          icon: Icons.arrow_forward_rounded,
                                          onPressed: _handleLogin,
                                        ),
                                        const SizedBox(height: 24),
                                        _SoftDivider(
                                          isDarkMode: _isDarkMode,
                                          label: orLabel,
                                        ),
                                        const SizedBox(height: 18),
                                        _SocialButton(
                                          isDarkMode: _isDarkMode,
                                          label: googleLabel,
                                          onPressed: () => _showComingSoon(
                                            isAr ? 'تسجيل Google' : 'La connexion Google',
                                          ),
                                        ),
                                        const SizedBox(height: 26),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isAr
                                                  ? 'ليس لديك حساب؟ '
                                                  : 'Pas encore de compte ? ',
                                              style: EduBridgeTypography.bodyMedium.copyWith(
                                                color: _isDarkMode
                                                    ? EduBridgeColors.darkTextSecondary
                                                    : EduBridgeColors.textSecondary,
                                              ),
                                            ),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(10),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageTransitions.fadeSlideRoute(
                                                    const RegisterPageV2(),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                                child: Text(
                                                  signupLabel,
                                                  style: EduBridgeTypography
                                                      .labelLarge
                                                      .copyWith(
                                                    color:
                                                        EduBridgeColors.primaryDark,
                                                    fontWeight: FontWeight.w800,
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

class _LoginPremiumBackground extends StatelessWidget {
  const _LoginPremiumBackground({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? EduBridgeColors.backgroundGradientDark
            : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F8FF),
            Color(0xFFEEF2FF),
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            child: _BlurOrb(
              size: 280,
              color: EduBridgeColors.primary.withOpacity(isDarkMode ? 0.12 : 0.18),
            ),
          ),
          Positioned(
            top: 120,
            right: -60,
            child: _BlurOrb(
              size: 240,
              color: EduBridgeColors.secondary.withOpacity(isDarkMode ? 0.11 : 0.16),
            ),
          ),
          Positioned(
            bottom: -70,
            left: 30,
            child: _BlurOrb(
              size: 220,
              color: EduBridgeColors.accent.withOpacity(isDarkMode ? 0.10 : 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
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
}

class _PremiumLoginCard extends StatefulWidget {
  const _PremiumLoginCard({
    required this.child,
    required this.isDarkMode,
  });

  final Widget child;
  final bool isDarkMode;

  @override
  State<_PremiumLoginCard> createState() => _PremiumLoginCardState();
}

class _PremiumLoginCardState extends State<_PremiumLoginCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.008 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? EduBridgeColors.darkSurface.withOpacity(0.82)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.isDarkMode
                      ? EduBridgeColors.darkSurfaceVariant.withOpacity(0.85)
                      : Colors.white.withOpacity(0.8),
                  width: 1.1,
                ),
                boxShadow: widget.isDarkMode
                    ? EduBridgeColors.cardShadowHoverDark(_hovered)
                    : EduBridgeColors.cardShadowHover(_hovered),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeroBadge extends StatelessWidget {
  const _LoginHeroBadge({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [
                    Color(0xFF5B61F6),
                    Color(0xFF7A55F8),
                    Color(0xFF9D7CFF),
                  ]
                : const [
                    EduBridgeColors.primary,
                    EduBridgeColors.secondary,
                    Color(0xFFB794F6),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: EduBridgeColors.shadowPrimary,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconGhostButton extends StatelessWidget {
  const _IconGhostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EduBridgeColors.surface.withOpacity(0.75),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EduBridgeColors.surfaceDim),
          ),
          child: Icon(
            icon,
            color: EduBridgeColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatefulWidget {
  const _PremiumTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
    this.enabled = true,
    this.isDarkMode = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool isDarkMode;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? EduBridgeColors.primary
        : widget.isDarkMode
            ? EduBridgeColors.darkSurfaceVariant
            : EduBridgeColors.surfaceDim;
    final fieldColor = widget.isDarkMode
        ? EduBridgeColors.darkSurface.withOpacity(_focused ? 0.95 : 0.84)
        : Colors.white.withOpacity(_focused ? 0.95 : 0.82);
    final iconBg = widget.isDarkMode
        ? EduBridgeColors.darkSurfaceVariant.withOpacity(_focused ? 0.86 : 0.64)
        : (_focused
                ? EduBridgeColors.primary
                : EduBridgeColors.surfaceVariant)
            .withOpacity(_focused ? 0.14 : 1);
    final iconColor = _focused || _hasText
        ? EduBridgeColors.primaryDark
        : widget.isDarkMode
            ? EduBridgeColors.darkTextSecondary
            : EduBridgeColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: _focused ? 1.6 : 1),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: EduBridgeColors.primary.withOpacity(0.16),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ]
            : EduBridgeColors.shadowSm,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: EduBridgeTypography.bodyMedium.copyWith(
          color: widget.isDarkMode
              ? EduBridgeColors.darkTextPrimary
              : EduBridgeColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
          labelText: widget.label,
          hintText: widget.hint,
          labelStyle: EduBridgeTypography.bodyMedium.copyWith(
            color: _focused || _hasText
                ? EduBridgeColors.primaryDark
                : widget.isDarkMode
                    ? EduBridgeColors.darkTextSecondary
                    : EduBridgeColors.textSecondary,
          ),
          hintStyle: EduBridgeTypography.bodyMedium.copyWith(
            color: widget.isDarkMode
                ? EduBridgeColors.darkTextTertiary
                : EduBridgeColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: _focused ? 1.06 : _hasText ? 1.03 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
          suffixIcon: widget.suffix,
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatefulWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
    required this.isDarkMode,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDarkMode;

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final elevated = _hovered || _pressed;
    return AnimatedScale(
      scale: _pressed ? 0.98 : elevated ? 1.01 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: widget.isDarkMode
                    ? const [
                        Color(0xFF5259F3),
                        Color(0xFF7C5AF8),
                      ]
                    : const [
                        EduBridgeColors.primary,
                        EduBridgeColors.secondary,
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: EduBridgeColors.primary.withOpacity(elevated ? 0.4 : 0.34),
                  blurRadius: elevated ? 28 : 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: EduBridgeTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSlide(
                        offset: _pressed ? const Offset(0.02, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 120),
                        child: Icon(widget.icon, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider({
    required this.label,
    required this.isDarkMode,
  });

  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDarkMode
                ? EduBridgeColors.darkSurfaceVariant
                : EduBridgeColors.surfaceDim,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: EduBridgeTypography.bodySmall.copyWith(
              color: isDarkMode
                  ? EduBridgeColors.darkTextTertiary
                  : EduBridgeColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDarkMode
                ? EduBridgeColors.darkSurfaceVariant
                : EduBridgeColors.surfaceDim,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.isDarkMode,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDarkMode
          ? EduBridgeColors.darkSurface.withOpacity(0.9)
          : Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDarkMode
                  ? EduBridgeColors.darkSurfaceVariant
                  : EduBridgeColors.surfaceDim,
            ),
            boxShadow: isDarkMode
                ? EduBridgeColors.shadowMd
                : EduBridgeColors.shadowSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'G',
                  style: EduBridgeTypography.labelLarge.copyWith(
                    color: const Color(0xFF4285F4),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: EduBridgeTypography.labelLarge.copyWith(
                  color: isDarkMode
                      ? EduBridgeColors.darkTextPrimary
                      : EduBridgeColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLangDarkControls extends StatelessWidget {
  const _TopLangDarkControls({
    required this.lang,
    required this.isDarkMode,
    required this.onLangChanged,
    required this.onDarkChanged,
  });

  final String lang;
  final bool isDarkMode;
  final ValueChanged<String> onLangChanged;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? EduBridgeColors.darkSurfaceVariant.withOpacity(0.86)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? EduBridgeColors.darkSurfaceVariant
                  : EduBridgeColors.surfaceDim,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: lang,
              isDense: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: isDarkMode
                    ? EduBridgeColors.darkTextSecondary
                    : EduBridgeColors.textSecondary,
              ),
              style: EduBridgeTypography.labelMedium.copyWith(
                color: isDarkMode
                    ? EduBridgeColors.darkTextPrimary
                    : EduBridgeColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              dropdownColor:
                  isDarkMode ? EduBridgeColors.darkSurface : EduBridgeColors.surface,
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('FR')),
                DropdownMenuItem(value: 'ar', child: Text('AR')),
              ],
              onChanged: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  onLangChanged(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? EduBridgeColors.darkSurfaceVariant.withOpacity(0.86)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? EduBridgeColors.darkSurfaceVariant
                  : EduBridgeColors.surfaceDim,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 16,
                color: isDarkMode
                    ? EduBridgeColors.darkTextSecondary
                    : EduBridgeColors.textSecondary,
              ),
              Switch.adaptive(
                value: isDarkMode,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onDarkChanged(value);
                },
                activeColor: EduBridgeColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
