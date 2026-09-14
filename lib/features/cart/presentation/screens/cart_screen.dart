import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/dekkon_logo.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/models/cart_model.dart';
import '../providers/cart_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            cartState.when(
              loading: () => const _CartHeader(showLogo: true),
              error: (_, _) => const _CartHeader(title: 'Mon panier'),
              data: (cart) => _CartHeader(showLogo: !(cart == null || cart.isEmpty)),
            ),
            Expanded(
              child: cartState.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => ErrorView(
                  message: 'Impossible de charger le panier.',
                  onRetry: () => ref.read(cartNotifierProvider.notifier).refresh(),
                ),
                data: (cart) {
                  if (cart == null || cart.isEmpty) {
                    return EmptyState(
                      icon: Symbols.shopping_bag,
                      title: 'Votre panier est vide',
                      subtitle: 'Parcourez nos catégories et trouvez les articles qui vous plaisent.',
                      action: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        child: const Text('Découvrir les produits'),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (cart.hasUnavailableItems)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: AppColors.errorContainer,
                          child: Row(
                            children: [
                              const Icon(Symbols.error, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Certains articles ne sont plus disponibles en quantité suffisante.',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _CartItemTile(item: cart.items[index]),
                        ),
                      ),
                      _CartSummary(cart: cart),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TopAppBar conforme aux maquettes Stitch "panier_dekkon" / "panier_vide_dekkon" :
/// icône menu à gauche, titre centré (logo Dekkon si le panier contient des
/// articles, "Mon panier" s'il est vide), icône recherche à droite.
/// Fond : dégradé orange -> blanc commun à toutes les pages principales.
class _CartHeader extends StatelessWidget {
  final bool showLogo;
  final String title;

  const _CartHeader({this.showLogo = false, this.title = 'Mon panier'});

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.menu, color: Colors.white),
                onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
              ),
              Expanded(
                child: Center(
                  child: showLogo
                      ? const DekkonLogo(height: 24)
                      : Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              IconButton(
                icon: const Icon(Symbols.search, color: Colors.white),
                // go() et non push() : '/products' est un onglet de la coquille.
                onPressed: () => context.go('/products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItemModel item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.shopping_bag, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(item.variantName, style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Text(Formatters.price(item.unitPrice), style: AppTextStyles.priceMedium),
                if (!item.isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Stock insuffisant (${item.availableQuantity} dispo.)',
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Symbols.delete, size: 20, color: AppColors.error),
                onPressed: () => notifier.removeItem(item.id),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyBtn(
                      icon: Symbols.remove,
                      onTap: item.quantity > 1
                          ? () => notifier.updateItem(itemId: item.id, quantity: item.quantity - 1)
                          : null,
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${item.quantity}', textAlign: TextAlign.center, style: AppTextStyles.labelMedium),
                    ),
                    _QtyBtn(
                      icon: Symbols.add,
                      onTap: () => notifier.updateItem(itemId: item.id, quantity: item.quantity + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: onTap == null ? AppColors.textDisabled : AppColors.textPrimary),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartModel cart;

  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Résumé', style: AppTextStyles.h4),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total (${cart.items.length})', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                Text(Formatters.price(cart.subtotal), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Frais de livraison', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                Text("Calculé à l'étape suivante", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total', style: AppTextStyles.h4),
                Text(Formatters.price(cart.subtotal), style: AppTextStyles.priceLarge),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: cart.hasUnavailableItems ? null : () => context.push('/checkout'),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Passer la commande'),
                  SizedBox(width: 8),
                  Icon(Symbols.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}