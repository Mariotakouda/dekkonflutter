import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dekkon_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/verify_account_screen.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar conforme à "profil_dekkon" : titre "Dekkon" centré + icône notifications.
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48), // équilibre visuel avec l'icône de droite
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Dekkon',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                (user?.customer?.firstName.isNotEmpty ?? false)
                                    ? user!.customer!.firstName[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.h1Mobile.copyWith(color: AppColors.primary),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.surface, width: 2),
                                ),
                                child: const Icon(Icons.verified, size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.customer?.fullName ?? user?.name ?? '',
                          style: AppTextStyles.h1Mobile,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                          child: Text('Modifier le profil', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _MenuSection(children: [
                    _MenuTile(
                      icon: Icons.person_outline,
                      label: 'Mon profil',
                      subtitle: 'Gérez vos infos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                    _MenuTile(
                      icon: Icons.location_on_outlined,
                      label: 'Mes adresses',
                      onTap: () => context.push('/addresses'),
                    ),
                    _MenuTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Mes commandes',
                      onTap: () => context.push('/orders'),
                    ),
                    _MenuTile(
                      icon: Icons.favorite_border,
                      label: 'Mes favoris',
                      onTap: () => context.push('/favorites'),
                    ),
                    _MenuTile(
                      icon: Icons.star_border,
                      label: 'Mes avis',
                      onTap: () => context.push('/reviews'),
                    ),
                    _MenuTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      trailingBadgeCount: unreadCount,
                      onTap: () => context.push('/notifications'),
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  _MenuSection(children: [
                    _MenuTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Vérifier mon compte',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VerifyAccountScreen()),
                      ),
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  _MenuSection(children: [
                    _MenuTile(
                      icon: Icons.logout,
                      label: 'Se déconnecter',
                      isDestructive: true,
                      isLast: true,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Se déconnecter ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion')),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref.read(authNotifierProvider.notifier).logout();
                          if (context.mounted) context.go('/auth');
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DekkonBottomNav(currentIndex: 4),
    );
  }
}

/// Carte groupant plusieurs [_MenuTile], conforme aux sections de
/// "profil_dekkon" (fond blanc, coins arrondis, séparateurs fins).
class _MenuSection extends StatelessWidget {
  final List<Widget> children;

  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLast;
  final int trailingBadgeCount;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.isLast = false,
    this.trailingBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.errorContainer : AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: isDestructive ? AppColors.error : AppColors.primary),
        ),
        title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
        trailing: isDestructive
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingBadgeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        trailingBadgeCount > 99 ? '99+' : '$trailingBadgeCount',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      ),
                    ),
                  const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}