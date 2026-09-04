import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../products/data/models/products_model.dart';

class FavoritesRepository {
  final Dio _dio;

  FavoritesRepository(this._dio);

  Future<List<ProductModel>> getFavorites() async {
    try {
      final response = await _dio.get(ApiConstants.favorites);
      final data = response.data['data'] as List;
      return data
          .map((f) => ProductModel.fromJson(f['product'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> addFavorite(String productId) async {
    try {
      await _dio.post('${ApiConstants.favorites}/$productId');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      await _dio.delete('${ApiConstants.favorites}/$productId');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}