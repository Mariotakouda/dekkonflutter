import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/reviews_model.dart';
import '../../data/repositories/reviews_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(dioProvider));
});

final reviewsListProvider = FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getReviews();
});

class ReviewSubmitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> submit({required String orderItemId, required int rating, String? comment}) async {
    state = true;
    try {
      await ref.read(reviewsRepositoryProvider).createReview(
            orderItemId: orderItemId,
            rating: rating,
            comment: comment,
          );
      ref.invalidate(reviewsListProvider);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final reviewSubmitProvider = NotifierProvider<ReviewSubmitNotifier, bool>(ReviewSubmitNotifier.new);