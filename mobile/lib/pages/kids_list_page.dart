import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/gradient_button.dart';
import '../components/glass_card.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../providers/kids_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import '../utils/rtl_support.dart';
import '../utils/app_router.dart';
import 'add_kid_page.dart';
import 'set_pin_page.dart';
import 'subjects_page.dart';
import 'verify_pin_page.dart';

class KidsListPage extends StatefulWidget {
  const KidsListPage({super.key});

  @override
  State<KidsListPage> createState() => _KidsListPageState();
}

class _KidsListPageState extends State<KidsListPage> {
  String? _selectedLanguage;

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
        body: Container(
          decoration: const BoxDecoration(
            gradient: EduBridgeColors.backgroundGradient,
          ),
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
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () {
                              authProvider.logout();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
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
                // Add Kid Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GradientButton(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
