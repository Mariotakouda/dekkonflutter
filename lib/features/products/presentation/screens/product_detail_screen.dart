import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/models/products_model.dart';
import '../providers/products_provider.dart';
import '../widgets/variant_selector.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariantModel? _selectedVariant;
  int _quantity = 1;

  void _initVariant(ProductModel product) {
    if (_selectedVariant == null && product.variants.isNotEmpty) {
      _selectedVariant = product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Permet de recharger le produit (stock, images...) sans quitter
          // l'écran, plutôt que de dépendre uniquement du cache Riverpod.
          ref.invalidate(productDetailProvider(widget.productId));
          await ref.read(productDetailProvider(widget.productId).future);
        },
        child: productAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorView(
            message: 'Impossible de charger ce produit.',
            onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
          ),
          data: (product) {
            _initVariant(product);
            return _ProductDetailContent(
              product: product,
              selectedVariant: _selectedVariant,
              quantity: _quantity,
              onSelectVariant: (v) => setState(() => _selectedVariant = v),
              onQuantityChanged: (q) => setState(() => _quantity = q),
            );
          },
        ),
      ),
      bottomNavigationBar: productAsync.when(
        loading: () => null,
        error: (e, _) => null,
        data: (product) => _AddToCartBar(
          product: product,
          selectedVariant: _selectedVariant,
          quantity: _quantity,
        ),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerWidget {
  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final int quantity;
  final void Function(ProductVariantModel) onSelectVariant;
  final void Function(int) onQuantityChanged;

  const _ProductDetailContent({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
    required this.onSelectVariant,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
    // On n'appelle /favorites/check que si connecté : pour un invité, ça
    // renverrait un 401 pour rien (l'icône reste simplement "non favori").
    final isFavoriteAsync = isAuthenticated
        ? ref.watch(isFavoriteProvider(product.id))
        : const AsyncValue<bool>.data(false);
    final isAvailable = selectedVariant?.inStock ?? false;
    final price = selectedVariant?.price ?? product.price;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 360, // proche des 390px de la maquette Stitch
          pinned: true,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _CircleIconButton(
              icon: Symbols.arrow_back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleIconButton(
                icon: Symbols.favorite,
                filled: isFavoriteAsync.value ?? false,
                iconColor: (isFavoriteAsync.value ?? false) ? AppColors.error : AppColors.outline,
                onTap: () {
                  if (!isAuthenticated) {
                    context.push(
                      '/auth',
                      extra: AuthScreenArgs(redirectTo: '/products/${product.id}'),
                    );
                    return;
                  }
                  ref.read(favoritesNotifierProvider.notifier).toggle(product.id, product: product);
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            // NOUVEAU : vrai carrousel swipable au lieu d'une image statique
            // avec de faux points décoratifs.
            background: _ProductImageGallery(images: product.images),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brand != null)
                  Text(product.brand!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(product.name, style: AppTextStyles.h3),
                const SizedBox(height: 8),

                if (product.averageRating != null)
                  Row(
                    children: [
                      Icon(Symbols.star_rounded, size: 18, color: AppColors.promotionYellow.withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text(product.averageRating!.toStringAsFixed(1), style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 10,
                        children: [
                          Text(Formatters.price(price), style: AppTextStyles.priceLarge),
                          if (product.hasDiscount)
                            Text(Formatters.price(product.compareAtPrice!), style: AppTextStyles.priceStrikethrough),
                        ],
                      ),
                    ),
                    if (product.hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.onErrorContainer, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      isAvailable ? Symbols.check_circle : Symbols.cancel,
                      size: 16,
                      color: isAvailable ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvailable ? 'En stock' : 'Rupture de stock',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isAvailable ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                const SizedBox(height: 4),
                VariantSelector(
                  variants: product.variants,
                  selected: selectedVariant,
                  onSelect: onSelectVariant,
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('Quantité', style: AppTextStyles.labelMedium),
                      const Spacer(),
                      _QuantitySelector(
                        quantity: quantity,
                        onChanged: onQuantityChanged,
                        maxQuantity: selectedVariant?.availableQuantity ?? 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (product.description != null) ...[
                  Text('Description', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  _ExpandableDescription(text: product.description!),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// NOUVEAU : galerie photo swipable avec indicateurs de page réels.
/// Remplace l'ancien Stack statique (image unique + points décoratifs figés).
class _ProductImageGallery extends StatefulWidget {
  final List<ProductImageModel> images;

  const _ProductImageGallery({required this.images});

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerLow,
        child: const Center(
          child: Icon(Symbols.image_not_supported, size: 48, color: AppColors.textDisabled),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, i) => CachedNetworkImage(
            imageUrl: widget.images[i].url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.surfaceContainerLow),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceContainerLow,
              child: const Icon(Symbols.broken_image, color: AppColors.textDisabled),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive ? AppColors.primaryDark : AppColors.border,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool filled;

  const _CircleIconButton({required this.icon, required this.onTap, this.iconColor, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, fill: filled ? 1 : 0, size: 20, color: iconColor ?? AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final int quantity;

  const _AddToCartBar({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
    if (!isAuthenticated) {
      NavDebounce.run(() => context.push(
            '/auth',
            extra: AuthScreenArgs(redirectTo: '/products/${widget.product.id}'),
          ));
      return;
    }

    final variant = widget.selectedVariant;
    if (variant == null) return;

    setState(() => _isAdding = true);
    final error = await ref.read(cartNotifierProvider.notifier).addItem(
          productVariantId: variant.id,
          quantity: widget.quantity,
        );
    if (!mounted) return;
    setState(() => _isAdding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Ajouté au panier.'),
        // `context.go` et non `context.push` : '/cart' est un onglet de la
        // coquille à navigation (StatefulShellRoute), et cet écran de détail
        // est lui-même empilé au-dessus de cette coquille. Un `push` y
        // empilerait une SECONDE instance complète de la coquille par-dessus
        // la première (deux mêmes GlobalKey en simultané → crash
        // "!keyReservation.contains(key)" / HeroControllerScope, écran rouge).
        // `go` réutilise la coquille déjà présente et bascule juste l'onglet.
        action: error == null
            ? SnackBarAction(label: 'Voir le panier', onPressed: () => context.go('/cart'))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.selectedVariant?.inStock ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: (isAvailable && !_isAdding) ? _addToCart : null,
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(52),
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.shopping_cart, size: 18),
                    const SizedBox(width: 8),
                    Text(isAvailable ? 'Ajouter au panier' : 'Rupture de stock'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final void Function(int) onChanged;

  const _QuantitySelector({required this.quantity, required this.maxQuantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyButton(icon: Symbols.remove, onTap: quantity > 1 ? () => onChanged(quantity - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$quantity', style: AppTextStyles.labelLarge),
        ),
        _QtyButton(
          icon: Symbols.add,
          onTap: quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.textDisabled : AppColors.textPrimary),
      ),
    );
  }
}

/// Description tronquée à 3 lignes avec bouton "Lire plus", conforme à la
/// maquette Stitch "d_tail_produit_dekkon" (line-clamp-3).
class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        if (!_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Text(
                'Lire plus',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}