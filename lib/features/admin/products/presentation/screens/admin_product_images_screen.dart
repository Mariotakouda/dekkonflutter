import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../providers/admin_products_provider.dart';

class AdminProductImagesScreen extends ConsumerWidget {
  final String productId;

  const AdminProductImagesScreen({super.key, required this.productId});

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, {required bool isPrimary}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final error = await ref.read(adminProductAssetsProvider.notifier).uploadImage(productId, file, isPrimary: isPrimary);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Image ajoutée.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(adminProductDetailProvider(productId));
    final isSubmitting = ref.watch(adminProductAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Images du produit')),
      body: productAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les images.',
          onRetry: () => ref.invalidate(adminProductDetailProvider(productId)),
        ),
        data: (product) {
          final images = product.images;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  label: 'Ajouter une image',
                  icon: Icons.add_photo_alternate_outlined,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : () => _pickAndUpload(context, ref, isPrimary: images.isEmpty),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: images.isEmpty
                      ? const EmptyState(icon: Icons.image_outlined, title: 'Aucune image pour ce produit')
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(imageUrl: image.url, fit: BoxFit.cover),
                                  ),
                                ),
                                if (image.isPrimary)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(100)),
                                      child: const Text('Principale', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final error =
                                          await ref.read(adminProductAssetsProvider.notifier).deleteImage(productId, image.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(error ?? 'Image supprimée.')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (!image.isPrimary)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final error = await ref
                                            .read(adminProductAssetsProvider.notifier)
                                            .setPrimaryImage(productId, image.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(error ?? 'Image principale définie.')),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const Icon(Icons.star_border, size: 14, color: AppColors.secondary),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}