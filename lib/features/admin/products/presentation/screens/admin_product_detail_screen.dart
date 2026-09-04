import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../providers/admin_products_provider.dart';
import 'admin_product_edit_screen.dart';
import 'admin_product_images_screen.dart';
import 'admin_product_variants_screen.dart';

class AdminProductDetailScreen extends ConsumerWidget {
  final String productId;

  const AdminProductDetailScreen({super.key, required this.productId});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref.read(adminProductFormProvider.notifier).delete(productId);
      if (!context.mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(adminProductDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdminProductEditScreen(productId: productId)),
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref)),
        ],
      ),
      body: productAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger ce produit.',
          onRetry: () => ref.invalidate(adminProductDetailProvider(productId)),
        ),
        data: (product) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (product.primaryImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: CachedNetworkImage(imageUrl: product.primaryImageUrl!, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  height: 140,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.textDisabled)),
                ),
              const SizedBox(height: 16),
              Text(product.name, style: AppTextStyles.h4),
              Text(product.sku, style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Text(Formatters.price(product.price), style: AppTextStyles.priceLarge),
              if (product.description != null) ...[
                const SizedBox(height: 12),
                Text(product.description!, style: AppTextStyles.bodyMedium),
              ],
              const SizedBox(height: 24),
              _ActionTile(
                icon: Icons.photo_library_outlined,
                label: 'Gérer les images (${product.images.length})',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminProductImagesScreen(productId: productId)),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.style_outlined,
                label: 'Gérer les variantes (${product.variants.length})',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminProductVariantsScreen(productId: productId)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}