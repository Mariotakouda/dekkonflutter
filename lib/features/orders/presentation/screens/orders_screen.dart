import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dekkon_bottom_nav.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_status_badge.dart';

/// Filtres de statut affichés dans les chips, conformes à "mes_commandes_dekkon".
/// La valeur `null` correspond au chip "Toutes".
const _statusFilters = <String?, String>{
  null: 'Toutes',
  'PENDING': 'En attente',
  'CONFIRMED': 'Confirmées',
  'PROCESSING': 'En préparation',
  'OUT_FOR_DELIVERY': 'En livraison',
  'DELIVERED': 'Livrées',
  'CANCELLED': 'Annulées',
};

class OrdersScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const OrdersScreen({super.key, this.orderId});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar + filtres, conformes à "mes_commandes_dekkon".
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
                boxShadow: AppTheme.ambientShadow,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mes commandes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary, // token "primary" du design system
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.textSecondary),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: _statusFilters.entries.map((entry) {
                        final selected = _selectedStatus == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedStatus = entry.key),
                            backgroundColor: AppColors.surfaceContainerHigh,
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            side: selected ? BorderSide.none : const BorderSide(color: AppColors.border),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersListProvider),
                child: ordersAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorView(
                    message: 'Impossible de charger vos commandes.',
                    onRetry: () => ref.invalidate(ordersListProvider),
                  ),
                  data: (allOrders) {
                    final orders = _selectedStatus == null
                        ? allOrders
                        : allOrders.where((o) => o.status == _selectedStatus).toList();

                    if (orders.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Aucune commande',
                        subtitle: 'Vos commandes passées apparaîtront ici.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DekkonBottomNav(currentIndex: 3),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order; // OrderModel (défini dans checkout_model.dart)

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.items as List;

    return InkWell(
      onTap: () => context.push('/orders/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderNumber}', style: AppTextStyles.labelLarge),
                    Text(Formatters.dateTime(order.placedAt), style: AppTextStyles.caption),
                  ],
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: List.generate(items.length > 2 ? 2 : items.length, (i) {
                      return Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primaryDark),
                      );
                    }),
                  ),
                ),
                if (items.isNotEmpty)
                  Text(
                    items.length > 2 ? '+${items.length - 2} articles' : '${items.length} article${items.length > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    Text(Formatters.price(order.totalAmount), style: AppTextStyles.labelLarge),
                  ],
                ),
                OutlinedButton(
                  onPressed: () => context.push('/orders/${order.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Voir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}