import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/products_model.dart';
import '../../data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(dioProvider));
});

/// Vérifie si un produit précis est en favori — utilisé sur ProductDetailScreen.
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, productId) async {
  // On dépend de favoritesNotifierProvider pour se recalculer après un toggle.
  final favoriteIds = ref.watch(favoritesNotifierProvider).value ?? [];
  return favoriteIds.contains(productId);
});

/// Liste complète des favoris (produits), state géré pour un toggle instantané dans l'UI.
class FavoritesNotifier extends AsyncNotifier<List<String>> {
  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  FavoritesRepository get _repository => ref.read(favoritesRepositoryProvider);

  @override
  Future<List<String>> build() async {
    final favorites = await _repository.getFavorites();
    _products = favorites;
    return favorites.map((p) => p.id).toList();
  }

  /// [product] est optionnel mais doit être fourni par les écrans qui ont
  /// déjà l'objet produit en main (ProductCard, ProductDetailScreen) afin
  /// que la liste `_products` reste synchronisée avec `state` pendant la
  /// mise à jour optimiste — sinon FavoritesScreen affiche des données
  /// périmées tant que le refetch réseau n'est pas terminé.
  Future<void> toggle(String productId, {ProductModel? product}) async {
    final currentIds = state.value ?? [];
    final previousProducts = _products;
    final isFav = currentIds.contains(productId);

    // Mise à jour optimiste de l'état pour une UI instantanée.
    if (isFav) {
      state = AsyncValue.data(currentIds.where((id) => id != productId).toList());
      _products = _products.where((p) => p.id != productId).toList();
    } else {
      state = AsyncValue.data([...currentIds, productId]);
      if (product != null && !_products.any((p) => p.id == productId)) {
        _products = [..._products, product];
      }
    }

    try {
      if (isFav) {
        await _repository.removeFavorite(productId);
      } else {
        await _repository.addFavorite(productId);
      }
      // Refetch en arrière-plan pour rester la source de vérité (ex: si le
      // produit ajouté n'était pas encore connu côté client) — n'affiche
      // plus de loading grâce à skipLoadingOnReload côté FavoritesScreen.
      ref.invalidateSelf();
    } catch (e) {
      // Rollback en cas d'échec réseau.
      state = AsyncValue.data(currentIds);
      _products = previousProducts;
    }
  }
}

final favoritesNotifierProvider = AsyncNotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);
