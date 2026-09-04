import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../orders/presentation/widgets/order_status_badge.dart';
import '../providers/admin_orders_provider.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  static const _transitions = {
    'PENDING': ['CONFIRMED', 'CANCELLED'],
    'CONFIRMED': ['PROCESSING', 'CANCELLED'],
    'PROCESSING': ['READY_FOR_DELIVERY', 'CANCELLED'],
    'READY_FOR_DELIVERY': ['ASSIGNED', 'CANCELLED'],
    'ASSIGNED': ['OUT_FOR_DELIVERY', 'CANCELLED'],
    'OUT_FOR_DELIVERY': ['DELIVERED', 'RETURNED'],
  };

  static const _statusLabels = {
    'PENDING': 'En attente',
    'CONFIRMED': 'Confirmée',
    'PROCESSING': 'En préparation',
    'READY_FOR_DELIVERY': 'Prête pour livraison',
    'ASSIGNED': 'Affectée',
    'OUT_FOR_DELIVERY': 'En livraison',
    'DELIVERED': 'Livrée',
    'CANCELLED': 'Annulée',
    'RETURNED': 'Retournée',
  };

  static const _deliveryStatusLabels = {
    'PENDING': "En attente d'affectation",
    'ASSIGNED': 'Livreur affecté',
    'PICKED_UP': 'Colis récupéré',
    'OUT_FOR_DELIVERY': 'En cours de livraison',
    'DELIVERED': 'Livrée',
    'FAILED': 'Échouée',
    'CANCELLED': 'Annulée',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(adminOrderDetailProvider(orderId));
    final isProcessing = ref.watch(adminOrderActionsProvider);
    final permissions = ref.watch(employeePermissionsProvider);
    final canConfirm = permissions.has(AdminPermissions.ordersConfirm);
    final canUpdateStatus = permissions.has(AdminPermissions.ordersUpdate);
    final canCancel = permissions.has(AdminPermissions.ordersCancel);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail commande')),
      body: orderAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger cette commande.',
          onRetry: () => ref.invalidate(adminOrderDetailProvider(orderId)),
        ),
        data: (order) {
          final nextStatuses = _transitions[order.status] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- En-tête ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.orderNumber, style: AppTextStyles.h4),
                            const SizedBox(height: 4),
                            Text(Formatters.dateTime(order.placedAt), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (order.customer != null)
                  _Section(
                    title: 'Client',
                    icon: Icons.person_outline,
                    color: AppColors.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customer!.name, style: AppTextStyles.bodyMedium),
                        if (order.customer!.phone != null)
                          Text(order.customer!.phone!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),

                _Section(
                  title: 'Articles',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.primaryDark,
                  child: Column(
                    children: order.items
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: AppTextStyles.bodyMedium),
                                        Text('Qté: ${item.quantity} · SKU: ${item.sku}', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Text(Formatters.price(item.totalAmount), style: AppTextStyles.labelMedium),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),

                if (order.address != null)
                  _Section(
                    title: 'Adresse de livraison',
                    icon: Icons.location_on_outlined,
                    color: const Color(0xFF2E7D32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${order.address!['recipient_name']} — ${order.address!['phone']}',
                            style: AppTextStyles.bodyMedium),
                        Text(
                          '${order.address!['address_line']}, ${order.address!['district']}, ${order.address!['city']}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                if (order.payments != null && order.payments!.isNotEmpty)
                  _Section(
                    title: 'Paiement',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF0277BD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: order.payments!
                          .map((p) => Text('${p['method']} — ${p['status']}', style: AppTextStyles.bodyMedium))
                          .toList(),
                    ),
                  ),

                if (order.delivery != null)
                  _Section(
                    title: 'Livraison',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFFEF6C00),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _deliveryStatusLabels[order.delivery!['status']] ?? order.delivery!['status'].toString(),
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (order.delivery!['driver_id'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Livreur affecté : ${order.delivery!['driver_id']}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),

                if (order.statusHistory != null && order.statusHistory!.isNotEmpty)
                  _Section(
                    title: 'Historique du statut',
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                    child: Column(
                      children: order.statusHistory!
                          .map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _statusLabels[h['status']] ?? h['status'].toString(),
                                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          if (h['comment'] != null && (h['comment'] as String).isNotEmpty)
                                            Text(h['comment'] as String, style: AppTextStyles.bodySmall),
                                          Text(
                                            [
                                              if (h['changed_by'] != null) h['changed_by'].toString(),
                                              if (h['created_at'] != null)
                                                Formatters.dateTime(DateTime.parse(h['created_at'] as String)),
                                            ].join(' · '),
                                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Column(
                    children: [
                      _Row('Sous-total', Formatters.price(order.subtotal)),
                      if (order.discountAmount > 0) _Row('Remise', '-${Formatters.price(order.discountAmount)}'),
                      _Row('Livraison', Formatters.price(order.deliveryFee)),
                      const Divider(),
                      _Row('Total', Formatters.price(order.totalAmount), isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (order.status == 'PENDING' && canConfirm)
                  CustomButton(
                    label: 'Confirmer la commande',
                    isLoading: isProcessing,
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final error = await ref.read(adminOrderActionsProvider.notifier).confirm(order.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error ?? 'Commande confirmée.')),
                              );
                            }
                          },
                    width: double.infinity,
                  ),

                if (canUpdateStatus && nextStatuses.where((s) => s != 'CANCELLED').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Changer le statut', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: nextStatuses.where((s) => s != 'CANCELLED').map((status) {
                      return OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final error = await ref
                                    .read(adminOrderActionsProvider.notifier)
                                    .updateStatus(order.id, status);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error ?? 'Statut mis à jour.')),
                                  );
                                }
                              },
                        child: Text(_statusLabels[status] ?? status),
                      );
                    }).toList(),
                  ),
                ],

                if (canCancel && nextStatuses.contains('CANCELLED')) ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Annuler la commande',
                    isOutlined: true,
                    isLoading: isProcessing,
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final reasonController = TextEditingController();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Annuler cette commande ?'),
                                content: TextField(
                                  controller: reasonController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Motif (optionnel)',
                                    hintText: 'Ex : rupture de stock, demande du client…',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              final error = await ref
                                  .read(adminOrderActionsProvider.notifier)
                                  .cancel(order.id, reason: reasonController.text.trim());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error ?? 'Commande annulée.')),
                                );
                              }
                            }
                          },
                    width: double.infinity,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _Row(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
          Text(value, style: isBold ? AppTextStyles.priceMedium : AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}