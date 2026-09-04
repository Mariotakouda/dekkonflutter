import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/models/products_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Même logique de favoris que sur ProductDetailScreen : on n'appelle
    // /favorites/check que si l'utilisateur est connecté.
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
    final isFavoriteAsync = isAuthenticated
        ? ref.watch(isFavoriteProvider(product.id))
        : const AsyncValue<bool>.data(false);
    final isFavorite = isFavoriteAsync.value ?? false;

    void openDetail() => context.push('/products/${product.id}');

    return GestureDetector(
      onTap: openDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: product.primaryImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.shimmerBase),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceContainerLow,
                            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textDisabled),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.image_outlined, color: AppColors.textDisabled, size: 32),
                        ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.promotionRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toInt()}%',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (!isAuthenticated) {
                        context.push('/auth');
                        return;
                      }
                      ref.read(favoritesNotifierProvider.notifier).toggle(product.id, product: product);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.ambientShadow,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFavorite ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Formatters.price(product.price),
                          style: AppTextStyles.priceMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: openDetail,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 18, color: AppColors.onPrimary),
                        ),
                      ),
                    ],
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      Formatters.price(product.compareAtPrice!),
                      style: AppTextStyles.priceStrikethrough,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}