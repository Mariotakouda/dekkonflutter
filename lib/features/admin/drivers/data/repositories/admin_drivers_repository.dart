import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../../../deliveries/data/models/admin_delivery_model.dart';
import '../../../employees/data/models/admin_employee_model.dart';

class AdminDriversRepository {
  final Dio _dio;

  AdminDriversRepository(this._dio);

  Future<List<AdminDriverModel>> getDrivers() async {
    try {
      final response = await _dio.get(ApiConstants.adminDrivers);
      final data = response.data['data'] as List;
      return data.map((d) => AdminDriverModel.fromJson(d as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminDriverModel> createDriver({
    required String employeeId,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminDrivers, data: {
        'employee_id': employeeId,
        if (vehicleType != null && vehicleType.isNotEmpty) 'vehicle_type': vehicleType,
        if (vehicleNumber != null && vehicleNumber.isNotEmpty) 'vehicle_number': vehicleNumber,
      });
      return AdminDriverModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminDriverModel> updateDriver(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiConstants.adminDrivers}/$id', data: data);
      return AdminDriverModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Employés pas encore livreurs — pour peupler le formulaire de création.
  Future<List<AdminEmployeeModel>> getEligibleEmployees() async {
    try {
      final response = await _dio.get(ApiConstants.adminEmployees, queryParameters: {
        'status': 'ACTIVE',
        'per_page': 100,
      });
      final data = response.data['data'] as List;
      return data.map((e) => AdminEmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}