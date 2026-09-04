import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../checkout/data/models/checkout_model.dart';
import '../../../products/data/models/products_model.dart';

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  Future<PaginatedResult<OrderModel>> getOrders({int page = 1}) async {
    try {
      final response = await _dio.get(ApiConstants.orders, queryParameters: {'page': page});
      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return PaginatedResult(
        items: data.map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<OrderModel> getOrder(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}/$id');
      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<OrderModel> cancelOrder(String id) async {
    try {
      final response = await _dio.post('${ApiConstants.orders}/$id/cancel');
      return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Ré-initie le paiement d'une commande existante (ex: paiement Mobile
  /// Money/carte resté en attente ou échoué). Retourne les données du
  /// paiement, dont `payment_url` à ouvrir dans le navigateur.
  Future<Map<String, dynamic>> initiatePayment(String orderId) async {
    try {
      final response = await _dio.post('${ApiConstants.orders}/$orderId/payment/initiate');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}