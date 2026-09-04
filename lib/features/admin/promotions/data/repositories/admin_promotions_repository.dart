import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_promotion_model.dart';

class AdminPromotionsRepository {
  final Dio _dio;

  AdminPromotionsRepository(this._dio);

  Future<AdminPaginatedPromotions<AdminPromotionModel>> getPromotions({int page = 1}) async {
    try {
      final response = await _dio.get(ApiConstants.adminPromotions, queryParameters: {'page': page});

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedPromotions(
        items: data.map((p) => AdminPromotionModel.fromJson(p as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPromotionModel> getPromotion(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminPromotions}/$id');
      return AdminPromotionModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPromotionModel> createPromotion(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.adminPromotions, data: data);
      return AdminPromotionModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPromotionModel> updatePromotion(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.adminPromotions}/$id', data: data);
      return AdminPromotionModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminPromotions}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}