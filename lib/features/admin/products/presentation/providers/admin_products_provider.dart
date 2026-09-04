import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_product_model.dart';
import '../../data/repositories/admin_products_repository.dart';

final adminProductsRepositoryProvider = Provider<AdminProductsRepository>((ref) {
  return AdminProductsRepository(ref.watch(dioProvider));
});

final adminCategoriesProvider = FutureProvider.autoDispose<List<AdminCategoryModel>>((ref) async {
  final repository = ref.watch(adminProductsRepositoryProvider);
  return repository.getCategories();
});

class AdminProductListState {
  final List<AdminProductModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? search;
  final String? categoryId;
  final String? error;

  AdminProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.search,
    this.categoryId,
    this.error,
  });

  AdminProductListState copyWith({
    List<AdminProductModel>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? search,
    String? categoryId,
    bool clearCategory = false,
    String? error,
  }) {
    return AdminProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      error: error,
    );
  }
}

class AdminProductListNotifier extends Notifier<AdminProductListState> {
  @override
  AdminProductListState build() {
    Future.microtask(loadFirstPage);
    return AdminProductListState();
  }

  AdminProductsRepository get _repository => ref.read(adminProductsRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getProducts(
        search: state.search,
        categoryId: state.categoryId,
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
        search: state.search,
        categoryId: state.categoryId,
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

  void search(String query) {
    state = state.copyWith(search: query);
    loadFirstPage();
  }

  void filterByCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
    loadFirstPage();
  }
}

final adminProductListProvider = NotifierProvider<AdminProductListNotifier, AdminProductListState>(
  AdminProductListNotifier.new,
);

final adminProductDetailProvider = FutureProvider.autoDispose.family<AdminProductModel, String>((ref, id) async {
  final repository = ref.watch(adminProductsRepositoryProvider);
  return repository.getProduct(id);
});

class AdminProductCreateResult {
  final AdminProductModel? product;
  final String? error;

  const AdminProductCreateResult({this.product, this.error});
}

class AdminProductFormNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminProductsRepository get _repository => ref.read(adminProductsRepositoryProvider);

  Future<AdminProductCreateResult> createAndReturn(Map<String, dynamic> data) async {
    state = true;
    try {
      final product = await _repository.createProduct(data);
      ref.read(adminProductListProvider.notifier).loadFirstPage();
      return AdminProductCreateResult(product: product);
    } catch (e) {
      return AdminProductCreateResult(error: e.toString());
    } finally {
      state = false;
    }
  }

  Future<AdminProductCreateResult> createFull({
    required Map<String, dynamic> productFields,
    Map<String, dynamic> attributes = const {},
    List<Map<String, dynamic>> variants = const [],
    List<PendingProductImage> images = const [],
  }) async {
    state = true;
    try {
      final product = await _repository.createProductFull(
        productFields: productFields,
        attributes: attributes,
        variants: variants,
        images: images,
      );
      ref.read(adminProductListProvider.notifier).loadFirstPage();
      return AdminProductCreateResult(product: product);
    } catch (e) {
      return AdminProductCreateResult(error: e.toString());
    } finally {
      state = false;
    }
  }

  Future<String?> update(String id, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.updateProduct(id, data);
      ref.invalidate(adminProductDetailProvider(id));
      ref.read(adminProductListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> delete(String id) async {
    state = true;
    try {
      await _repository.deleteProduct(id);
      ref.read(adminProductListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminProductFormProvider = NotifierProvider<AdminProductFormNotifier, bool>(
  AdminProductFormNotifier.new,
);

/// Gère les actions sur les images et variantes d'un produit déjà créé.
class AdminProductAssetsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminProductsRepository get _repository => ref.read(adminProductsRepositoryProvider);

  Future<String?> uploadImage(String productId, XFile file, {bool isPrimary = false}) async {
    state = true;
    try {
      await _repository.uploadImage(productId, file, isPrimary: isPrimary);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> deleteImage(String productId, String imageId) async {
    state = true;
    try {
      await _repository.deleteImage(productId, imageId);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> setPrimaryImage(String productId, String imageId) async {
    state = true;
    try {
      await _repository.setPrimaryImage(productId, imageId);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> createVariant(String productId, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.createVariant(productId, data);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.updateVariant(productId, variantId, data);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> deleteVariant(String productId, String variantId) async {
    state = true;
    try {
      await _repository.deleteVariant(productId, variantId);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  // --- Stock (NOUVEAU) ---

  Future<String?> adjustStock(
    String productId,
    String variantId, {
    required String type,
    required int quantity,
    String? reason,
  }) async {
    state = true;
    try {
      await _repository.adjustStock(variantId, type: type, quantity: quantity, reason: reason);
      ref.invalidate(adminProductDetailProvider(productId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminProductAssetsProvider = NotifierProvider<AdminProductAssetsNotifier, bool>(
  AdminProductAssetsNotifier.new,
);