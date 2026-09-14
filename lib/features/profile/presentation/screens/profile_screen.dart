import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dekkon_logo.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/verify_account_screen.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import 'edit_profile_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

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
            // TopAppBar conforme à "profil_dekkon" : logo centré + icône
            // notifications, sur le dégradé orange -> blanc commun à toutes
            // les pages principales.
            GradientHeader(
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 48), // équilibre visuel avec l'icône de droite
                      const Expanded(
                        child: Center(
                          child: DekkonLogo(height: 24),
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Symbols.notifications, color: Colors.white),
                            onPressed: () => context.push('/notifications'),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                                child: const Icon(Symbols.verified, size: 13, color: Colors.white),
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
                      icon: Symbols.person,
                      label: 'Mon profil',
                      subtitle: 'Gérez vos infos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                    _MenuTile(
                      icon: Symbols.location_on,
                      label: 'Mes adresses',
                      onTap: () => context.push('/addresses'),
                    ),
                    _MenuTile(
                      icon: Symbols.receipt_long,
                      label: 'Mes commandes',
                      // go() et non push() : '/orders' est un onglet de la
                      // coquille à navigation, pas un écran empilé (même
                      // bug que /cart, voir product_detail_screen.dart).
                      onTap: () => context.go('/orders'),
                    ),
                    _MenuTile(
                      icon: Symbols.favorite,
                      label: 'Mes favoris',
                      onTap: () => context.push('/favorites'),
                    ),
                    _MenuTile(
                      icon: Symbols.star,
                      label: 'Mes avis',
                      onTap: () => context.push('/reviews'),
                    ),
                    _MenuTile(
                      icon: Symbols.notifications,
                      label: 'Notifications',
                      trailingBadgeCount: unreadCount,
                      onTap: () => context.push('/notifications'),
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  _MenuSection(children: [
                    _MenuTile(
                      icon: Symbols.verified_user,
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
                      icon: Symbols.logout,
                      label: 'Se déconnecter',
                      isDestructive: true,
                      isLast: true,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          // `dialogContext` (et non le `context` de la page Profil) :
                          // sinon Navigator.pop dépile la page Profil elle-même dans
                          // go_router au lieu de fermer juste la popup, ce qui peut
                          // vider toute la pile de navigation (écran blanc).
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Se déconnecter ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Déconnexion'),
                              ),
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
                  const Icon(Symbols.chevron_right, color: AppColors.textDisabled),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}