import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'ui/theme/edubridge_theme.dart';
import 'ui/transitions/page_transitions.dart';
import 'pages/welcome_page_v2.dart';
import 'providers/auth_provider.dart';
import 'providers/kids_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/subjects_provider.dart';
import 'providers/lessons_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/assignments_provider.dart';
import 'providers/live_sessions_provider.dart';
import 'services/api_service.dart';
import 'utils/app_router.dart';
import 'components/loading.dart';

void main() {
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Une seule instance ApiService partagée pour que le token soit disponible partout
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => KidsProvider(apiService)),
        ChangeNotifierProvider(create: (_) => QuizProvider(apiService)),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SubjectsProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => LessonsProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TeacherProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AssignmentsProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => LiveSessionsProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'EduBridge',
        theme: EduBridgeTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('fr', 'FR'),
        ],
        home: const HomePage(),
        // Transitions globales personnalisées
        onGenerateRoute: (settings) {
          // Tu peux ajouter des routes nommées ici si nécessaire
          return null;
        },
        // Utiliser les transitions par défaut pour toutes les navigations
        builder: (context, child) {
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Widget qui vérifie l'authentification et redirige selon le rôle
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    debugPrint('🔐 [HomePage] ========== INITIAL AUTH CHECK ==========');
    debugPrint('🔐 [HomePage] Is authenticated: ${authProvider.isAuthenticated}');
    
    // Si l'utilisateur a un token, charger le profil
    if (authProvider.isAuthenticated) {
      debugPrint('🔐 [HomePage] Token found, loading user profile...');
      try {
        await authProvider.loadProfile();
        debugPrint('🔐 [HomePage] Profile loaded successfully');
      } catch (e) {
        debugPrint('❌ [HomePage] Error loading profile: $e');
        // En cas d'erreur (token invalide, etc.), déconnecter l'utilisateur
        authProvider.logout();
      }
    } else {
      debugPrint('🔐 [HomePage] No token found, user not authenticated');
    }

    debugPrint('🔐 [HomePage] =======================================');

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Loading(message: 'Loading...'),
      );
    }

    // Utiliser AppRouter pour déterminer la page d'accueil
    return AppRouter.getHomePage(context);
  }
}
