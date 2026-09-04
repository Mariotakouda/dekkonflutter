import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/checkout_model.dart';

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  Future<OrderModel> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? promotionCode,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.orders, data: {
        'address_id': addressId,
        'payment_method': paymentMethod,
        if (promotionCode != null && promotionCode.isNotEmpty) 'promotion_code': promotionCode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    try {
      final response = await _dio.post('${ApiConstants.orders}/$orderId/payment/initiate');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}