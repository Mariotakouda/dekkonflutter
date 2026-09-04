import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_delivery_model.dart';

class AdminDeliveriesRepository {
  final Dio _dio;

  AdminDeliveriesRepository(this._dio);

  Future<AdminPaginatedDeliveries<AdminDeliveryModel>> getDeliveries({
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminDeliveries, queryParameters: {
        'status': ?status,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedDeliveries(
        items: data.map((d) => AdminDeliveryModel.fromJson(d as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminDeliveryModel> assignDriver(String deliveryId, String driverId) async {
    try {
      final response = await _dio.post('${ApiConstants.adminDeliveries}/$deliveryId/assign', data: {
        'driver_id': driverId,
      });
      return AdminDeliveryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminDeliveryModel> updateStatus(String deliveryId, String status, {String? failureReason}) async {
    try {
      final response = await _dio.patch('${ApiConstants.adminDeliveries}/$deliveryId/status', data: {
        'status': status,
        if (failureReason != null && failureReason.isNotEmpty) 'failure_reason': failureReason,
      });
      return AdminDeliveryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<AdminDriverModel>> getDrivers({String? status}) async {
    try {
      final response = await _dio.get(ApiConstants.adminDrivers, queryParameters: {
        'status': ?status,
      });
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
}