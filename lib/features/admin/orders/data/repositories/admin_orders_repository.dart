import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_order_model.dart';

class AdminOrdersRepository {
  final Dio _dio;

  AdminOrdersRepository(this._dio);

  Future<AdminPaginatedResult<AdminOrderModel>> getOrders({
    String? status,
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page};

      if (status case final value?) queryParameters['status'] = value;
      if (search case final value? when value.isNotEmpty) queryParameters['search'] = value;

      final response = await _dio.get(ApiConstants.adminOrders, queryParameters: queryParameters);

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedResult(
        items: data.map((o) => AdminOrderModel.fromJson(o as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminOrderModel> getOrder(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminOrders}/$id');
      return AdminOrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminOrderModel> confirmOrder(String id) async {
    try {
      final response = await _dio.post('${ApiConstants.adminOrders}/$id/confirm');
      return AdminOrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminOrderModel> updateStatus(String id, String status, {String? comment}) async {
    try {
      final response = await _dio.patch('${ApiConstants.adminOrders}/$id/status', data: {
        'status': status,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      return AdminOrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminOrderModel> cancelOrder(String id, {String? reason}) async {
    try {
      final response = await _dio.post('${ApiConstants.adminOrders}/$id/cancel', data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return AdminOrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}