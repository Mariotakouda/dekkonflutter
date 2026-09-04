import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_delivery_model.dart';
import '../../data/repositories/admin_deliveries_repository.dart';

final adminDeliveriesRepositoryProvider = Provider<AdminDeliveriesRepository>((ref) {
  return AdminDeliveriesRepository(ref.watch(dioProvider));
});

class AdminDeliveryListState {
  final List<AdminDeliveryModel> deliveries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? statusFilter;
  final String? error;

  AdminDeliveryListState({
    this.deliveries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.statusFilter,
    this.error,
  });

  AdminDeliveryListState copyWith({
    List<AdminDeliveryModel>? deliveries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? error,
  }) {
    return AdminDeliveryListState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      error: error,
    );
  }
}

class AdminDeliveryListNotifier extends Notifier<AdminDeliveryListState> {
  @override
  AdminDeliveryListState build() {
    Future.microtask(loadFirstPage);
    return AdminDeliveryListState();
  }

  AdminDeliveriesRepository get _repository => ref.read(adminDeliveriesRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getDeliveries(status: state.statusFilter, page: 1);
      state = state.copyWith(
        deliveries: result.items,
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
      final result = await _repository.getDeliveries(status: state.statusFilter, page: nextPage);
      state = state.copyWith(
        deliveries: [...state.deliveries, ...result.items],
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
}

final adminDeliveryListProvider = NotifierProvider<AdminDeliveryListNotifier, AdminDeliveryListState>(
  AdminDeliveryListNotifier.new,
);

final adminAvailableDriversProvider = FutureProvider.autoDispose<List<AdminDriverModel>>((ref) async {
  final repository = ref.watch(adminDeliveriesRepositoryProvider);
  return repository.getDrivers(status: 'AVAILABLE');
});

class AdminDeliveryActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminDeliveriesRepository get _repository => ref.read(adminDeliveriesRepositoryProvider);

  Future<String?> assignDriver(String deliveryId, String driverId) async {
    state = true;
    try {
      await _repository.assignDriver(deliveryId, driverId);
      ref.read(adminDeliveryListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> updateStatus(String deliveryId, String status, {String? failureReason}) async {
    state = true;
    try {
      await _repository.updateStatus(deliveryId, status, failureReason: failureReason);
      ref.read(adminDeliveryListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminDeliveryActionsProvider = NotifierProvider<AdminDeliveryActionsNotifier, bool>(
  AdminDeliveryActionsNotifier.new,
);