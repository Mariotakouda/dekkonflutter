import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/categories_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final data = response.data['data'] as List;
      return data.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}