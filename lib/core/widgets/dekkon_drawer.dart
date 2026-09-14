import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class DekkonDrawer extends ConsumerWidget {
  const DekkonDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- En-tête avec logo ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logodekkon.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Symbols.favorite,
                    label: 'Favoris',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/favorites');
                    },
                  ),
                  _DrawerItem(
                    icon: Symbols.location_on,
                    label: 'Mes adresses',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/addresses');
                    },
                  ),
                  _DrawerItem(
                    icon: Symbols.local_offer,
                    label: 'Codes promo',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/promo-codes');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerItem(
                    icon: Symbols.settings,
                    label: 'Paramètres',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Symbols.help,
                    label: 'Aide & Support',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/support');
                    },
                  ),
                  _DrawerItem(
                    icon: Symbols.description,
                    label: 'Conditions & Confidentialité',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/legal');
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            _DrawerItem(
              icon: Symbols.logout,
              label: 'Déconnexion',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  // `dialogContext` (et non le `context` de la page hôte) :
                  // sinon Navigator.pop dépile la page qui contient le drawer
                  // dans go_router au lieu de fermer juste la popup — ce qui
                  // vide toute la pile de navigation de cet onglet (écran
                  // blanc + "You have popped the last page off of the stack").
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

                if (confirmed != true) return;

                // On ferme d'abord le drawer, PUIS on déconnecte : appeler
                // logout() avant peut invalider le context du Scaffold qui
                // héberge le drawer et laisser un écran vide/figé le temps
                // que Navigator.pop tente de s'exécuter sur un arbre déjà
                // en cours de reconstruction (redirect vers /auth).
                if (context.mounted) Navigator.pop(context);

                await ref.read(authNotifierProvider.notifier).logout();

                if (context.mounted) context.go('/auth');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: labelColor ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}