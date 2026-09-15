import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/simple_filter_chip.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_payment_model.dart';
import '../providers/admin_payments_provider.dart';
import 'admin_payment_detail_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  final _scrollController = ScrollController();

  static const _statuses = [null, 'PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'REFUNDED'];
  static const _statusLabels = {
    'PENDING': 'En attente',
    'PROCESSING': 'En traitement',
    'SUCCESS': 'Réussis',
    'FAILED': 'Échoués',
    'REFUNDED': 'Remboursés',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminPaymentListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPaymentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
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
                return SimpleFilterChip(
                  label: status == null ? 'Tous' : (_statusLabels[status] ?? status),
                  selected: selected,
                  onTap: () => ref.read(adminPaymentListProvider.notifier).filterByStatus(status),
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const LoadingIndicator()
                : state.error != null
                    ? ErrorView(
                        message: 'Impossible de charger les paiements.',
                        onRetry: () => ref.read(adminPaymentListProvider.notifier).loadFirstPage(),
                      )
                    : state.payments.isEmpty
                        ? const EmptyState(icon: Symbols.payments, title: 'Aucun paiement')
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.payments.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _PaymentTile(payment: state.payments[index]),
                          ),
          ),
          if (state.isLoadingMore)
            const Padding(padding: EdgeInsets.all(12), child: LoadingIndicator(size: 24)),
        ],
      ),
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  final AdminPaymentModel payment;

  const _PaymentTile({required this.payment});

  Color get _statusColor => switch (payment.status) {
        'SUCCESS' => AppColors.primary,
        'PENDING' || 'PROCESSING' => AppColors.secondary,
        'FAILED' => AppColors.error,
        'REFUNDED' => AppColors.textSecondary,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(adminPaymentActionsProvider);
    final orderNumber = payment.order?['order_number'] as String? ?? '';
    final canRefund = payment.status == 'SUCCESS' &&
        ref.watch(employeePermissionsProvider).has(AdminPermissions.paymentsManage);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminPaymentDetailScreen(paymentId: payment.id)),
      ),
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
              Text(orderNumber, style: AppTextStyles.labelMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(payment.status, style: AppTextStyles.caption.copyWith(color: _statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_AdminPaymentsScreenLabels.methodLabels[payment.method] ?? payment.method} · ${Formatters.price(payment.amount)}',
            style: AppTextStyles.bodySmall,
          ),
          if (payment.transactionReference != null)
            Text('Réf: ${payment.transactionReference}', style: AppTextStyles.caption),
          if (canRefund) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Rembourser ce paiement ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final error = await ref.read(adminPaymentActionsProvider.notifier).refund(payment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error ?? 'Paiement remboursé.')),
                          );
                        }
                      }
                    },
              child: const Text('Rembourser'),
            ),
          ],
          ],
        ),
      ),
    );
  }
}

class _AdminPaymentsScreenLabels {
  static const methodLabels = {
    'CASH_ON_DELIVERY': 'À la livraison',
    'MOBILE_MONEY': 'Mobile Money',
    'CARD': 'Carte',
  };
}