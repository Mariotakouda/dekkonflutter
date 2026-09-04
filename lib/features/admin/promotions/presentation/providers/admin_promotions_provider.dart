import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_promotion_model.dart';
import '../../data/repositories/admin_promotions_repository.dart';

final adminPromotionsRepositoryProvider = Provider<AdminPromotionsRepository>((ref) {
  return AdminPromotionsRepository(ref.watch(dioProvider));
});

final adminPromotionDetailProvider = FutureProvider.autoDispose.family<AdminPromotionModel, String>((ref, id) async {
  final repository = ref.watch(adminPromotionsRepositoryProvider);
  return repository.getPromotion(id);
});

class AdminPromotionsListNotifier extends AsyncNotifier<List<AdminPromotionModel>> {
  AdminPromotionsRepository get _repository => ref.read(adminPromotionsRepositoryProvider);

  @override
  Future<List<AdminPromotionModel>> build() async {
    final result = await _repository.getPromotions();
    return result.items;
  }

  Future<String?> create(Map<String, dynamic> data) async {
    try {
      await _repository.createPromotion(data);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePromotion(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updatePromotion(id, data);
      ref.invalidate(adminPromotionDetailProvider(id));
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.deletePromotion(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminPromotionsListProvider = AsyncNotifierProvider<AdminPromotionsListNotifier, List<AdminPromotionModel>>(
  AdminPromotionsListNotifier.new,
);