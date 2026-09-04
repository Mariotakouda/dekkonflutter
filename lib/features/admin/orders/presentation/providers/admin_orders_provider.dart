import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/repositories/admin_orders_repository.dart';

final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>((ref) {
  return AdminOrdersRepository(ref.watch(dioProvider));
});

class AdminOrderListState {
  final List<AdminOrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? statusFilter;
  final String? searchQuery;
  final String? error;

  AdminOrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.statusFilter,
    this.searchQuery,
    this.error,
  });

  AdminOrderListState copyWith({
    List<AdminOrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? error,
  }) {
    return AdminOrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      error: error,
    );
  }
}

class AdminOrderListNotifier extends Notifier<AdminOrderListState> {
  @override
  AdminOrderListState build() {
    Future.microtask(loadFirstPage);
    return AdminOrderListState();
  }

  AdminOrdersRepository get _repository => ref.read(adminOrdersRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getOrders(
        status: state.statusFilter,
        search: state.searchQuery,
        page: 1,
      );
      state = state.copyWith(
        orders: result.items,
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
      final result = await _repository.getOrders(
        status: state.statusFilter,
        search: state.searchQuery,
        page: nextPage,
      );
      state = state.copyWith(
        orders: [...state.orders, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void filterByStatus(String? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    loadFirstPage();
  }

  void search(String? query) {
    final trimmed = query?.trim();
    state = state.copyWith(
      searchQuery: trimmed,
      clearSearchQuery: trimmed == null || trimmed.isEmpty,
    );
    loadFirstPage();
  }
}

final adminOrderListProvider = NotifierProvider<AdminOrderListNotifier, AdminOrderListState>(
  AdminOrderListNotifier.new,
);

final adminOrderDetailProvider = FutureProvider.autoDispose.family<AdminOrderModel, String>((ref, id) async {
  final repository = ref.watch(adminOrdersRepositoryProvider);
  return repository.getOrder(id);
});

class AdminOrderActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminOrdersRepository get _repository => ref.read(adminOrdersRepositoryProvider);

  Future<String?> confirm(String orderId) async {
    state = true;
    try {
      await _repository.confirmOrder(orderId);
      ref.invalidate(adminOrderDetailProvider(orderId));
      ref.read(adminOrderListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> updateStatus(String orderId, String status, {String? comment}) async {
    state = true;
    try {
      await _repository.updateStatus(orderId, status, comment: comment);
      ref.invalidate(adminOrderDetailProvider(orderId));
      ref.read(adminOrderListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> cancel(String orderId, {String? reason}) async {
    state = true;
    try {
      await _repository.cancelOrder(orderId, reason: reason);
      ref.invalidate(adminOrderDetailProvider(orderId));
      ref.read(adminOrderListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminOrderActionsProvider = NotifierProvider<AdminOrderActionsNotifier, bool>(
  AdminOrderActionsNotifier.new,
);