import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../../../core/errors/app_exception.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});

class CartNotifier extends AsyncNotifier<CartModel?> {
  CartRepository get _repository => ref.read(cartRepositoryProvider);

  @override
  Future<CartModel?> build() async {
    return _repository.getCart();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCart());
  }

  Future<String?> addItem({required String productVariantId, required int quantity}) async {
    try {
      final cart = await _repository.addItem(productVariantId: productVariantId, quantity: quantity);
      state = AsyncValue.data(cart);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateItem({required String itemId, required int quantity}) async {
    try {
      final cart = await _repository.updateItem(itemId: itemId, quantity: quantity);
      state = AsyncValue.data(cart);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<void> removeItem(String itemId) async {
    final cart = await _repository.removeItem(itemId);
    state = AsyncValue.data(cart);
  }
}

final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, CartModel?>(CartNotifier.new);

/// Nombre d'articles dans le panier — pratique pour un badge sur l'icône panier.
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartNotifierProvider).value;
  return cart?.itemCount ?? 0;
});