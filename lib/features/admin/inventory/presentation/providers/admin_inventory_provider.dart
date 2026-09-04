import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_inventory_model.dart';
import '../../data/repositories/admin_inventory_repository.dart';

final adminInventoryRepositoryProvider = Provider<AdminInventoryRepository>((ref) {
  return AdminInventoryRepository(ref.watch(dioProvider));
});

class AdminInventoryListState {
  final List<AdminInventoryModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final bool lowStockOnly;
  final String? error;

  AdminInventoryListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.lowStockOnly = false,
    this.error,
  });

  AdminInventoryListState copyWith({
    List<AdminInventoryModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    bool? lowStockOnly,
    String? error,
  }) {
    return AdminInventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      error: error,
    );
  }
}

class AdminInventoryListNotifier extends Notifier<AdminInventoryListState> {
  @override
  AdminInventoryListState build() {
    Future.microtask(loadFirstPage);
    return AdminInventoryListState();
  }

  AdminInventoryRepository get _repository => ref.read(adminInventoryRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getInventory(lowStockOnly: state.lowStockOnly, page: 1);
      state = state.copyWith(
        items: result.items,
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
      final result = await _repository.getInventory(lowStockOnly: state.lowStockOnly, page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void toggleLowStockOnly(bool value) {
    state = state.copyWith(lowStockOnly: value);
    loadFirstPage();
  }
}

final adminInventoryListProvider = NotifierProvider<AdminInventoryListNotifier, AdminInventoryListState>(
  AdminInventoryListNotifier.new,
);

class AdminStockAdjustNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> adjust({
    required String variantId,
    required String type,
    required int quantity,
    String? reason,
  }) async {
    state = true;
    try {
      await ref.read(adminInventoryRepositoryProvider).adjustStock(
            variantId: variantId,
            type: type,
            quantity: quantity,
            reason: reason,
          );
      ref.read(adminInventoryListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminStockAdjustProvider = NotifierProvider<AdminStockAdjustNotifier, bool>(
  AdminStockAdjustNotifier.new,
);