import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
        'PENDING' => AppColors.statusPending,
        'CONFIRMED' => AppColors.statusConfirmed,
        'PROCESSING' || 'READY_FOR_DELIVERY' || 'ASSIGNED' => AppColors.statusProcessing,
        'OUT_FOR_DELIVERY' => AppColors.statusProcessing,
        'DELIVERED' => AppColors.statusDelivered,
        'CANCELLED' || 'RETURNED' || 'REFUNDED' => AppColors.statusCancelled,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'PENDING' => 'En attente',
        'CONFIRMED' => 'Confirmée',
        'PROCESSING' => 'En préparation',
        'READY_FOR_DELIVERY' => 'Prête',
        'ASSIGNED' => 'Affectée',
        'OUT_FOR_DELIVERY' => 'En livraison',
        'DELIVERED' => 'Livrée',
        'CANCELLED' => 'Annulée',
        'RETURNED' => 'Retournée',
        'REFUNDED' => 'Remboursée',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: AppTextStyles.labelSmall.copyWith(color: _color),
      ),
    );
  }
}