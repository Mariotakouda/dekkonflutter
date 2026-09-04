import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/notifications_model.dart';

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final data = response.data['data'] as List;
      return data.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('${ApiConstants.notifications}/$id/read');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('${ApiConstants.notifications}/read-all');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('${ApiConstants.notifications}/unread-count');
      return response.data['data']['unread_count'] as int;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}