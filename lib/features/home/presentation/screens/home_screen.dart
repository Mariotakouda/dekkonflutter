import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dekkon_drawer.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/dekkon_logo.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../categories/presentation/widgets/category_chip.dart';

import '../../../products/presentation/providers/products_provider.dart';
import '../../../products/presentation/widgets/product_card.dart';

import '../widgets/section_header.dart';
import '../widgets/promo_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final newProductsAsync = ref.watch(newProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      drawer: const DekkonDrawer(),

      body: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // HEADER FIXE
            // ============================================================

            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),

                child: _HomeHeader(
                  onNotificationsTap: () {
                    context.push('/notifications');
                  },

                  onSearchTap: () {
                    context.go('/products');
                  },
                ),
              ),
            ),

            // ============================================================
            // ZONE SCROLLABLE
            // ============================================================

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(featuredProductsProvider);
                  ref.invalidate(newProductsProvider);
                },

                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 24,
                  ),

                  children: [
                    // ======================================================
                    // BANNIÈRE PROMOTIONNELLE
                    // ======================================================

                    PromoBanner(
                      onDiscoverTap: () {
                        context.go('/products');
                      },
                    ),

                    const SizedBox(height: 24),

                    // ======================================================
                    // CATÉGORIES
                    // ======================================================

                    SectionHeader(
                      title: 'Catégories',

                      onSeeAll: () {
                        context.push('/categories');
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 112,

                      child: categoriesAsync.when(
                        // ------------------------------------------------
                        // LOADING
                        // ------------------------------------------------

                        loading: () {
                          return const LoadingIndicator();
                        },

                        // ------------------------------------------------
                        // ERROR
                        // ------------------------------------------------

                        error: (error, stackTrace) {
                          return const SizedBox.shrink();
                        },

                        // ------------------------------------------------
                        // DATA
                        // ------------------------------------------------

                        data: (categories) {
                          if (categories.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          const double chipEstimatedWidth = 76.0;

                          final screenWidth =
                              MediaQuery.sizeOf(context).width;

                          final availableWidth =
                              screenWidth - 32;

                          final totalChipsWidth =
                              categories.length * chipEstimatedWidth;

                          final fitsOnScreen =
                              totalChipsWidth <= availableWidth;

                          // ------------------------------------------------
                          // LES CATÉGORIES TIENNENT SUR L'ÉCRAN
                          // ------------------------------------------------

                          if (fitsOnScreen) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: categories.map(
                                  (category) {
                                    return Flexible(
                                      child: CategoryChip(
                                        category: category,

                                        onTap: () {
                                          _openCategory(
                                            context,
                                            category,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            );
                          }

                          // ------------------------------------------------
                          // TROP DE CATÉGORIES
                          // SCROLL HORIZONTAL
                          // ------------------------------------------------

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,

                            physics:
                                const BouncingScrollPhysics(),

                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),

                            itemCount: categories.length,

                            separatorBuilder: (_, _) {
                              return const SizedBox(
                                width: 12,
                              );
                            },

                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final category =
                                  categories[index];

                              return CategoryChip(
                                category: category,

                                onTap: () {
                                  _openCategory(
                                    context,
                                    category,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ======================================================
                    // PRODUITS VEDETTES
                    // ======================================================

                    SectionHeader(
                      title: 'Produits vedettes',

                      onSeeAll: () {
                        context.push(
                          '/products?featured=true',
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    featuredAsync.when(
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------

                      loading: () {
                        return const SizedBox(
                          height: 240,
                          child: LoadingIndicator(),
                        );
                      },

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------

                      error: (error, stackTrace) {
                        return const SizedBox.shrink();
                      },

                      // ------------------------------------------------
                      // DATA
                      // ------------------------------------------------

                      data: (products) {
                        return _ProductGrid(
                          products: products,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ======================================================
                    // NOUVEAUTÉS
                    // ======================================================

                    SectionHeader(
                      title: 'Nouveautés',

                      onSeeAll: () {
                        context.go('/products');
                      },
                    ),

                    const SizedBox(height: 12),

                    newProductsAsync.when(
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------

                      loading: () {
                        return const SizedBox(
                          height: 240,
                          child: LoadingIndicator(),
                        );
                      },

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------

                      error: (error, stackTrace) {
                        return const ErrorView(
                          message:
                              'Impossible de charger les nouveautés.',
                        );
                      },

                      // ------------------------------------------------
                      // DATA
                      // ------------------------------------------------

                      data: (products) {
                        return _HorizontalProductList(
                          products: products,
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OUVRIR UNE CATÉGORIE
  // ================================================================

  static void _openCategory(
    BuildContext context,
    dynamic category,
  ) {
    if (category.children.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoriesScreen(
            title: category.name,
            categories: category.children,
            parentId: category.id,
            parentName: category.name,
          ),
        ),
      );
    } else {
      context.push(
        '/products?category_id=${category.id}',
      );
    }
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _HomeHeader extends ConsumerWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onSearchTap;

  const _HomeHeader({
    required this.onNotificationsTap,
    required this.onSearchTap,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final initial =
        (user?.customer?.firstName.isNotEmpty ?? false)
            ? user!.customer!.firstName[0].toUpperCase()
            : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        0,
      ),

      child: SizedBox(
        height: 56,

        child: Row(
          children: [
            // ============================================================
            // LOGO
            // ============================================================

            const Flexible(
              child: DekkonLogo(
                height: 36,
              ),
            ),

            const Spacer(),

            // ============================================================
            // RECHERCHE
            // ============================================================

            IconButton(
              tooltip: 'Rechercher',

              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),

              padding: EdgeInsets.zero,

              icon: const Icon(
                Symbols.search,
                color: AppColors.primary,
              ),

              onPressed: onSearchTap,
            ),

            // ============================================================
            // NOTIFICATIONS
            // ============================================================

            Stack(
              clipBehavior: Clip.none,

              children: [
                IconButton(
                  tooltip: 'Notifications',

                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),

                  padding: EdgeInsets.zero,

                  icon: const Icon(
                    Symbols.notifications,
                    color: AppColors.primary,
                  ),

                  onPressed: onNotificationsTap,
                ),

                Positioned(
                  top: 7,
                  right: 7,

                  child: IgnorePointer(
                    child: Container(
                      width: 9,
                      height: 9,

                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),

            // ============================================================
            // AVATAR
            // ============================================================

            GestureDetector(
              onTap: () {
                context.go('/profile');
              },

              child: Container(
                padding: const EdgeInsets.all(2),

                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: AppColors.surfaceContainerHigh,
                    width: 1,
                  ),
                ),

                child: CircleAvatar(
                  radius: 15,

                  backgroundColor:
                      AppColors.surfaceContainerHigh,

                  child: Text(
                    initial,

                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GRILLE DES PRODUITS VEDETTES
// ============================================================================

class _ProductGrid extends StatelessWidget {
  final List products;

  const _ProductGrid({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 100,

        child: Center(
          child: Text(
            'Aucun produit pour le moment.',
          ),
        ),
      );
    }

    final screenWidth =
        MediaQuery.sizeOf(context).width;

    // ================================================================
    // ADAPTATION DU NOMBRE DE COLONNES
    // ================================================================

    int crossAxisCount;

    if (screenWidth < 360) {
      crossAxisCount = 2;
    } else if (screenWidth < 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      child: GridView.builder(
        shrinkWrap: true,

        physics:
            const NeverScrollableScrollPhysics(),

        itemCount: products.length,

        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,

          mainAxisSpacing: 12,
          crossAxisSpacing: 8,

          // ============================================================
          // IMPORTANT
          // On donne suffisamment de hauteur aux cartes pour éviter
          // les RenderFlex overflow.
          // ============================================================

          childAspectRatio:
              screenWidth < 360
                  ? 0.68
                  : 0.64,
        ),

        itemBuilder: (
          context,
          index,
        ) {
          return ProductCard(
            product: products[index],
          );
        },
      ),
    );
  }
}

// ============================================================================
// LISTE HORIZONTALE DES NOUVEAUTÉS
// ============================================================================

class _HorizontalProductList
    extends StatelessWidget {
  final List products;

  const _HorizontalProductList({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 100,

        child: Center(
          child: Text(
            'Aucun produit pour le moment.',
          ),
        ),
      );
    }

    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final cardWidth =
        screenWidth < 360
            ? 145.0
            : 160.0;

    return SizedBox(
      height: 270,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        physics:
            const BouncingScrollPhysics(),

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),

        itemCount: products.length,

        separatorBuilder: (_, _) {
          return const SizedBox(
            width: 12,
          );
        },

        itemBuilder: (
          context,
          index,
        ) {
          return SizedBox(
            width: cardWidth,

            child: ProductCard(
              product: products[index],
            ),
          );
        },
      ),
    );
  }
}