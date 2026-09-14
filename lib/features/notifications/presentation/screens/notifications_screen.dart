import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/notifications_model.dart';
import '../providers/notifications_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsNotifierProvider.notifier).markAllAsRead(),
            child: const Text('Tout marquer lu'),
          ),
        ],
      ),
      body: notificationsState.when(
        skipLoadingOnReload: true,
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les notifications.',
          onRetry: () => ref.invalidate(notificationsNotifierProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Symbols.notifications,
              title: 'Aucune notification',
            );
          }

          final groups = _groupByDay(notifications);

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final group = groups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      group.label.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.02 * 12,
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = group.notifications[index];
                      return ListTile(
                        onTap: () => _handleTap(context, ref, notif),
                        tileColor: notif.isRead ? null : AppColors.primary.withValues(alpha: 0.04),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(_iconForType(notif.type), color: AppColors.primary, size: 20),
                        ),
                        title: Text(notif.title, style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600,
                        )),
                        subtitle: Text(notif.message, style: AppTextStyles.bodySmall),
                        trailing: Text(Formatters.relativeDate(notif.createdAt), style: AppTextStyles.caption),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Regroupe les notifications par jour ("Aujourd'hui", "Hier", puis date
  /// formatée), conformément à la maquette "notifications_dekkon".
  List<_NotificationGroup> _groupByDay(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<NotificationModel>>{};
    for (final notif in notifications) {
      final day = DateTime(notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);
      final String label;
      if (day == today) {
        label = "Aujourd'hui";
      } else if (day == yesterday) {
        label = 'Hier';
      } else {
        label = Formatters.date(notif.createdAt);
      }
      groups.putIfAbsent(label, () => []).add(notif);
    }

    return groups.entries.map((e) => _NotificationGroup(e.key, e.value)).toList();
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationModel notif) {
    if (!notif.isRead) {
      ref.read(notificationsNotifierProvider.notifier).markAsRead(notif.id);
    }

    // Redirige vers la commande concernée quand la notification en a une
    // (order_confirmed, payment_received, order_shipped, order_delivered).
    // Jusqu'ici le tap ne faisait que marquer comme lu, sans jamais naviguer.
    final orderId = notif.data?['order_id']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
    }
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'order_confirmed' => Symbols.check_circle,
      'payment_received' => Symbols.payment,
      'order_shipped' => Symbols.local_shipping,
      'order_delivered' => Symbols.done_all,
      'low_stock_alert' => Symbols.warning_amber,
      _ => Symbols.notifications,
    };
  }
}

/// Un groupe de notifications partageant le même libellé de jour
/// ("Aujourd'hui", "Hier", ou une date formatée).
class _NotificationGroup {
  final String label;
  final List<NotificationModel> notifications;

  const _NotificationGroup(this.label, this.notifications);
}
