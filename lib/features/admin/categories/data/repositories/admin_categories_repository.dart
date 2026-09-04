import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../../../products/data/models/admin_product_model.dart';

class AdminCategoriesRepository {
  final Dio _dio;

  AdminCategoriesRepository(this._dio);

  Future<List<AdminCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.adminCategories);
      final data = response.data['data'] as List;
      return data.map((c) => AdminCategoryModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminCategoryModel> createCategory({
    required String name,
    String? parentId,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminCategories, data: {
        'name': name,
        'parent_id': ?parentId,
        if (description != null && description.isNotEmpty) 'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      });
      return AdminCategoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminCategoryModel> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.put('${ApiConstants.adminCategories}/$id', data: {
        'name': ?name,
        'description': ?description,
        'image_url': ?imageUrl,
        'is_active': ?isActive,
      });
      return AdminCategoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

    Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminCategories}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // --- Attributs spécifiques à une catégorie ---

  Future<List<CategoryAttributeModel>> getCategoryAttributes(String categoryId) async {
    try {
      final response = await _dio.get('${ApiConstants.adminCategories}/$categoryId/attributes');
      final data = response.data['data'] as List;
      return data.map((a) => CategoryAttributeModel.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CategoryAttributeModel> createCategoryAttribute(String categoryId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('${ApiConstants.adminCategories}/$categoryId/attributes', data: data);
      return CategoryAttributeModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CategoryAttributeModel> updateCategoryAttribute(
    String categoryId,
    String attributeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('${ApiConstants.adminCategories}/$categoryId/attributes/$attributeId', data: data);
      return CategoryAttributeModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteCategoryAttribute(String categoryId, String attributeId) async {
    try {
      await _dio.delete('${ApiConstants.adminCategories}/$categoryId/attributes/$attributeId');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}