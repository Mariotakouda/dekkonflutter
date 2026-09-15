import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/simple_filter_chip.dart';
import '../../../../orders/presentation/widgets/order_status_badge.dart';
import '../providers/admin_orders_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  static const _statuses = [
    null,
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'READY_FOR_DELIVERY',
    'ASSIGNED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
  ];

  static const _statusLabels = {
    'PENDING': 'En attente',
    'CONFIRMED': 'Confirmées',
    'PROCESSING': 'En préparation',
    'READY_FOR_DELIVERY': 'Prêtes',
    'ASSIGNED': 'Affectées',
    'OUT_FOR_DELIVERY': 'En livraison',
    'DELIVERED': 'Livrées',
    'CANCELLED': 'Annulées',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminOrderListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminOrderListProvider.notifier).search(value);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOrderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un numéro de commande…',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminOrderListProvider.notifier).search(null);
                          setState(() {});
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) {
                _debounce?.cancel();
                ref.read(adminOrderListProvider.notifier).search(v);
              },
            ),
          ),
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
                return SimpleFilterChip(
                  label: status == null ? 'Toutes' : (_statusLabels[status] ?? status),
                  selected: selected,
                  onTap: () => ref.read(adminOrderListProvider.notifier).filterByStatus(status),
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingIndicator()
                : state.error != null
                    ? ErrorView(
                        message: 'Impossible de charger les commandes.',
                        onRetry: () => ref.read(adminOrderListProvider.notifier).loadFirstPage(),
                      )
                    : state.orders.isEmpty
                        ? const EmptyState(icon: Symbols.receipt_long, title: 'Aucune commande')
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final order = state.orders[index];
                              return InkWell(
                                onTap: () => context.push('/admin/orders/${order.id}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
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
                                          Text(order.orderNumber, style: AppTextStyles.labelMedium),
                                          OrderStatusBadge(status: order.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (order.customer != null)
                                        Text(order.customer!.name, style: AppTextStyles.bodySmall),
                                      const SizedBox(height: 4),
                                      Text(Formatters.dateTime(order.placedAt), style: AppTextStyles.caption),
                                      const SizedBox(height: 6),
                                      Text(Formatters.price(order.totalAmount), style: AppTextStyles.priceMedium),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if (state.isLoadingMore)
            const Padding(padding: EdgeInsets.all(12), child: LoadingIndicator(size: 24)),
        ],
      ),
    );
  }
}