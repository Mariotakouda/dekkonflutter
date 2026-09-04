import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../auth/data/models/auth_model.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (firstName case final value?) data['first_name'] = value;
      if (lastName case final value?) data['last_name'] = value;
      if (email case final value?) data['email'] = value;
      if (phone case final value?) data['phone'] = value;

      final response = await _dio.patch(ApiConstants.profile, data: data);
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}