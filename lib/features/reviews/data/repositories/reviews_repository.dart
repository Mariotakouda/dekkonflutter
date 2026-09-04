import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/reviews_model.dart';

class ReviewsRepository {
  final Dio _dio;

  ReviewsRepository(this._dio);

  Future<List<ReviewModel>> getReviews({String? productId}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (productId != null) queryParameters['product_id'] = productId;

      final response = await _dio.get(ApiConstants.reviews, queryParameters: queryParameters);
      final data = response.data['data'] as List;
      final reviews = data.map((r) => ReviewModel.fromJson(r as Map<String, dynamic>)).toList();

      // Filtre de sécurité côté client : si le backend ignore
      // `product_id` (paramètre non supporté), on filtre quand même
      // localement pour ne jamais afficher l'avis d'un autre produit.
      if (productId == null) return reviews;
      return reviews.where((r) => r.product?['id'] == productId).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ReviewModel> createReview({
    required String orderItemId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.reviews, data: {
        'order_item_id': orderItemId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}