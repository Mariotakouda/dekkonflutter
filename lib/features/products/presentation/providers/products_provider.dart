import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/products_model.dart';
import '../../data/repositories/products_repository.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(dioProvider));
});

/// Produits vedettes pour la home — chargés une fois, cache automatique via FutureProvider.
final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productsRepositoryProvider);
  final result = await repository.getProducts(featured: true);
  return result.items;
});

/// Nouveautés pour la home.
final newProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productsRepositoryProvider);
  final result = await repository.getProducts(sort: 'newest');
  return result.items;
});

/// Détail d'un produit — paramétré par id, se recalcule si l'id change.
final productDetailProvider = FutureProvider.family<ProductModel, String>((ref, id) async {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getProduct(id);
});

/// État de la recherche/filtre catalogue (géré séparément, voir ProductListNotifier plus bas).
class ProductListParams {
  final String? search;
  final String? categoryId;
  final String sort;

  const ProductListParams({this.search, this.categoryId, this.sort = 'newest'});

  ProductListParams copyWith({String? search, String? categoryId, String? sort}) {
    return ProductListParams(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      sort: sort ?? this.sort,
    );
  }
}

class ProductListState {
  final List<ProductModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ProductListState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

/// Sentinel utilisé par [ProductListNotifier.updateFilters] pour distinguer
/// "paramètre non fourni" de "paramètre explicitement remis à null".
/// Avant ce correctif, `categoryId: null` (ex: bouton "Tous") était perdu
/// car `copyWith` faisait `categoryId ?? this.categoryId`, qui retombe sur
/// l'ancienne valeur dès que `null` est passé — impossible de réinitialiser
/// le filtre catégorie une fois qu'il avait été positionné une fois.
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class ProductListNotifier extends Notifier<ProductListState> {
  ProductListParams _params = const ProductListParams();

  @override
  ProductListState build() {
    Future.microtask(loadFirstPage);
    return ProductListState();
  }

  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getProducts(
        search: _params.search,
        categoryId: _params.categoryId,
        sort: _params.sort,
        page: 1,
      );

      state = state.copyWith(
        products: result.items,
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getProducts(
        search: _params.search,
        categoryId: _params.categoryId,
        sort: _params.sort,
        page: nextPage,
      );

      state = state.copyWith(
        products: [...state.products, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Met à jour un ou plusieurs filtres. Utilise un sentinel (`_unset`) pour
  /// que passer explicitement `null` (ex: catégorie "Tous") efface bien le
  /// filtre au lieu de le laisser inchangé.
  void updateFilters({
    Object? search = _unset,
    Object? categoryId = _unset,
    Object? sort = _unset,
  }) {
    _params = ProductListParams(
      search: identical(search, _unset) ? _params.search : search as String?,
      categoryId: identical(categoryId, _unset) ? _params.categoryId : categoryId as String?,
      sort: identical(sort, _unset) ? _params.sort : (sort as String? ?? _params.sort),
    );
    loadFirstPage();
  }
}

final productListProvider = NotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);