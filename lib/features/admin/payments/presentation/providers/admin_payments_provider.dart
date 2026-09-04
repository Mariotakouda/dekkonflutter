import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_payment_model.dart';
import '../../data/repositories/admin_payments_repository.dart';

final adminPaymentsRepositoryProvider = Provider<AdminPaymentsRepository>((ref) {
  return AdminPaymentsRepository(ref.watch(dioProvider));
});

class AdminPaymentListState {
  final List<AdminPaymentModel> payments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? statusFilter;
  final String? error;

  AdminPaymentListState({
    this.payments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.statusFilter,
    this.error,
  });

  AdminPaymentListState copyWith({
    List<AdminPaymentModel>? payments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? error,
  }) {
    return AdminPaymentListState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      error: error,
    );
  }
}

class AdminPaymentListNotifier extends Notifier<AdminPaymentListState> {
  @override
  AdminPaymentListState build() {
    Future.microtask(loadFirstPage);
    return AdminPaymentListState();
  }

  AdminPaymentsRepository get _repository => ref.read(adminPaymentsRepositoryProvider);

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getPayments(status: state.statusFilter, page: 1);
      state = state.copyWith(
        payments: result.items,
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
      final result = await _repository.getPayments(status: state.statusFilter, page: nextPage);
      state = state.copyWith(
        payments: [...state.payments, ...result.items],
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

final adminPaymentListProvider = NotifierProvider<AdminPaymentListNotifier, AdminPaymentListState>(
  AdminPaymentListNotifier.new,
);

final adminPaymentDetailProvider = FutureProvider.autoDispose.family<AdminPaymentModel, String>((ref, id) async {
  final repository = ref.watch(adminPaymentsRepositoryProvider);
  return repository.getPayment(id);
});

class AdminPaymentActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> refund(String paymentId, {String? reason}) async {
    state = true;
    try {
      await ref.read(adminPaymentsRepositoryProvider).refundPayment(paymentId, reason: reason);
      ref.invalidate(adminPaymentDetailProvider(paymentId));
      ref.read(adminPaymentListProvider.notifier).loadFirstPage();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminPaymentActionsProvider = NotifierProvider<AdminPaymentActionsNotifier, bool>(
  AdminPaymentActionsNotifier.new,
);