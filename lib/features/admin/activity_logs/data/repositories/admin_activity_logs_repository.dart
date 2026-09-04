import 'package:dio/dio.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';

class AdminActivityLogModel {
  final String id;
  final Map<String, dynamic>? user;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final DateTime createdAt;

  AdminActivityLogModel({
    required this.id,
    this.user,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    required this.createdAt,
  });

  factory AdminActivityLogModel.fromJson(Map<String, dynamic> json) {
    return AdminActivityLogModel(
      id: json['id'] as String,
      user: json['user'] as Map<String, dynamic>?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminActivityLogsRepository {
  final Dio _dio;

  AdminActivityLogsRepository(this._dio);

  Future<List<AdminActivityLogModel>> getLogs({int page = 1}) async {
    try {
      final response = await _dio.get(ApiConstants.adminActivityLogs, queryParameters: {'page': page});
      final data = response.data['data'] as List;
      return data.map((l) => AdminActivityLogModel.fromJson(l as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}