import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/cart_model.dart';

class CartRepository {
  final Dio _dio;

  CartRepository(this._dio);

  Future<CartModel> getCart() async {
    try {
      final response = await _dio.get(ApiConstants.cart);
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CartModel> addItem({required String productVariantId, required int quantity}) async {
    try {
      final response = await _dio.post(ApiConstants.cartItems, data: {
        'product_variant_id': productVariantId,
        'quantity': quantity,
      });
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CartModel> updateItem({required String itemId, required int quantity}) async {
    try {
      final response = await _dio.patch('${ApiConstants.cartItems}/$itemId', data: {
        'quantity': quantity,
      });
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CartModel> removeItem(String itemId) async {
    try {
      final response = await _dio.delete('${ApiConstants.cartItems}/$itemId');
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}