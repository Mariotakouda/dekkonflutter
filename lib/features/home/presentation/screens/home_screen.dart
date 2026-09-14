import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dekkon_drawer.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../categories/presentation/widgets/category_chip.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../widgets/section_header.dart';
import '../widgets/promo_banner.dart';
import '../../../../core/widgets/dekkon_logo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Dégradé de la zone haute de l'accueil : orange vif en haut (sous la barre
// de statut) qui s'éclaircit progressivement jusqu'au blanc.
const _headerGradientTop = Color(0xFFFF7A2E);
const _headerGradientBottom = Colors.white;

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
            // Dégradé orange -> blanc derrière le header (plus de barre de
            // recherche ici : la loupe est passée en icône dans le header).
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_headerGradientTop, _headerGradientBottom],
                  stops: [0.0, 0.85],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HomeHeader(
                  onNotificationsTap: () => context.push('/notifications'),
                  onSearchTap: () => context.go('/products'),
                ),
              ),
            ),

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
                    PromoBanner(onDiscoverTap: () => context.go('/products')),
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

                    SectionHeader(title: 'Nouveautés', onSeeAll: () => context.go('/products')),
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
    );
  }
}

/// TopAppBar fixe, conforme à la maquette Stitch "accueil_dekkon" :
/// logo à gauche, icônes recherche + notifications et avatar à droite.
///
/// Fond transparent : c'est le dégradé orange -> blanc défini dans
/// [HomeScreen] qui se voit à travers. Icônes/avatar passés en blanc pour
/// rester lisibles sur l'orange.
class _HomeHeader extends ConsumerWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onSearchTap;

  const _HomeHeader({required this.onNotificationsTap, required this.onSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final initial = (user?.customer?.firstName.isNotEmpty ?? false)
        ? user!.customer!.firstName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const DekkonLogo(height: 22),
            const Spacer(),
            IconButton(
              icon: const Icon(Symbols.search, color: Colors.white),
              onPressed: onSearchTap,
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Symbols.notifications, color: Colors.white),
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
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Text(
                    initial,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
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