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
import '../../data/models/admin_inventory_model.dart';
import '../providers/admin_inventory_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminInventoryListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
        actions: [
          Row(
            children: [
              Text('Stock faible', style: AppTextStyles.bodySmall),
              Switch(
                value: state.lowStockOnly,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => ref.read(adminInventoryListProvider.notifier).toggleLowStockOnly(v),
              ),
            ],
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null
              ? ErrorView(
                  message: 'Impossible de charger l\'inventaire.',
                  onRetry: () => ref.read(adminInventoryListProvider.notifier).loadFirstPage(),
                )
              : state.items.isEmpty
                  ? const EmptyState(icon: Symbols.inventory_2, title: 'Aucun article')
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _InventoryTile(inventory: state.items[index]),
                    ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final AdminInventoryModel inventory;

  const _InventoryTile({required this.inventory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
        border: inventory.isLowStock
            ? const Border(left: BorderSide(color: AppColors.error, width: 3))
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (inventory.isLowStock) ...[
            const Icon(Symbols.warning_amber_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inventory.variant?.productName ?? '', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('${inventory.variant?.name ?? ''} · ${inventory.variant?.sku ?? ''}', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatChip(label: 'Dispo', value: '${inventory.availableQuantity}', highlight: inventory.isLowStock),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Réservé', value: '${inventory.reservedQuantity}'),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Seuil', value: '${inventory.lowStockThreshold}'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.tune, color: AppColors.primary),
            onPressed: ref.watch(employeePermissionsProvider).has(AdminPermissions.inventoryUpdate)
                ? () => _showAdjustDialog(context, ref, inventory)
                : null,
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref, AdminInventoryModel inventory) {
    showDialog(
      context: context,
      builder: (_) => _AdjustStockDialog(inventory: inventory),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(color: highlight ? AppColors.error : AppColors.textSecondary),
      ),
    );
  }
}

class _AdjustStockDialog extends ConsumerStatefulWidget {
  final AdminInventoryModel inventory;

  const _AdjustStockDialog({required this.inventory});

  @override
  ConsumerState<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<_AdjustStockDialog> {
  String _type = 'IN';
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();

  static const _typeLabels = {
    'IN': 'Entrée de stock',
    'OUT': 'Sortie de stock',
    'ADJUSTMENT': 'Ajustement (valeur exacte)',
  };

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(adminStockAdjustProvider);

    return AlertDialog(
      title: Text('Ajuster : ${widget.inventory.variant?.name ?? ''}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: _typeLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'IN'),
            decoration: const InputDecoration(labelText: 'Type de mouvement'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == 'ADJUSTMENT' ? 'Nouvelle quantité' : 'Quantité',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Raison (optionnel)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        CustomButton(
          label: 'Valider',
          isLoading: isSubmitting,
          onPressed: () async {
            final qty = int.tryParse(_quantityController.text.trim());
            if (qty == null || qty < 1) return;

            final error = await ref.read(adminStockAdjustProvider.notifier).adjust(
                  variantId: widget.inventory.variant?.id ?? '',
                  type: _type,
                  quantity: qty,
                  reason: _reasonController.text.trim(),
                );

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'Stock mis à jour.')),
              );
            }
          },
        ),
      ],
    );
  }
}