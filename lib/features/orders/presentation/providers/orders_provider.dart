import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../checkout/data/models/checkout_model.dart';
import '../../data/repositories/orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(dioProvider));
});

/// Liste des commandes du client, première page uniquement pour l'instant
/// (pagination simple, scroll infini pourra être ajouté comme sur ProductListNotifier).
final ordersListProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final repository = ref.watch(ordersRepositoryProvider);
  final result = await repository.getOrders();
  return result.items;
});

/// Détail d'une commande précise — se rafraîchit automatiquement si l'id change.
final orderDetailProvider = FutureProvider.autoDispose.family<OrderModel, String>((ref, id) async {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getOrder(id);
});

class OrderActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false; // isCancelling

  OrdersRepository get _repository => ref.read(ordersRepositoryProvider);

  Future<bool> cancelOrder(String orderId) async {
    state = true;
    try {
      await _repository.cancelOrder(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(ordersListProvider);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = false;
    }
  }

  Future<Map<String, dynamic>?> retryPayment(String orderId) async {
    state = true;
    try {
      final result = await _repository.initiatePayment(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      return result;
    } catch (e) {
      return null;
    } finally {
      state = false;
    }
  }
}

final orderActionsProvider = NotifierProvider<OrderActionsNotifier, bool>(OrderActionsNotifier.new);