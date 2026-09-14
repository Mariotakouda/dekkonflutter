import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_promotion_model.dart';
import '../providers/admin_promotions_provider.dart';
import '../providers/admin_promotion_products_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminPromotionsScreen extends ConsumerWidget {
  const AdminPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsState = ref.watch(adminPromotionsListProvider);
    final canManage = ref.watch(employeePermissionsProvider).has(AdminPermissions.promotionsManage);

    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showFormDialog(context, ref),
              child: const Icon(Symbols.add, color: Colors.white),
            )
          : null,
      body: promotionsState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les promotions.',
          onRetry: () => ref.invalidate(adminPromotionsListProvider),
        ),
        data: (promotions) {
          if (promotions.isEmpty) {
            return const EmptyState(icon: Symbols.local_offer, title: 'Aucune promotion');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: promotions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _PromotionTile(promotion: promotions[index]),
          );
        },
      ),
    );
  }

  static void _showFormDialog(BuildContext context, WidgetRef ref, {AdminPromotionModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final codeController = TextEditingController(text: existing?.code ?? '');
    final valueController = TextEditingController(text: existing?.value.toStringAsFixed(0) ?? '');
    final minAmountController = TextEditingController(text: existing?.minimumAmount?.toStringAsFixed(0) ?? '');
    String type = existing?.type ?? 'PERCENTAGE';
    bool isActive = existing?.isActive ?? true;
    final Set<String> selectedProductIds = {};

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final productsAsync = dialogRef.watch(adminSelectableProductsProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(existing == null ? 'Nouvelle promotion' : 'Modifier la promotion'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code (ex: PROMO10)'),
                        textCapitalization: TextCapitalization.characters,
                        enabled: existing == null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'PERCENTAGE', child: Text('Pourcentage')),
                          DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Montant fixe')),
                        ],
                        onChanged: (v) => setState(() => type = v ?? 'PERCENTAGE'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: type == 'PERCENTAGE' ? 'Pourcentage' : 'Montant (FCFA)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: minAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Montant minimum (optionnel)'),
                      ),
                      if (existing != null) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                          title: const Text('Active'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Produits concernés (optionnel)', style: AppTextStyles.labelMedium),
                      ),
                      const SizedBox(height: 8),
                      productsAsync.when(
                        loading: () => const LoadingIndicator(),
                        error: (e, _) => const Text('Impossible de charger les produits.'),
                        data: (products) => Column(
                          children: products
                              .map((p) => CheckboxListTile(
                                    dense: true,
                                    value: selectedProductIds.contains(p.id),
                                    title: Text(p.name, style: AppTextStyles.bodySmall),
                                    onChanged: (checked) => setState(() {
                                      if (checked == true) {
                                        selectedProductIds.add(p.id);
                                      } else {
                                        selectedProductIds.remove(p.id);
                                      }
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
                CustomButton(
                  label: existing == null ? 'Créer' : 'Enregistrer',
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) return;
                    final value = double.tryParse(valueController.text.trim());
                    if (value == null) return;

                    final data = {
                      'name': nameController.text.trim(),
                      'code': codeController.text.trim().toUpperCase(),
                      'type': type,
                      'value': value,
                      if (minAmountController.text.trim().isNotEmpty)
                        'minimum_amount': double.tryParse(minAmountController.text.trim()),
                      'is_active': isActive,
                      'product_ids': selectedProductIds.toList(),
                    };

                    final notifier = dialogRef.read(adminPromotionsListProvider.notifier);
                    final error = existing == null
                        ? await notifier.create(data)
                        : await notifier.updatePromotion(existing.id, data);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Promotion enregistrée.')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromotionTile extends ConsumerWidget {
  final AdminPromotionModel promotion;

  const _PromotionTile({required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(employeePermissionsProvider).has(AdminPermissions.promotionsManage);

    return InkWell(
      onTap: !canManage ? null : () => AdminPromotionsScreen._showFormDialog(context, ref, existing: promotion),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow,
          border: promotion.isValid ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: promotion.isValid
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                promotion.valueLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: promotion.isValid ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promotion.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text(promotion.code, style: AppTextStyles.caption),
                  if (promotion.usageLimit != null)
                    Text('${promotion.usageCount}/${promotion.usageLimit} utilisations', style: AppTextStyles.caption),
                ],
              ),
            ),
            if (canManage)
              IconButton(
                icon: const Icon(Symbols.delete, color: AppColors.error, size: 20),
                onPressed: () async {
                  final error = await ref.read(adminPromotionsListProvider.notifier).delete(promotion.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Promotion supprimée.')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}