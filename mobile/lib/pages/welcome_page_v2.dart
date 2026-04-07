import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/gradient_page_shell.dart';
import '../ui/transitions/page_transitions.dart';
import '../providers/app_settings_provider.dart';
import 'login_page_v2.dart';
import 'register_page_v2.dart';
import 'welcome/welcome_copy.dart';
import 'welcome/welcome_settings_sheet.dart';

/// Page d'accueil — produit SaaS sobre : hiérarchie typo, CTA compacts, réglages.
class WelcomePageV2 extends StatefulWidget {
  const WelcomePageV2({super.key});

  @override
  State<WelcomePageV2> createState() => _WelcomePageV2State();
}

class _WelcomePageV2State extends State<WelcomePageV2>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _starsController;
  late AnimationController _bounceController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _starsRotation;

  static const List<Color> _accentPalette = [
    Color(0xFF818CF8),
    Color(0xFFA78BFA),
    Color(0xFF22D3EE),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF94A3B8),
    Color(0xFF64748B),
  ];

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoRotation = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _starsRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _starsController, curve: Curves.linear),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _starsController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Widget _buildFloatingStar(Offset position, Color color, double size) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedBuilder(
        animation: _starsRotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _starsRotation.value,
            child: Opacity(
              opacity: 0.26,
              child: Icon(Icons.star_rounded, color: color, size: size),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBouncingShape(Offset position, Color color, IconData icon) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              math.sin(_bounceController.value * 2 * math.pi) * 8,
            ),
            child: Icon(
              icon,
              color: color.withValues(alpha: 0.5),
              size: 32,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final o = _logoScale.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Opacity(
              opacity: o,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: EduBridgeColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? EduBridgeColors.cardShadowLayeredDark
                      : EduBridgeColors.cardShadowLayered,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school_rounded,
                        size: 52,
                        color: scheme.onPrimary,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettingsProvider>().languageCode;
    final scheme = Theme.of(context).colorScheme;
    final onBg = scheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? EduBridgeColors.darkTextSecondary
        : EduBridgeColors.textSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientPageShell(
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingStar(
                const Offset(40, 72),
                _accentPalette[0],
                26,
              ),
              _buildFloatingStar(
                const Offset(300, 120),
                _accentPalette[1],
                22,
              ),
              _buildFloatingStar(
                const Offset(64, 220),
                _accentPalette[2],
                28,
              ),
              _buildBouncingShape(
                const Offset(312, 64),
                _accentPalette[3],
                Icons.diamond_outlined,
              ),
              _buildBouncingShape(
                const Offset(32, 360),
                _accentPalette[4],
                Icons.auto_awesome_outlined,
              ),

              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: WelcomeCopy.settingsTitle(lang),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: onBg.withValues(alpha: 0.85),
                  ),
                  onPressed: () => showWelcomeSettingsSheet(context),
                ),
              ),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EduBridgeTheme.spacingLG,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Hero(
                                tag: 'logo',
                                child: _buildLogo(scheme),
                              ),
                              const SizedBox(height: 28),

                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Transform.translate(
                                      offset: Offset(0, 14 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        '\u0645\u0631\u062d\u0628\u0627\u064b \u0628\u0643',
                                        textAlign: TextAlign.center,
                                        style: EduBridgeTypography.arabicTitle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      WelcomeCopy.welcomeToLine(lang),
                                      textAlign: TextAlign.center,
                                      style: EduBridgeTypography.titleMedium
                                          .copyWith(
                                        color: muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) =>
                                          EduBridgeColors.primaryGradient
                                              .createShader(
                                        Rect.fromLTWH(
                                          0,
                                          0,
                                          bounds.width,
                                          bounds.height,
                                        ),
                                      ),
                                      child: const Text(
                                        'EduBridge',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      WelcomeCopy.tagline(lang),
                                      textAlign: TextAlign.center,
                                      style: EduBridgeTypography.bodyMedium
                                          .copyWith(
                                        color: muted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: Transform.translate(
                                      offset: Offset(0, 18 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    EduBridgeTheme.radiusLG,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      GradientButton(
                                        text: WelcomeCopy.startCta(lang),
                                        height: 44,
                                        borderRadius: BorderRadius.circular(
                                          EduBridgeTheme.radiusMD,
                                        ),
                                        icon: Icons.arrow_forward_rounded,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageTransitions.fadeSlideRoute(
                                              const RegisterPageV2(),
                                            ),
                                          );
                                        },
                                        variant: GradientButtonVariant.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      GradientButton(
                                        text: WelcomeCopy.loginCta(lang),
                                        height: 44,
                                        borderRadius: BorderRadius.circular(
                                          EduBridgeTheme.radiusMD,
                                        ),
                                        variant:
                                            GradientButtonVariant.secondary,
                                        icon: Icons.login_rounded,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageTransitions.fadeSlideRoute(
                                              const LoginPageV2(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
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
    );
  }
}
