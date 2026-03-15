import 'package:flutter/material.dart';
import 'admin_home_screen.dart';

/// Legacy AdminHomePage - redirige vers AdminHomeScreen
/// Conservé pour compatibilité avec le code existant
@Deprecated('Use AdminHomeScreen instead')
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Rediriger vers le nouvel écran moderne
    return const AdminHomeScreen();
  }
}
