import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notifications_model.dart';
import '../../data/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  NotificationsRepository get _repository => ref.read(notificationsRepositoryProvider);

  @override
  Future<List<NotificationModel>> build() async {
    return _repository.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    ref.invalidateSelf();
    // Le badge affiché sur l'écran Profil dépend de unreadNotificationsCountProvider :
    // sans cette invalidation, il resterait périmé après une lecture.
    ref.invalidate(unreadNotificationsCountProvider);
    await future;
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    ref.invalidateSelf();
    ref.invalidate(unreadNotificationsCountProvider);
    await future;
  }
}

final notificationsNotifierProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.unreadCount();
});
