import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/admin_activity_logs_repository.dart';

final adminActivityLogsRepositoryProvider = Provider<AdminActivityLogsRepository>((ref) {
  return AdminActivityLogsRepository(ref.watch(dioProvider));
});

final adminActivityLogsProvider = FutureProvider.autoDispose<List<AdminActivityLogModel>>((ref) async {
  final repository = ref.watch(adminActivityLogsRepositoryProvider);
  return repository.getLogs();
});