import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_payment_model.dart';

class AdminPaymentsRepository {
  final Dio _dio;

  AdminPaymentsRepository(this._dio);

  Future<AdminPaginatedPayments<AdminPaymentModel>> getPayments({
    String? status,
    String? method,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminPayments, queryParameters: {
        'status': ?status,
        'method': ?method,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedPayments(
        items: data.map((p) => AdminPaymentModel.fromJson(p as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPaymentModel> getPayment(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminPayments}/$id');
      return AdminPaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPaymentModel> refundPayment(String id, {String? reason}) async {
    try {
      final response = await _dio.post('${ApiConstants.adminPayments}/$id/refund', data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return AdminPaymentModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}