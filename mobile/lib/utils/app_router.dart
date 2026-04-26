import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/welcome_page_v2.dart';
import '../pages/login_page_v2.dart';
import '../pages/kids_list_page.dart';
import '../pages/parent_dashboard_screen.dart';
import '../pages/admin_dashboard_screen.dart';
import '../pages/teacher_dashboard_screen.dart';
import '../ui/transitions/page_transitions.dart';

class AppRouter {
  /// Détermine la page d'accueil selon le rôle de l'utilisateur
  /// Règles de routing:
  /// - ADMIN -> AdminHomePage
  /// - TEACHER -> TeacherHomePage
  /// - PARENT -> ParentDashboardScreen
  static Widget getHomePage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    debugPrint('🔀 [AppRouter] ========== ROUTING DECISION ==========');
    debugPrint('🔀 [AppRouter] User authenticated: ${authProvider.isAuthenticated}');
    debugPrint('🔀 [AppRouter] User object: ${user != null ? "exists" : "null"}');

    if (user == null) {
      debugPrint('🔀 [AppRouter] No user found -> WelcomePageV2');
      debugPrint('🔀 [AppRouter] ======================================');
      return const WelcomePageV2();
    }

    // Debug log détaillé
    debugPrint('🔀 [AppRouter] User ID: ${user.id}');
    debugPrint('🔀 [AppRouter] User Name: ${user.fullName}');
    debugPrint('🔀 [AppRouter] User Role (raw): ${user.role}');
    debugPrint('🔀 [AppRouter] IsAdmin: ${user.isAdmin}');
    debugPrint('🔀 [AppRouter] IsTeacher: ${user.isTeacher}');
    debugPrint('🔀 [AppRouter] IsParent: ${user.isParent}');

    // Routing basé sur le rôle - ordre de priorité: ADMIN > TEACHER > PARENT
    Widget targetPage;
    if (user.isAdmin) {
      debugPrint('🔀 [AppRouter] ✅ Routing to: AdminDashboardScreen');
      targetPage = const AdminDashboardScreen();
    } else if (user.isTeacher) {
      debugPrint('🔀 [AppRouter] ✅ Routing to: TeacherDashboardScreen');
      targetPage = const TeacherDashboardScreen();
    } else {
      // Par défaut, parent (ou rôle non reconnu -> traité comme parent)
      debugPrint('🔀 [AppRouter] ✅ Routing to: ParentDashboardScreen');
      targetPage = const ParentDashboardScreen();
    }

    debugPrint('🔀 [AppRouter] ======================================');
    return targetPage;
  }

  /// Navigue vers la page appropriée après login
  /// Utilise les mêmes règles de routing que getHomePage
  static void navigateAfterLogin(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    debugPrint('🔀 [AppRouter] ========== POST-LOGIN ROUTING ==========');
    debugPrint('🔀 [AppRouter] User authenticated: ${authProvider.isAuthenticated}');
    debugPrint('🔀 [AppRouter] User object: ${user != null ? "exists" : "null"}');

    if (user == null) {
      debugPrint('🔀 [AppRouter] ⚠️ No user after login -> redirecting to LoginPageV2');
      debugPrint('🔀 [AppRouter] =========================================');
      Navigator.pushReplacement(
        context,
        PageTransitions.fadeSlideRoute(const LoginPageV2()),
      );
      return;
    }

    // Debug log détaillé
    debugPrint('🔀 [AppRouter] User ID: ${user.id}');
    debugPrint('🔀 [AppRouter] User Name: ${user.fullName}');
    debugPrint('🔀 [AppRouter] User Role: ${user.role}');
    debugPrint('🔀 [AppRouter] IsAdmin: ${user.isAdmin}');
    debugPrint('🔀 [AppRouter] IsTeacher: ${user.isTeacher}');
    debugPrint('🔀 [AppRouter] IsParent: ${user.isParent}');

    // Déterminer la page cible selon le rôle
    Widget targetPage;
    if (user.isAdmin) {
      debugPrint('🔀 [AppRouter] ✅ Post-login routing to: AdminDashboardScreen');
      targetPage = const AdminDashboardScreen();
    } else if (user.isTeacher) {
      debugPrint('🔀 [AppRouter] ✅ Post-login routing to: TeacherDashboardScreen');
      targetPage = const TeacherDashboardScreen();
    } else {
      debugPrint('🔀 [AppRouter] ✅ Post-login routing to: ParentDashboardScreen');
      targetPage = const ParentDashboardScreen();
    }

    debugPrint('🔀 [AppRouter] =========================================');
    Navigator.pushReplacement(
      context,
      PageTransitions.fadeSlideRoute(targetPage),
    );
  }
}
