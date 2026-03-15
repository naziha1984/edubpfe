import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../ui/components/gradient_button.dart';
import '../ui/components/glass_card.dart';
import '../ui/transitions/page_transitions.dart';
import 'login_page_v2.dart';
import 'register_page_v2.dart';

/// Page d'accueil attrayante pour les enfants avec logo et bienvenue en arabe
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

  // Couleurs vives pour enfants
  static const List<Color> _childColors = [
    Color(0xFFFF6B6B), // Rouge vif
    Color(0xFFFFD93D), // Jaune vif
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFF95E1D3), // Vert menthe
    Color(0xFFFFA07A), // Saumon
    Color(0xFF87CEEB), // Bleu ciel
    Color(0xFFFFB6C1), // Rose
    Color(0xFFDDA0DD), // Prune
  ];

  @override
  void initState() {
    super.initState();

    // Animation du logo (bounce + rotation)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    // Animation des étoiles (rotation continue)
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _starsRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _starsController,
        curve: Curves.linear,
      ),
    );

    // Animation de bounce pour les éléments décoratifs
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
              opacity: 0.6,
              child: Icon(
                Icons.star,
                color: color,
                size: size,
              ),
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
            offset: Offset(0, math.sin(_bounceController.value * 2 * math.pi) * 10),
            child: Icon(
              icon,
              color: color,
              size: 40,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final clampedOpacity = _logoScale.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Opacity(
              opacity: clampedOpacity,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFD93D),
                      Color(0xFF4ECDC4),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 70,
                  color: Colors.white,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF5E1), // Crème chaud
              Color(0xFFE8F5E9), // Vert très clair
              Color(0xFFE3F2FD), // Bleu très clair
              Color(0xFFFCE4EC), // Rose très clair
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Éléments décoratifs flottants
              _buildFloatingStar(
                const Offset(50, 100),
                _childColors[0],
                30,
              ),
              _buildFloatingStar(
                const Offset(300, 150),
                _childColors[1],
                25,
              ),
              _buildFloatingStar(
                const Offset(80, 250),
                _childColors[2],
                35,
              ),
              _buildBouncingShape(
                const Offset(320, 80),
                _childColors[3],
                Icons.favorite,
              ),
              _buildBouncingShape(
                const Offset(40, 400),
                _childColors[4],
                Icons.auto_awesome,
              ),
              _buildBouncingShape(
                const Offset(280, 450),
                _childColors[5],
                Icons.celebration,
              ),

              // Contenu principal
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(EduBridgeTheme.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Logo avec animation
                      Hero(
                        tag: 'logo',
                        child: _buildLogo(),
                      ),
                      const SizedBox(height: 40),

                      // Message de bienvenue en arabe
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Column(
                                children: [
                                  // Texte arabe "مرحباً" (Bienvenue)
                                  Text(
                                    'مرحباً',
                                    style: EduBridgeTypography.arabicTitle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: _childColors[0],
                                    ).copyWith(
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Sous-titre en français
                                  Text(
                                    'Bienvenue sur',
                                    style: EduBridgeTypography.headlineSmall.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Nom de l'application
                                  Text(
                                    'EduBridge',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..shader = const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B6B),
                                            Color(0xFFFFD93D),
                                            Color(0xFF4ECDC4),
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 70),
                                        ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Message amical
                                  Text(
                                    'Apprendre en s\'amusant ! 🎉',
                                    style: EduBridgeTypography.bodyLarge.copyWith(
                                      color: EduBridgeColors.textSecondary,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Boutons avec animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: GlassCard(
                                padding: const EdgeInsets.all(EduBridgeTheme.spacingXL),
                                child: Column(
                                  children: [
                                    GradientButton(
                                      text: 'Commencer',
                                      icon: Icons.rocket_launch,
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
                                    const SizedBox(height: EduBridgeTheme.spacingMD),
                                    GradientButton(
                                      text: 'Se connecter',
                                      variant: GradientButtonVariant.secondary,
                                      icon: Icons.login,
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
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
