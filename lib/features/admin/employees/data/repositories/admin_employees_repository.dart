import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_employee_model.dart';

class AdminEmployeesRepository {
  final Dio _dio;

  AdminEmployeesRepository(this._dio);

  Future<AdminPaginatedEmployees<AdminEmployeeModel>> getEmployees({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminEmployees, queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'status': ?status,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedEmployees(
        items: data.map((e) => AdminEmployeeModel.fromJson(e as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminEmployeeModel> getEmployee(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminEmployees}/$id');
      return AdminEmployeeModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminEmployeeModel> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.adminEmployees, data: data);
      return AdminEmployeeModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminEmployeeModel> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.adminEmployees}/$id', data: data);
      return AdminEmployeeModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deactivateEmployee(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminEmployees}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<AdminRoleModel>> getRoles() async {
    try {
      final response = await _dio.get(ApiConstants.adminRoles);
      final data = response.data['data'] as List;
      return data.map((r) => AdminRoleModel.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<AdminPermissionModel>> getPermissions() async {
    try {
      final response = await _dio.get(ApiConstants.adminPermissions);
      final data = response.data['data'] as List;
      return data.map((p) => AdminPermissionModel.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminRoleModel> createRole({
    required String name,
    required String code,
    String? description,
    List<String> permissionIds = const [],
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminRoles, data: {
        'name': name,
        'code': code,
        if (description != null && description.isNotEmpty) 'description': description,
        'permission_ids': permissionIds,
      });
      return AdminRoleModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminRoleModel> updateRole(String id, {String? name, String? description}) async {
    try {
      final response = await _dio.put('${ApiConstants.adminRoles}/$id', data: {
        'name': ?name,
        'description': ?description,
      });
      return AdminRoleModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminRoles}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminRoleModel> syncRolePermissions(String roleId, List<String> permissionIds) async {
    try {
      final response = await _dio.put('${ApiConstants.adminRoles}/$roleId/permissions', data: {
        'permission_ids': permissionIds,
      });
      return AdminRoleModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}