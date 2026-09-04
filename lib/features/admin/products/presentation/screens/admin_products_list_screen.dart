import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../data/models/admin_product_model.dart';
import '../providers/admin_products_provider.dart';
import 'admin_product_create_screen.dart';
import 'admin_product_detail_screen.dart';

class AdminProductsListScreen extends ConsumerStatefulWidget {
  const AdminProductsListScreen({super.key});

  @override
  ConsumerState<AdminProductsListScreen> createState() => _AdminProductsListScreenState();
}

class _AdminProductsListScreenState extends ConsumerState<AdminProductsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminProductListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProductListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produits')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminProductCreateScreen()),
          );
          if (created == true) ref.read(adminProductListProvider.notifier).loadFirstPage();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (v) => ref.read(adminProductListProvider.notifier).search(v.trim()),
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingIndicator()
                : state.error != null
                    ? ErrorView(
                        message: 'Impossible de charger les produits.',
                        onRetry: () => ref.read(adminProductListProvider.notifier).loadFirstPage(),
                      )
                    : state.products.isEmpty
                        ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'Aucun produit')
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: state.products.length,
                            itemBuilder: (context, index) => _ProductTile(product: state.products[index]),
                          ),
          ),
          if (state.isLoadingMore)
            const Padding(padding: EdgeInsets.all(12), child: LoadingIndicator(size: 24)),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final AdminProductModel product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminProductDetailScreen(productId: product.id)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.ambientShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.primaryImageUrl != null
                        ? CachedNetworkImage(imageUrl: product.primaryImageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.background,
                            child: const Icon(Icons.image_outlined, color: AppColors.textDisabled),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (product.status == 'ACTIVE' ? AppColors.primary : AppColors.textDisabled)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.status == 'ACTIVE' ? 'Actif' : product.status,
                        style: AppTextStyles.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.sku,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(Formatters.price(product.price), style: AppTextStyles.priceMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}