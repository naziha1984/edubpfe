import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/edubridge_colors.dart';
import '../ui/theme/edubridge_typography.dart';
import '../ui/theme/edubridge_theme.dart';
import '../providers/admin_provider.dart';
import '../ui/components/glass_card.dart';
import '../components/user_card.dart';
import '../ui/components/loading_skeleton.dart';
import '../components/error_state.dart';
import '../components/empty_state.dart';
import '../ui/components/gradient_button.dart';
import '../models/admin_kid_model.dart';

/// Écran de gestion des utilisateurs avec recherche et filtres
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showKidsTab = false; // false = Utilisateurs, true = Enfants

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: EduBridgeColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: EduBridgeColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'User Management',
                        style: EduBridgeTypography.headlineMedium.copyWith(
                          color: EduBridgeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs Utilisateurs / Enfants
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EduBridgeTheme.spacingLG,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentChip('Utilisateurs', false, adminProvider),
                    ),
                    const SizedBox(width: EduBridgeTheme.spacingSM),
                    Expanded(
                      child: _buildSegmentChip('Enfants', true, adminProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EduBridgeTheme.spacingMD),
              if (!_showKidsTab) ...[
                // Search & Filters (users only)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EduBridgeTheme.spacingLG,
                  ),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      adminProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(
                              EduBridgeTheme.spacingMD,
                            ),
                          ),
                          onChanged: (value) {
                            adminProvider.setSearchQuery(value);
                          },
                        ),
                      ),
                      const SizedBox(height: EduBridgeTheme.spacingMD),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(
                              'All',
                              null,
                              adminProvider.roleFilter == null,
                              adminProvider,
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingSM),
                            _buildFilterChip(
                              'Admin',
                              'ADMIN',
                              adminProvider.roleFilter == 'ADMIN',
                              adminProvider,
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingSM),
                            _buildFilterChip(
                              'Teacher',
                              'TEACHER',
                              adminProvider.roleFilter == 'TEACHER',
                              adminProvider,
                            ),
                            const SizedBox(width: EduBridgeTheme.spacingSM),
                            _buildFilterChip(
                              'Parent',
                              'PARENT',
                              adminProvider.roleFilter == 'PARENT',
                              adminProvider,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EduBridgeTheme.spacingMD),
              ],
              Expanded(
                child: _showKidsTab
                    ? _buildKidsList(adminProvider)
                    : _buildUsersList(adminProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentChip(String label, bool isKids, AdminProvider adminProvider) {
    final selected = _showKidsTab == isKids;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showKidsTab = isKids;
            if (isKids) {
              adminProvider.loadKids();
            }
          });
        },
        borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: EduBridgeTheme.spacingSM,
            horizontal: EduBridgeTheme.spacingMD,
          ),
          decoration: BoxDecoration(
            color: selected
                ? EduBridgeColors.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusMD),
            border: Border.all(
              color: selected
                  ? EduBridgeColors.primary
                  : Colors.white.withOpacity(0.2),
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: EduBridgeTypography.labelLarge.copyWith(
              color: selected
                  ? EduBridgeColors.primary
                  : EduBridgeColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? role,
    bool isSelected,
    AdminProvider adminProvider,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        adminProvider.setRoleFilter(selected ? role : null);
      },
      selectedColor: EduBridgeColors.primary.withOpacity(0.2),
      checkmarkColor: EduBridgeColors.primary,
      labelStyle: EduBridgeTypography.labelMedium.copyWith(
        color: isSelected
            ? EduBridgeColors.primary
            : EduBridgeColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildUsersList(AdminProvider adminProvider) {
    if (adminProvider.isLoadingUsers) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (adminProvider.usersError != null) {
      return ErrorState(
        icon: Icons.error_outline,
        title: 'Error Loading Users',
        message: adminProvider.usersError ?? 'Unknown error',
        onRetry: () => adminProvider.loadUsers(),
      );
    }

    final filteredUsers = adminProvider.filteredUsers;

    if (filteredUsers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: adminProvider.searchQuery.isNotEmpty ||
                adminProvider.roleFilter != null
            ? 'No users found'
            : 'No users yet',
        message: adminProvider.searchQuery.isNotEmpty ||
                adminProvider.roleFilter != null
            ? 'Try adjusting your search or filters'
            : 'Users will appear here once they register',
        actionLabel: adminProvider.searchQuery.isNotEmpty ||
                adminProvider.roleFilter != null
            ? 'Clear Filters'
            : null,
        onAction: adminProvider.searchQuery.isNotEmpty ||
                adminProvider.roleFilter != null
            ? () {
                adminProvider.resetFilters();
                _searchController.clear();
              }
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: UserCard(
            user: filteredUsers[index],
            onTap: () {
              // TODO: Navigate to user details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User details for ${filteredUsers[index].email}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildKidsList(AdminProvider adminProvider) {
    if (adminProvider.isLoadingKids) {
      return ListView.builder(
        padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(EduBridgeTheme.radiusLG),
          ),
        ),
      );
    }

    if (adminProvider.kidsError != null) {
      return ErrorState(
        icon: Icons.child_care_outlined,
        title: 'Erreur chargement enfants',
        message: adminProvider.kidsError ?? 'Erreur inconnue',
        onRetry: () => adminProvider.loadKids(),
      );
    }

    final kids = adminProvider.kids;
    if (kids.isEmpty) {
      return EmptyState(
        icon: Icons.child_care_outlined,
        title: 'Aucun enfant',
        message: 'Les enfants apparaîtront ici une fois créés par les parents.',
        actionLabel: 'Actualiser',
        onAction: () => adminProvider.loadKids(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingLG),
      itemCount: kids.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: EduBridgeTheme.spacingMD),
          child: _buildKidCard(kids[index]),
        );
      },
    );
  }

  Widget _buildKidCard(AdminKidModel kid) {
    return GlassCard(
      padding: const EdgeInsets.all(EduBridgeTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: EduBridgeColors.primary.withOpacity(0.2),
                child: Icon(
                  Icons.person_outline,
                  color: EduBridgeColors.primary,
                ),
              ),
              const SizedBox(width: EduBridgeTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kid.fullName,
                      style: EduBridgeTypography.titleMedium.copyWith(
                        color: EduBridgeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parent: ${kid.parentName}',
                      style: EduBridgeTypography.bodySmall.copyWith(
                        color: EduBridgeColors.textSecondary,
                      ),
                    ),
                    if (kid.parentEmail != null) ...[
                      Text(
                        kid.parentEmail!,
                        style: EduBridgeTypography.bodySmall.copyWith(
                          color: EduBridgeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (kid.grade != null || kid.school != null) ...[
            const SizedBox(height: EduBridgeTheme.spacingSM),
            Wrap(
              spacing: EduBridgeTheme.spacingSM,
              children: [
                if (kid.grade != null)
                  Chip(
                    label: Text(
                      kid.grade!,
                      style: EduBridgeTypography.labelSmall,
                    ),
                    backgroundColor: EduBridgeColors.primary.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (kid.school != null)
                  Text(
                    kid.school!,
                    style: EduBridgeTypography.bodySmall.copyWith(
                      color: EduBridgeColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
