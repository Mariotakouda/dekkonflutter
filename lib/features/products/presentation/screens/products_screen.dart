import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/simple_filter_chip.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/data/models/categories_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_grid.dart';

/// Aplatit l'arbre catégories/sous-catégories en une liste plate pour la
/// barre de filtres rapides. Sans ça, seules les catégories racines
/// (ex: "Électronique") étaient proposées comme puces, alors que les
/// produits sont rattachés aux sous-catégories (ex: "Téléphones") — filtrer
/// sur la catégorie racine ne matchait donc aucun produit et affichait
/// "Aucun produit trouvé" bien que le catalogue soit non vide.
/// `depth` sert à préfixer visuellement les sous-catégories dans la puce.
class _FlatCategory {
  final CategoryModel category;
  final int depth;
  const _FlatCategory(this.category, this.depth);
}

List<_FlatCategory> _flattenCategories(List<CategoryModel> categories, [int depth = 0]) {
  final result = <_FlatCategory>[];
  for (final c in categories) {
    result.add(_FlatCategory(c, depth));
    if (c.children.isNotEmpty) {
      result.addAll(_flattenCategories(c.children, depth + 1));
    }
  }
  return result;
}

class ProductsScreen extends ConsumerStatefulWidget {
  final String? productId;
  final String? initialCategoryId;
  final bool initialFeaturedOnly;

  const ProductsScreen({
    super.key,
    this.productId,
    this.initialCategoryId,
    this.initialFeaturedOnly = false, String? initialSearch,
  });

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedCategoryId;
  final String _selectedSort = 'newest';
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(productListProvider.notifier).updateFilters(
            categoryId: _selectedCategoryId,
            sort: _selectedSort,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(productListProvider.notifier).updateFilters(
          search: _searchController.text.trim(),
          categoryId: _selectedCategoryId,
          sort: _selectedSort,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // TopAppBar conforme à "catalogue_dekkon" : retour + titre + icônes
          // recherche / filtre (tune) / tri (sort).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(bottom: BorderSide(color: AppColors.border)),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Catalogue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary, // token "primary" du design system
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _searchExpanded = !_searchExpanded),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                      onPressed: () {
                        // TODO: brancher sur l'écran "filtres_catalogue_dekkon".
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, color: AppColors.textSecondary),
                      onPressed: () {
                        // TODO: brancher sur l'écran "tri_catalogue_dekkon".
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_searchExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: AppColors.surface,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onSubmitted: (_) => _applyFilters(),
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (categories) {
              // Catégories ET sous-catégories aplaties : "Téléphones" doit
              // pouvoir être sélectionné directement, pas seulement
              // "Électronique" (voir commentaire sur _flattenCategories).
              final flat = _flattenCategories(categories);
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    SimpleFilterChip(
                      label: 'Tous',
                      selected: _selectedCategoryId == null,
                      onTap: () {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...flat.map((fc) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SimpleFilterChip(
                            // Préfixe "› " pour montrer visuellement qu'il
                            // s'agit d'une sous-catégorie (ex: "› Téléphones").
                            label: fc.depth == 0 ? fc.category.name : '›  ${fc.category.name}',
                            selected: _selectedCategoryId == fc.category.id,
                            onTap: () {
                              setState(() => _selectedCategoryId = fc.category.id);
                              _applyFilters();
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          Expanded(
            child: state.isLoading
                ? const LoadingIndicator()
                : state.error != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Erreur de chargement',
                        subtitle: state.error!,
                      )
                    : state.products.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Aucun produit trouvé',
                            subtitle: 'Essayez une autre recherche ou catégorie.',
                          )
                        : ProductGrid(
                            products: state.products,
                            scrollController: _scrollController,
                          ),
          ),

          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LoadingIndicator(size: 24),
            ),
        ],
      ),
    );
  }
}