import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_header.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

// Couleur des éléments inactifs.
// On conserve la couleur actuelle de ton thème.
const _kNavInactiveColor = Color(0xFF1A1A1A);

/// Coquille persistante des 5 onglets principaux.
///
/// Utilisée par le StatefulShellRoute.indexedStack dans app_router.dart.
/// Chaque onglet conserve sa propre pile de navigation et son état.
class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  // ---------------------------------------------------------------------------
  // ONGLET DE NAVIGATION
  // ---------------------------------------------------------------------------
  static const _items = [
    (
      icon: Symbols.home,
      iconFilled: Symbols.home,
      label: 'Accueil',
    ),
    (
      icon: Symbols.grid_view,
      iconFilled: Symbols.grid_view,
      label: 'Catalogue',
    ),
    (
      icon: Symbols.shopping_cart,
      iconFilled: Symbols.shopping_cart,
      label: 'Panier',
    ),
    (
      icon: Symbols.receipt_long,
      iconFilled: Symbols.receipt_long,
      label: 'Commandes',
    ),
    (
      icon: Symbols.person,
      iconFilled: Symbols.person,
      label: 'Profil',
    ),
  ];

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,

      // =========================================================================
      // BARRE DE NAVIGATION FLOTTANTE
      // =========================================================================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            0,
            12,
            10,
          ),
          child: Container(
            // Barre volontairement compacte.
            height: 64,

            decoration: BoxDecoration(
              color: AppColors.surface,

              // Forme arrondie comme sur la référence.
              borderRadius: BorderRadius.circular(34),

              // Ombre légère.
              boxShadow: [
                BoxShadow(
                  color: AppColors.ambientShadow.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),

              child: Row(
                children: List.generate(
                  _items.length,
                  (index) {
                    final item = _items[index];

                    final isActive =
                        index == currentIndex;

                    final showCartBadge =
                        index == 2 && cartCount > 0;

                    final color = isActive
                        ? kHeaderGradientTop
                        : _kNavInactiveColor;

                    return Expanded(
                      child: Material(
                        color: Colors.transparent,

                        child: InkWell(
                          onTap: () => _onTap(index),

                          borderRadius:
                              BorderRadius.circular(30),

                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),

                            curve: Curves.easeOut,

                            decoration: BoxDecoration(
                              // Fond très discret uniquement
                              // pour l'onglet actif.
                              color: isActive
                                  ? kHeaderGradientTop.withValues(
                                      alpha: 0.10,
                                    )
                                  : Colors.transparent,

                              borderRadius:
                                  BorderRadius.circular(30),
                            ),

                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [
                                // =================================================
                                // ICÔNE
                                // =================================================
                                SizedBox(
                                  height: 28,

                                  child: Stack(
                                    clipBehavior:
                                        Clip.none,

                                    alignment:
                                        Alignment.center,

                                    children: [
                                      Icon(
                                        isActive
                                            ? item.iconFilled
                                            : item.icon,

                                        fill: isActive
                                            ? 1
                                            : 0,

                                        color: color,

                                        // Taille réduite pour correspondre
                                        // à la référence.
                                        size: 24,
                                      ),

                                      // ===========================================
                                      // BADGE DU PANIER
                                      // ===========================================
                                      if (showCartBadge)
                                        Positioned(
                                          top: -4,
                                          right: -7,

                                          child: Container(
                                            constraints:
                                                const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),

                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 3,
                                              vertical: 1,
                                            ),

                                            decoration:
                                                BoxDecoration(
                                              color: AppColors
                                                  .promotionRed,

                                              shape:
                                                  BoxShape.circle,

                                              border:
                                                  Border.all(
                                                color:
                                                    AppColors
                                                        .surface,
                                                width: 1.5,
                                              ),
                                            ),

                                            child: Text(
                                              '$cartCount',

                                              textAlign:
                                                  TextAlign
                                                      .center,

                                              style:
                                                  AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                color:
                                                    Colors.white,

                                                fontSize: 9,

                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // =================================================
                                // ESPACE ENTRE ICÔNE ET TEXTE
                                // =================================================
                                const SizedBox(
                                  height: 2,
                                ),

                                // =================================================
                                // TEXTE
                                // =================================================
                                Text(
                                  item.label,

                                  maxLines: 1,

                                  overflow:
                                      TextOverflow.ellipsis,

                                  textAlign:
                                      TextAlign.center,

                                  style:
                                      AppTextStyles
                                          .labelSmall
                                          .copyWith(
                                    color: color,

                                    // Texte plus petit.
                                    fontSize: 10,

                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w500,

                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}