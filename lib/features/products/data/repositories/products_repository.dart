import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/products_model.dart';

class ProductsRepository {
  final Dio _dio;

  ProductsRepository(this._dio);

  Future<PaginatedResult<ProductModel>> getProducts({
    String? search,
    String? categoryId,
    bool? featured,
    String sort = 'newest',
    int page = 1,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'sort': sort,
        'page': page,
      };

      if (search case final value?) queryParameters['search'] = value;
      if (categoryId case final value?) queryParameters['category_id'] = value;
      if (featured == true) queryParameters['featured'] = true;

      final response = await _dio.get(ApiConstants.products, queryParameters: queryParameters);

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return PaginatedResult(
        items: data.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.products}/$id');
      return ProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}