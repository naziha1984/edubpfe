import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../ui/components/gradient_page_shell.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../components/join_class_bottom_sheet.dart';
import '../components/toast.dart';
import '../providers/kids_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import '../utils/rtl_support.dart';
import '../utils/app_router.dart';
import 'add_kid_page.dart';
import 'set_pin_page.dart';
import 'verify_pin_page.dart';
import 'notifications_screen.dart';

class KidsListPage extends StatefulWidget {
  const KidsListPage({super.key});

  @override
  State<KidsListPage> createState() => _KidsListPageState();
}

class _KidsListPageState extends State<KidsListPage> {
  String? _selectedLanguage;

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  Future<void> _showProfileSheet() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: EduBridgeColors.primary.withOpacity(0.15),
                      child: Icon(
                        Icons.person,
                        color: EduBridgeColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: EduBridgeTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            user.email,
                            style: EduBridgeTypography.bodySmall.copyWith(
                              color: EduBridgeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Rôle : ${user.role}',
                  style: EduBridgeTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Décaler le chargement après le premier frame pour éviter setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKids();
    });
  }

  Future<void> _loadKids() async {
    if (!mounted) return;
    final kidsProvider = Provider.of<KidsProvider>(context, listen: false);
    await ErrorHandler.handleApiCall(
      context,
      () => kidsProvider.loadKids(),
    );
  }

  Future<void> _openJoinClassSheet() async {
    final kidsProvider = Provider.of<KidsProvider>(context, listen: false);
    if (kidsProvider.kids.isEmpty) {
      ErrorHandler.showError(
        context,
        Exception('Ajoute d\'abord un enfant dans « Add Kid »'),
      );
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: JoinClassBottomSheet(kids: kidsProvider.kids),
      ),
    );
    if (result == true && mounted) {
      Toast.success(context, 'Inscription à la classe réussie !');
    }
  }

  Future<void> _copyKidId(String kidId) async {
    await Clipboard.setData(ClipboardData(text: kidId));
    if (mounted) {
      Toast.success(context, 'Identifiant copié — à envoyer à l’enseignant si besoin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsProvider = Provider.of<KidsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Protection : Seuls les PARENT peuvent accéder à cette page
    if (!authProvider.isParent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('⚠️ [KidsListPage] Access denied for role: ${authProvider.userRole}');
        debugPrint('⚠️ [KidsListPage] Redirecting to appropriate home page');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppRouter.getHomePage(context),
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: RTLSupport.getTextDirection(_selectedLanguage),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientPageShell(
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Kids',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Notifications',
                            icon: const Icon(Icons.notifications_outlined),
                            color: EduBridgeColors.textPrimary,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          // Language selector
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            hint: const Text('Language'),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('EN')),
                              DropdownMenuItem(value: 'fr', child: Text('FR')),
                              DropdownMenuItem(value: 'ar', child: Text('AR')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                            },
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Profil',
                            onSelected: (value) {
                              if (value == 'profile') {
                                _showProfileSheet();
                              } else if (value == 'logout') {
                                _logout();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: ListTile(
                                  leading: Icon(Icons.person_outline),
                                  title: Text('Voir profil'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: ListTile(
                                  leading: Icon(Icons.logout),
                                  title: Text('Se déconnecter'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: EduBridgeColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(Icons.person, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Kids List
                Expanded(
                  child: kidsProvider.isLoading
                      ? const Loading()
                      : kidsProvider.kids.isEmpty
                          ? EmptyState(
                              icon: Icons.child_care,
                              title: 'No Kids Yet',
                              message: 'Add your first child to get started',
                              action: GradientButton(
                                text: 'Add Kid',
                                icon: Icons.add,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddKidPage(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadKids();
                                  }
                                },
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadKids,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: kidsProvider.kids.length,
                                itemBuilder: (context, index) {
                                  final kid = kidsProvider.kids[index];
                                  return GlassCard(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    onTap: () {
                                      // Navigate to PIN verification
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VerifyPinPage(
                                            kidId: kid['id'],
                                            kidName:
                                                '${kid['firstName']} ${kid['lastName']}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: EduBridgeColors.primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: EduBridgeColors.primary,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${kid['firstName']} ${kid['lastName']}',
                                                style: EduBridgeTypography
                                                    .titleLarge.copyWith(
                                                  color:
                                                      EduBridgeColors.textPrimary,
                                                ),
                                              ),
                                              if (kid['grade'] != null)
                                                Text(
                                                  'Grade: ${kid['grade']}',
                                                  style: EduBridgeTypography
                                                      .bodyMedium,
                                                ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'ID élève : ${kid['id']}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: EduBridgeTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: EduBridgeColors
                                                            .textTertiary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.copy_rounded,
                                                      size: 20,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    tooltip:
                                                        'Copier l’ID pour l’enseignant',
                                                    onPressed: () =>
                                                        _copyKidId(
                                                      kid['id'].toString(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.lock),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SetPinPage(kidId: kid['id']),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
                // Add kid + join class
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GradientButton(
                        text: 'Add Kid',
                        icon: Icons.add,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddKidPage(),
                            ),
                          );
                          if (result == true) {
                            _loadKids();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openJoinClassSheet,
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Rejoindre une classe (code)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EduBridgeColors.primary,
                          side: const BorderSide(
                            color: EduBridgeColors.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
