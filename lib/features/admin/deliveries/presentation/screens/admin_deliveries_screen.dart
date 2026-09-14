import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_delivery_model.dart';
import '../providers/admin_deliveries_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminDeliveriesScreen extends ConsumerStatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  ConsumerState<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends ConsumerState<AdminDeliveriesScreen> {
  final _scrollController = ScrollController();

  static const _statuses = [null, 'PENDING', 'ASSIGNED', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED', 'FAILED'];
  static const _statusLabels = {
    'PENDING': 'En attente',
    'ASSIGNED': 'Affectées',
    'PICKED_UP': 'Récupérées',
    'OUT_FOR_DELIVERY': 'En livraison',
    'DELIVERED': 'Livrées',
    'FAILED': 'Échouées',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminDeliveryListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDeliveryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Livraisons')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final selected = state.statusFilter == status;
                return ChoiceChip(
                  label: Text(status == null ? 'Toutes' : (_statusLabels[status] ?? status)),
                  selected: selected,
                  onSelected: (_) => ref.read(adminDeliveryListProvider.notifier).filterByStatus(status),
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingIndicator()
                : state.error != null
                    ? ErrorView(
                        message: 'Impossible de charger les livraisons.',
                        onRetry: () => ref.read(adminDeliveryListProvider.notifier).loadFirstPage(),
                      )
                    : state.deliveries.isEmpty
                        ? const EmptyState(icon: Symbols.local_shipping, title: 'Aucune livraison')
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.deliveries.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _DeliveryTile(delivery: state.deliveries[index]),
                          ),
          ),
          if (state.isLoadingMore)
            const Padding(padding: EdgeInsets.all(12), child: LoadingIndicator(size: 24)),
        ],
      ),
    );
  }
}

class _DeliveryTile extends ConsumerWidget {
  final AdminDeliveryModel delivery;

  const _DeliveryTile({required this.delivery});

  static const _statusLabels = {
    'PENDING': 'En attente',
    'ASSIGNED': 'Affectée',
    'PICKED_UP': 'Récupérée',
    'OUT_FOR_DELIVERY': 'En livraison',
    'DELIVERED': 'Livrée',
    'FAILED': 'Échouée',
    'CANCELLED': 'Annulée',
  };

  static const _nextStatus = {
    'ASSIGNED': 'PICKED_UP',
    'PICKED_UP': 'OUT_FOR_DELIVERY',
    'OUT_FOR_DELIVERY': 'DELIVERED',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(adminDeliveryActionsProvider);
    final orderNumber = delivery.order?['order_number'] as String? ?? '';
    final next = _nextStatus[delivery.status];
    final canManage = ref.watch(employeePermissionsProvider).has(AdminPermissions.deliveriesManage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: AppTextStyles.labelMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabels[delivery.status] ?? delivery.status, style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            delivery.driver != null ? 'Livreur : ${delivery.driver!.name}' : 'Aucun livreur affecté',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (delivery.status == 'FAILED' && delivery.failureReason != null && delivery.failureReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Motif : ${delivery.failureReason}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (canManage && delivery.status == 'PENDING')
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _showAssignDialog(context, ref),
                    child: const Text('Affecter un livreur'),
                  ),
                ),
              if (canManage && next != null) ...[
                if (delivery.status == 'PENDING') const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: _statusLabels[next] ?? next,
                    isLoading: isProcessing,
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final error = await ref
                                .read(adminDeliveryActionsProvider.notifier)
                                .updateStatus(delivery.id, next);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error ?? 'Statut mis à jour.')),
                              );
                            }
                          },
                  ),
                ),
              ],
              if (canManage &&
                  ['ASSIGNED', 'PICKED_UP', 'OUT_FOR_DELIVERY'].contains(delivery.status)) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Marquer comme échouée',
                  icon: const Icon(Symbols.report_problem, color: AppColors.error),
                  onPressed: isProcessing ? null : () => _showFailDialog(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showFailDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Signaler un échec de livraison'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motif',
            hintText: 'Ex : client absent, adresse introuvable…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          Consumer(
            builder: (context, dialogRef, _) => TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                final error = await dialogRef.read(adminDeliveryActionsProvider.notifier).updateStatus(
                      delivery.id,
                      'FAILED',
                      failureReason: reasonController.text.trim(),
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Livraison marquée comme échouée.')),
                  );
                }
              },
              child: const Text('Confirmer'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final driversAsync = dialogRef.watch(adminAvailableDriversProvider);

          return AlertDialog(
            title: const Text('Affecter un livreur'),
            content: driversAsync.when(
              loading: () => const SizedBox(height: 80, child: LoadingIndicator()),
              error: (e, _) => const Text('Impossible de charger les livreurs.'),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return const Text('Aucun livreur disponible actuellement.');
                }
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return ListTile(
                        title: Text(driver.name),
                        subtitle: Text(driver.vehicleType ?? ''),
                        onTap: () async {
                          final error = await dialogRef
                              .read(adminDeliveryActionsProvider.notifier)
                              .assignDriver(delivery.id, driver.id);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? 'Livreur affecté.')),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }
}