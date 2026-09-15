import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nav_debounce.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/models/products_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    // ============================================================
    // AUTHENTIFICATION
    // ============================================================

    final isAuthenticated =
        ref.watch(authNotifierProvider).isAuthenticated;

    // ============================================================
    // FAVORIS
    // ============================================================

    final isFavoriteAsync = isAuthenticated
        ? ref.watch(isFavoriteProvider(product.id))
        : const AsyncValue<bool>.data(false);

    final isFavorite =
        isFavoriteAsync.value ?? false;

    // ============================================================
    // OUVRIR LE PRODUIT
    // ============================================================

    void openDetail() {
      NavDebounce.run(
        () => context.push(
          '/products/${product.id}',
        ),
      );
    }

    // ============================================================
    // CARTE
    // ============================================================

    return GestureDetector(
      onTap: openDetail,

      child: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow,
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ========================================================
            // IMAGE
            // ========================================================

            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,

                  child: product.primaryImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl:
                              product.primaryImageUrl!,

                          width: double.infinity,

                          fit: BoxFit.cover,

                          placeholder:
                              (context, url) {
                            return Container(
                              color:
                                  AppColors.shimmerBase,

                              child:
                                  const Center(
                                child:
                                    SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },

                          errorWidget:
                              (context, url, error) {
                            return Container(
                              color: AppColors
                                  .surfaceContainerLow,

                              alignment:
                                  Alignment.center,

                              child: const Icon(
                                Symbols
                                    .image_not_supported,
                                color: AppColors
                                    .textDisabled,
                                size: 28,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors
                              .surfaceContainerLow,

                          alignment:
                              Alignment.center,

                          child: const Icon(
                            Symbols.image,
                            color: AppColors
                                .textDisabled,
                            size: 30,
                          ),
                        ),
                ),

                // ====================================================
                // BADGE PROMOTION
                // ====================================================

                if (product.hasDiscount)
                  Positioned(
                    top: 7,
                    left: 7,

                    child: Container(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 48,
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),

                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .promotionRed,

                        borderRadius:
                            BorderRadius.circular(5),
                      ),

                      child: Text(
                        '-${product.discountPercentage.toInt()}%',

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: AppTextStyles
                            .labelSmall
                            .copyWith(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                // ====================================================
                // FAVORIS
                // ====================================================

                Positioned(
                  top: 7,
                  right: 7,

                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.opaque,

                    onTap: () {
                      if (!isAuthenticated) {
                        context.push('/auth');
                        return;
                      }

                      ref
                          .read(
                            favoritesNotifierProvider
                                .notifier,
                          )
                          .toggle(
                            product.id,
                            product: product,
                          );
                    },

                    child: Container(
                      width: 28,
                      height: 28,

                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.92,
                        ),

                        shape:
                            BoxShape.circle,

                        boxShadow:
                            AppTheme.ambientShadow,
                      ),

                      alignment:
                          Alignment.center,

                      child: Icon(
                        Symbols.favorite,

                        fill:
                            isFavorite ? 1 : 0,

                        size: 15,

                        color: isFavorite
                            ? AppColors.error
                            : AppColors
                                .textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ========================================================
            // INFORMATIONS DU PRODUIT
            // ========================================================

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  9,
                  8,
                  9,
                  8,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // NOM
                    // ==================================================

                    Expanded(
                      child: Text(
                        product.name,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style: AppTextStyles
                            .bodyMedium
                            .copyWith(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ==================================================
                    // PRIX + BOUTON
                    // ==================================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,

                      children: [
                        // ------------------------------------------------
                        // PRIX
                        // ------------------------------------------------

                        Expanded(
                          child: Text(
                            Formatters.price(
                              product.price,
                            ),

                            maxLines: 1,

                            overflow:
                                TextOverflow.ellipsis,

                            softWrap: false,

                            style: AppTextStyles
                                .priceMedium,
                          ),
                        ),

                        const SizedBox(width: 5),

                        // ------------------------------------------------
                        // BOUTON +
                        // ------------------------------------------------

                        GestureDetector(
                          behavior:
                              HitTestBehavior.opaque,

                          onTap: openDetail,

                          child: Container(
                            width: 27,
                            height: 27,

                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.primary,
                              shape:
                                  BoxShape.circle,
                            ),

                            alignment:
                                Alignment.center,

                            child: const Icon(
                              Symbols.add,
                              size: 17,
                              color:
                                  AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // ANCIEN PRIX
                    // ==================================================

                    if (product.hasDiscount) ...[
                      const SizedBox(height: 2),

                      SizedBox(
                        height: 16,

                        child: Text(
                          Formatters.price(
                            product.compareAtPrice!,
                          ),

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style: AppTextStyles
                              .priceStrikethrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}