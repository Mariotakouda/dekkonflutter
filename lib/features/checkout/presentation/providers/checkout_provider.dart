import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../data/models/checkout_model.dart';
import '../../data/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(dioProvider));
});

enum PaymentMethodOption { cashOnDelivery, mobileMoney, card }

extension PaymentMethodOptionX on PaymentMethodOption {
  String get apiValue => switch (this) {
        PaymentMethodOption.cashOnDelivery => 'CASH_ON_DELIVERY',
        PaymentMethodOption.mobileMoney => 'MOBILE_MONEY',
        PaymentMethodOption.card => 'CARD',
      };

  String get label => switch (this) {
        PaymentMethodOption.cashOnDelivery => 'Paiement à la livraison',
        PaymentMethodOption.mobileMoney => 'Mobile Money',
        PaymentMethodOption.card => 'Carte bancaire',
      };
}

class CheckoutState {
  final bool isSubmitting;
  final String? error;
  final OrderModel? placedOrder;

  CheckoutState({this.isSubmitting = false, this.error, this.placedOrder});

  CheckoutState copyWith({bool? isSubmitting, String? error, OrderModel? placedOrder}) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      placedOrder: placedOrder ?? this.placedOrder,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => CheckoutState();

  CheckoutRepository get _repository => ref.read(checkoutRepositoryProvider);

  Future<bool> submitOrder({
    required String addressId,
    required PaymentMethodOption paymentMethod,
    String? promotionCode,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final order = await _repository.placeOrder(
        addressId: addressId,
        paymentMethod: paymentMethod.apiValue,
        promotionCode: promotionCode,
        notes: notes,
      );

      state = state.copyWith(isSubmitting: false, placedOrder: order);

      // Rafraîchit le panier (désormais vide/converti côté backend).
      ref.invalidate(cartNotifierProvider);

      // Rafraîchit "Mes commandes" pour que la commande qu'on vient de
      // passer apparaisse immédiatement. Sans ça, comme l'onglet Commandes
      // reste monté en permanence dans le StatefulShellRoute, le
      // FutureProvider.autoDispose garde son ancien résultat en cache et la
      // nouvelle commande n'apparaît qu'après un redémarrage complet de l'app.
      ref.invalidate(ordersListProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> initiatePayment(String orderId) async {
    try {
      return await _repository.initiatePayment(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void reset() {
    state = CheckoutState();
  }
}

final checkoutNotifierProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);