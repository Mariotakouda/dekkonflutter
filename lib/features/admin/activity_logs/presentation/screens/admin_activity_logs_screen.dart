import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../data/repositories/admin_activity_logs_repository.dart';
import '../providers/admin_activity_logs_provider.dart';

class AdminActivityLogsScreen extends ConsumerStatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  ConsumerState<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState
    extends ConsumerState<AdminActivityLogsScreen> {
  String? _selectedEntityType;

  // Types d'entités les plus courants du domaine Dekkon, pour un filtrage rapide.
  // La liste reste indicative : le backend accepte n'importe quel entity_type existant.
  static const _entityTypes = [
    null,
    'Product',
    'Order',
    'Payment',
    'Category',
    'Employee',
    'Promotion',
    'Driver',
    'Delivery',
    'Inventory',
  ];

  static const _entityTypeLabels = {
    'Product': 'Produits',
    'Order': 'Commandes',
    'Payment': 'Paiements',
    'Category': 'Catégories',
    'Employee': 'Employés',
    'Promotion': 'Promotions',
    'Driver': 'Livreurs',
    'Delivery': 'Livraisons',
    'Inventory': 'Stock',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminActivityLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Journal d'activité")),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _entityTypes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entityType = _entityTypes[index];
                final selected = _selectedEntityType == entityType;
                return ChoiceChip(
                  label: Text(
                    entityType == null
                        ? 'Toutes'
                        : (_entityTypeLabels[entityType] ?? entityType),
                  ),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedEntityType = entityType),
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const LoadingIndicator(),
              error: (_, _) => ErrorView(
                message: 'Impossible de charger le journal.',
                onRetry: () => ref.invalidate(adminActivityLogsProvider),
              ),
              data: (logs) {
                final filteredLogs = _selectedEntityType == null
                    ? logs
                    : logs
                          .where((log) => log.entityType == _selectedEntityType)
                          .toList();

                if (filteredLogs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'Aucune activité enregistrée',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _LogTile(log: filteredLogs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AdminActivityLogModel log;

  const _LogTile({required this.log});

  IconData get _icon {
    if (log.action.startsWith('order.')) return Icons.receipt_long_outlined;
    if (log.action.startsWith('product.')) return Icons.inventory_2_outlined;
    if (log.action.startsWith('payment.')) return Icons.payments_outlined;
    if (log.action.startsWith('category.')) return Icons.folder_outlined;
    if (log.action.startsWith('employee.') || log.action.startsWith('role.')) {
      return Icons.people_outline;
    }
    if (log.action.startsWith('promotion.')) return Icons.local_offer_outlined;
    if (log.action.startsWith('driver.') || log.action.startsWith('delivery.')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.history;
  }

  Color get _color {
    if (log.action.startsWith('order.')) return AppColors.secondary;
    if (log.action.startsWith('product.')) return AppColors.primaryDark;
    if (log.action.startsWith('payment.')) return const Color(0xFF0277BD);
    if (log.action.startsWith('category.')) return const Color(0xFF00897B);
    if (log.action.startsWith('employee.') || log.action.startsWith('role.')) {
      return const Color(0xFF5E35B1);
    }
    if (log.action.startsWith('promotion.')) return AppColors.promotionRed;
    if (log.action.startsWith('driver.') || log.action.startsWith('delivery.')) {
      return const Color(0xFFEF6C00);
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _color.withValues(alpha: 0.1),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${log.entityType} · ${log.entityId.substring(0, log.entityId.length > 8 ? 8 : log.entityId.length)}',
                  style: AppTextStyles.caption,
                ),
                if (log.user != null)
                  Text(
                    'Par ${log.user!['name']}',
                    style: AppTextStyles.caption,
                  ),
                Text(
                  Formatters.dateTime(log.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
