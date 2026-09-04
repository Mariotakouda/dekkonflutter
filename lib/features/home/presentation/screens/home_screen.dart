import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dekkon_bottom_nav.dart';
import '../../../../core/widgets/dekkon_drawer.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
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
            // --- Zone fixe : ne scroll jamais ---
            _HomeHeader(onNotificationsTap: () => context.push('/notifications')),
            const SizedBox(height: 12),
            _SearchBar(onTap: () => context.push('/products')),
            const SizedBox(height: 8),

            // --- Zone scrollable : tout le reste ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(featuredProductsProvider);
                  ref.invalidate(newProductsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  children: [
                    PromoBanner(onDiscoverTap: () => context.push('/products')),
                    const SizedBox(height: 24),

                    SectionHeader(title: 'Catégories', onSeeAll: () => context.push('/categories')),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 112,
                      child: categoriesAsync.when(
                        loading: () => const LoadingIndicator(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (categories) {
                          // Si peu de catégories, on les répartit sur toute la largeur
                          // au lieu de les laisser collées à gauche dans un scroll horizontal.
                          const chipEstimatedWidth = 76.0;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final totalChipsWidth = categories.length * chipEstimatedWidth;
                          final fitsOnScreen = totalChipsWidth < (screenWidth - 32);

                          if (fitsOnScreen) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: categories.map((category) {
                                  return CategoryChip(
                                    category: category,
                                    onTap: () {
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
                                        context.push('/products?category_id=${category.id}');
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          }

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return CategoryChip(
                                category: category,
                                onTap: () {
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
                                    context.push('/products?category_id=${category.id}');
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    SectionHeader(title: 'Produits vedettes', onSeeAll: () => context.push('/products?featured=true')),
                    const SizedBox(height: 12),
                    featuredAsync.when(
                      loading: () => const SizedBox(height: 240, child: LoadingIndicator()),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (products) => _ProductGrid(products: products),
                    ),
                    const SizedBox(height: 24),

                    SectionHeader(title: 'Nouveautés', onSeeAll: () => context.push('/products')),
                    const SizedBox(height: 12),
                    newProductsAsync.when(
                      loading: () => const SizedBox(height: 240, child: LoadingIndicator()),
                      error: (e, _) => const ErrorView(message: 'Impossible de charger les nouveautés.'),
                      data: (products) => _HorizontalProductList(products: products),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DekkonBottomNav(currentIndex: 0),
    );
  }
}

/// TopAppBar fixe, conforme à la maquette Stitch "accueil_dekkon" :
/// icône notifications (avec pastille) à gauche, titre "Dekkon" centré,
/// icône recherche à droite.
class _HomeHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const _HomeHeader({required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                onPressed: onNotificationsTap,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.surface, width: 1)),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                'Dekkon',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary, // token "primary" (#00236F) du design system
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () => context.push('/products'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16), // "rounded-lg" du design system Stitch
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Row(
            children: const [
              Icon(Icons.search, color: AppColors.outline),
              SizedBox(width: 10),
              Text('Rechercher un produit...', style: TextStyle(color: AppColors.textDisabled)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grille 2 colonnes pour "Produits Populaires", comme sur la maquette.
class _ProductGrid extends StatelessWidget {
  final List products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Aucun produit pour le moment.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  final List products;

  const _HorizontalProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Aucun produit pour le moment.')),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 160,
          child: ProductCard(product: products[index]),
        ),
      ),
    );
  }
}