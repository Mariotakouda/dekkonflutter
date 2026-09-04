import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/admin_product_model.dart';
import '../../../products/presentation/providers/admin_products_provider.dart';

/// Liste légère de produits (première page) pour peupler le sélecteur d'association promo.
final adminSelectableProductsProvider = FutureProvider.autoDispose<List<AdminProductModel>>((ref) async {
  final repository = ref.watch(adminProductsRepositoryProvider);
  final result = await repository.getProducts(page: 1);
  return result.items;
});