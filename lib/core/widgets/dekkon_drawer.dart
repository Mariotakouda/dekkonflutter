import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DekkonDrawer extends StatelessWidget {
  const DekkonDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.favorite_border,
                    label: 'Favoris',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/favorites');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_outlined,
                    label: 'Mes adresses',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/addresses');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
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
                    icon: Icons.settings_outlined,
                    label: 'Paramètres',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Aide & Support',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/support');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
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
              icon: Icons.logout,
              label: 'Déconnexion',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                // TODO: brancher sur la logique de déconnexion (provider auth).
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