import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../products/presentation/widgets/product_grid.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesNotifierProvider);
    final notifier = ref.read(favoritesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes favoris'), centerTitle: true),
      body: favoritesState.when(
        // skipLoadingOnReload : le refetch déclenché après un toggle ne doit
        // plus faire clignoter tout l'écran, la liste est déjà à jour
        // localement grâce à la mise à jour optimiste dans le notifier.
        skipLoadingOnReload: true,
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger vos favoris.',
          onRetry: () => ref.invalidate(favoritesNotifierProvider),
        ),
        data: (_) {
          final products = notifier.products;

          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Aucun favori',
              subtitle: 'Ajoutez des produits à vos favoris pour les retrouver ici.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Retrouvez les articles que vous avez aimés.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Expanded(child: ProductGrid(products: products)),
            ],
          );
        },
      ),
    );
  }
}
