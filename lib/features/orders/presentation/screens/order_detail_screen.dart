import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../reviews/presentation/widgets/review_form_dialog.dart';
import '../providers/orders_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Les 5 étapes du suivi de commande, conformes à "d_tail_commande_dekkon".
const _timelineSteps = ['Commande passée', 'Confirmée', 'Préparation', 'En livraison', 'Livrée'];

int _stepIndexFor(String status) => switch (status) {
      'PENDING' => 0,
      'CONFIRMED' => 1,
      'PROCESSING' || 'READY_FOR_DELIVERY' || 'ASSIGNED' => 2,
      'OUT_FOR_DELIVERY' => 3,
      'DELIVERED' => 4,
      _ => 0, // CANCELLED / RETURNED / REFUNDED : pas de timeline pertinente
    };

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  static const _paymentStatusLabels = {
    'PENDING': 'En attente de paiement',
    'PROCESSING': 'Paiement en cours',
    'SUCCESS': 'Payé',
    'FAILED': 'Échec du paiement',
    'REFUNDED': 'Remboursé',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final isCancelling = ref.watch(orderActionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: orderAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorView(
            message: 'Impossible de charger cette commande.',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
          data: (order) {
            final canCancel = ['PENDING', 'CONFIRMED'].contains(order.status);
            final isCancelled = ['CANCELLED', 'RETURNED', 'REFUNDED'].contains(order.status);
            final paymentStatus = order.payment?['status'] as String?;
            final canRetryPayment = order.status != 'CANCELLED' &&
                order.payment != null &&
                order.payment!['method'] != 'CASH_ON_DELIVERY' &&
                (paymentStatus == 'PENDING' || paymentStatus == 'FAILED');
            final stepIndex = _stepIndexFor(order.status);

            return Column(
              children: [
                // TopAppBar conforme à "d_tail_commande_dekkon" : retour + "Commande #XXX".
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.arrow_back, color: AppColors.textSecondary),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            // Arrivé ici juste après un checkout : celui-ci
                            // utilise context.go() qui vide la pile de
                            // navigation, donc il n'y a rien à pop. On
                            // retombe sur la liste des commandes.
                            context.go('/orders');
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Commande #${order.orderNumber}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Carte statut + timeline verticale ---
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCancelled ? 'Annulée' : _timelineSteps[stepIndex],
                                          style: AppTextStyles.h4,
                                        ),
                                        Text(
                                          Formatters.dateTime(order.placedAt),
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight, // token "secondary-container" du design system
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCancelled ? Symbols.cancel : Symbols.inventory_2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isCancelled) ...[
                                const SizedBox(height: 16),
                                ...List.generate(_timelineSteps.length, (i) {
                                  final done = i < stepIndex || (order.status == 'DELIVERED' && i == stepIndex);
                                  final current = i == stepIndex && order.status != 'DELIVERED';
                                  final isLast = i == _timelineSteps.length - 1;
                                  return _TimelineStep(
                                    label: _timelineSteps[i],
                                    done: done,
                                    current: current,
                                    isLast: isLast,
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Articles ---
                        Text('Articles', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < order.items.length; i++)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: i < order.items.length - 1
                                        ? const Border(bottom: BorderSide(color: AppColors.border))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Symbols.shopping_bag, color: AppColors.primaryDark),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(order.items[i].productName,
                                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                            Text('Qté ${order.items[i].quantity}', style: AppTextStyles.caption),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(Formatters.price(order.items[i].totalAmount), style: AppTextStyles.labelMedium),
                                          if (order.status == 'DELIVERED')
                                            TextButton(
                                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                                              onPressed: () => showReviewFormDialog(
                                                context,
                                                orderItemId: order.items[i].id,
                                                productName: order.items[i].productName,
                                              ),
                                              child: const Text('Laisser un avis'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Adresse de livraison ---
                        if (order.address != null) ...[
                          _InfoCard(
                            icon: Symbols.location_on,
                            title: 'Adresse de livraison',
                            child: Text(
                              '${order.address!['recipient_name']}\n${order.address!['address_line']}\n${order.address!['district']}, ${order.address!['city']}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // --- Paiement ---
                        if (order.payment != null) ...[
                          _InfoCard(
                            icon: Symbols.credit_card,
                            title: 'Paiement',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      paymentStatus == 'SUCCESS' ? Symbols.check_circle : Symbols.error,
                                      size: 16,
                                      color: paymentStatus == 'SUCCESS' ? AppColors.success : AppColors.error,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _paymentStatusLabels[paymentStatus] ?? paymentStatus ?? '',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                if (canRetryPayment) ...[
                                  const SizedBox(height: 10),
                                  CustomButton(
                                    label: 'Réessayer le paiement',
                                    isOutlined: true,
                                    isLoading: isCancelling,
                                    onPressed: isCancelling
                                        ? null
                                        : () async {
                                            final result = await ref.read(orderActionsProvider.notifier).retryPayment(order.id);
                                            if (!context.mounted) return;

                                            final paymentUrl = result?['payment_url'] as String?;
                                            if (paymentUrl != null) {
                                              final url = Uri.parse(paymentUrl);
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                                return;
                                              }
                                            }

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(result == null
                                                    ? "Impossible de relancer le paiement pour l'instant."
                                                    : 'Paiement relancé.'),
                                              ),
                                            );
                                          },
                                    width: double.infinity,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- Résumé ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              _SummaryRow('Sous-total', Formatters.price(order.subtotal)),
                              if (order.discountAmount > 0)
                                _SummaryRow('Remise', '-${Formatters.price(order.discountAmount)}'),
                              _SummaryRow('Livraison', Formatters.price(order.deliveryFee)),
                              const Divider(),
                              _SummaryRow('Total', Formatters.price(order.totalAmount), isBold: true),
                            ],
                          ),
                        ),

                        if (canCancel) ...[
                          const SizedBox(height: 20),
                          CustomButton(
                            label: 'Annuler la commande',
                            isOutlined: true,
                            isLoading: isCancelling,
                            onPressed: isCancelling
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Annuler la commande ?'),
                                        content: const Text('Cette action est irréversible.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, annuler')),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await ref.read(orderActionsProvider.notifier).cancelOrder(order.id);
                                    }
                                  },
                            width: double.infinity,
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Une étape de la timeline verticale de suivi (repère + libellé + connecteur).
class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final bool isLast;

  const _TimelineStep({required this.label, required this.done, required this.current, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? activeColor : Colors.transparent,
                  border: Border.all(color: (done || current) ? activeColor : AppColors.border, width: 2),
                ),
                child: done
                    ? const Icon(Symbols.check, size: 12, color: Colors.white)
                    : current
                        ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)))
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: done ? activeColor : AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 2),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: current ? FontWeight.w700 : (done ? FontWeight.w600 : FontWeight.w400),
                color: current ? activeColor : (done ? AppColors.textPrimary : AppColors.textDisabled),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow(this.label, this.value, {this.isBold = false});

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