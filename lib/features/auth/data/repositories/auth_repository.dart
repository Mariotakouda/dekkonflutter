import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      return AuthResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      return AuthResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post(ApiConstants.resetPassword, data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> sendVerificationCode() async {
    try {
      await _dio.post(ApiConstants.sendVerification);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> verifyAccount(String code) async {
    try {
      await _dio.post(ApiConstants.verifyAccount, data: {'code': code});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}