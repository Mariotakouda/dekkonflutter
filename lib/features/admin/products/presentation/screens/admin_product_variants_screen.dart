import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../data/models/admin_product_model.dart';
import '../providers/admin_products_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminProductVariantsScreen extends ConsumerWidget {
  final String productId;

  const AdminProductVariantsScreen({super.key, required this.productId});

  void _showVariantDialog(BuildContext context, WidgetRef ref, {AdminProductVariantModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final priceController = TextEditingController(text: existing?.price?.toStringAsFixed(0) ?? '');
    final quantityController = TextEditingController(text: existing?.inventory?['quantity']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle variante' : 'Modifier la variante'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom (ex: Noir / M)')),
              const SizedBox(height: 12),
              TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU')),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix spécifique (optionnel)'),
              ),
              if (existing == null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock initial'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          Consumer(
            builder: (context, dialogRef, _) => CustomButton(
              label: existing == null ? 'Créer' : 'Enregistrer',
              onPressed: () async {
                if (nameController.text.trim().isEmpty || skuController.text.trim().isEmpty) return;

                final data = {
                  'name': nameController.text.trim(),
                  'sku': skuController.text.trim(),
                  if (priceController.text.trim().isNotEmpty) 'price': double.tryParse(priceController.text.trim()),
                  if (existing == null) 'initial_quantity': int.tryParse(quantityController.text.trim()) ?? 0,
                };

                final notifier = dialogRef.read(adminProductAssetsProvider.notifier);
                final error = existing == null
                    ? await notifier.createVariant(productId, data)
                    : await notifier.updateVariant(productId, existing.id, data);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Variante enregistrée.')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// NOUVEAU : dialogue d'ajustement de stock pour une variante existante.
  /// Appelle POST /admin/inventory/{variant}/adjust, le seul endpoint qui
  /// modifie réellement l'inventaire.
  void _showStockDialog(BuildContext context, WidgetRef ref, AdminProductVariantModel variant) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    String type = 'IN';

    final currentStock = variant.inventory?['available_quantity'] ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Ajuster le stock — ${variant.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock actuel : $currentStock', style: AppTextStyles.caption),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type de mouvement'),
                  items: const [
                    DropdownMenuItem(value: 'IN', child: Text('Entrée (ajouter)')),
                    DropdownMenuItem(value: 'OUT', child: Text('Sortie (retirer)')),
                    DropdownMenuItem(value: 'ADJUSTMENT', child: Text('Ajustement (valeur exacte)')),
                  ],
                  onChanged: (v) => setLocalState(() => type = v ?? 'IN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == 'ADJUSTMENT' ? 'Nouvelle quantité totale' : 'Quantité',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Raison (optionnel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            Consumer(
              builder: (context, dialogRef, _) => CustomButton(
                label: 'Valider',
                onPressed: () async {
                  final qty = int.tryParse(qtyController.text.trim());
                  if (qty == null || qty <= 0) return;

                  final error = await dialogRef.read(adminProductAssetsProvider.notifier).adjustStock(
                        productId,
                        variant.id,
                        type: type,
                        quantity: qty,
                        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                      );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Stock ajusté.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(adminProductDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Variantes du produit')),
      body: productAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les variantes.',
          onRetry: () => ref.invalidate(adminProductDetailProvider(productId)),
        ),
        data: (product) {
          final variants = product.variants;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  label: 'Ajouter une variante',
                  icon: Symbols.add,
                  onPressed: () => _showVariantDialog(context, ref),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: variants.isEmpty
                      ? const Center(child: Text('Aucune variante pour ce produit.'))
                      : ListView.separated(
                          itemCount: variants.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final variant = variants[index];
                            final stock = variant.inventory?['available_quantity'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppTheme.ambientShadow,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(variant.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                        Text('${variant.sku} · Stock: $stock', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Symbols.inventory_2, size: 18, color: AppColors.primary),
                                    tooltip: 'Ajuster le stock',
                                    onPressed: () => _showStockDialog(context, ref, variant),
                                  ),
                                  IconButton(
                                    icon: const Icon(Symbols.edit, size: 18),
                                    onPressed: () => _showVariantDialog(context, ref, existing: variant),
                                  ),
                                  IconButton(
                                    icon: const Icon(Symbols.delete, size: 18, color: AppColors.error),
                                    onPressed: () async {
                                      final error =
                                          await ref.read(adminProductAssetsProvider.notifier).deleteVariant(productId, variant.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(error ?? 'Variante supprimée.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
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