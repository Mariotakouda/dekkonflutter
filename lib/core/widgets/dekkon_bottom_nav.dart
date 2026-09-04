import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

class DekkonBottomNav extends ConsumerWidget {
  final int currentIndex;

  const DekkonBottomNav({super.key, required this.currentIndex});

  static const _items = [
    (icon: Icons.home_outlined, iconFilled: Icons.home, label: 'Accueil', route: '/home'),
    (icon: Icons.grid_view_outlined, iconFilled: Icons.grid_view, label: 'Catalogue', route: '/products'),
    (icon: Icons.shopping_cart_outlined, iconFilled: Icons.shopping_cart, label: 'Panier', route: '/cart'),
    (icon: Icons.receipt_long_outlined, iconFilled: Icons.receipt_long, label: 'Commandes', route: '/orders'),
    (icon: Icons.person_outline, iconFilled: Icons.person, label: 'Profil', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68, // était 64 → +4px de marge de sécurité
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              final showCartBadge = index == 2 && cartCount > 0;

              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.route),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // 8 → 4
                    padding: const EdgeInsets.symmetric(vertical: 4), // 6 → 4
                    decoration: BoxDecoration(
                      // Pill "secondary-container" (#2170E4) du design system Stitch,
                      // conforme au bouton actif de navigation_principale_dekkon.
                      color: isActive ? AppColors.primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // évite que la Column prenne plus que nécessaire
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? item.iconFilled : item.icon,
                              color: isActive
                                  ? AppColors.onPrimary
                                  : AppColors.textDisabled,
                              size: 22, // 24 → 22, gagne un peu de place
                            ),
                            if (showCartBadge)
                              Positioned(
                                top: -2,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.promotionRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '$cartCount',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.onPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2), // 4 → 2
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isActive
                                ? AppColors.onPrimary
                                : AppColors.textDisabled,
                            fontSize: 10, // force une petite taille pour être sûr que ça rentre
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}