import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_inventory_model.dart';

class AdminInventoryRepository {
  final Dio _dio;

  AdminInventoryRepository(this._dio);

  Future<AdminPaginatedInventory<AdminInventoryModel>> getInventory({
    bool lowStockOnly = false,
    String? search,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminInventory, queryParameters: {
        if (lowStockOnly) 'low_stock': true,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedInventory(
        items: data.map((i) => AdminInventoryModel.fromJson(i as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminInventoryModel> adjustStock({
    required String variantId,
    required String type,
    required int quantity,
    String? reason,
  }) async {
    try {
      final response = await _dio.post('${ApiConstants.adminInventory}/$variantId/adjust', data: {
        'type': type,
        'quantity': quantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

      final inventoryJson = response.data['data']['inventory'] as Map<String, dynamic>;
      return AdminInventoryModel.fromJson(inventoryJson);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminPaginatedInventory<AdminStockMovementModel>> getMovementsPaginated({
    String? variantId,
    String? type,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminStockMovements, queryParameters: {
        if (variantId != null && variantId.isNotEmpty) 'product_variant_id': variantId,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedInventory(
        items: data.map((m) => AdminStockMovementModel.fromJson(m as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}