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
import '../providers/admin_payments_provider.dart';

class AdminPaymentDetailScreen extends ConsumerWidget {
  final String paymentId;

  const AdminPaymentDetailScreen({super.key, required this.paymentId});

  static const _statusLabels = {
    'PENDING': 'En attente',
    'PROCESSING': 'En traitement',
    'SUCCESS': 'Réussi',
    'FAILED': 'Échoué',
    'REFUNDED': 'Remboursé',
  };

  static const _methodLabels = {
    'CASH_ON_DELIVERY': 'À la livraison',
    'MOBILE_MONEY': 'Mobile Money',
    'CARD': 'Carte',
  };

  Color _statusColor(String status) => switch (status) {
        'SUCCESS' => AppColors.primary,
        'PENDING' || 'PROCESSING' => AppColors.secondary,
        'FAILED' => AppColors.error,
        'REFUNDED' => AppColors.textSecondary,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(adminPaymentDetailProvider(paymentId));
    final isProcessing = ref.watch(adminPaymentActionsProvider);
    final canRefund = ref.watch(employeePermissionsProvider).has(AdminPermissions.paymentsManage);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail paiement')),
      body: paymentAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger ce paiement.',
          onRetry: () => ref.invalidate(adminPaymentDetailProvider(paymentId)),
        ),
        data: (payment) {
          final orderNumber = payment.order?['order_number'] as String? ?? '';
          final canActuallyRefund = canRefund && payment.status == 'SUCCESS';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0277BD).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0277BD), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(orderNumber, style: AppTextStyles.h4),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor(payment.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _statusLabels[payment.status] ?? payment.status,
                          style: AppTextStyles.caption.copyWith(color: _statusColor(payment.status)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Column(
                    children: [
                      _Row('Montant', Formatters.price(payment.amount), isBold: true),
                      const Divider(),
                      _Row('Méthode', _methodLabels[payment.method] ?? payment.method),
                      if (payment.provider != null) _Row('Fournisseur', payment.provider!),
                      if (payment.transactionReference != null)
                        _Row('Référence transaction', payment.transactionReference!),
                      if (payment.paidAt != null) _Row('Payé le', Formatters.dateTime(payment.paidAt!)),
                      _Row('Créé le', Formatters.dateTime(payment.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (canActuallyRefund)
                  CustomButton(
                    label: 'Rembourser ce paiement',
                    isOutlined: true,
                    isLoading: isProcessing,
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
                    width: double.infinity,
                  ),
              ],
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isBold ? AppTextStyles.priceMedium : AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}