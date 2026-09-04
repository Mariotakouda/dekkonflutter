import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

/// Client HTTP central de l'application — instance unique de Dio,
/// configurée avec l'intercepteur d'authentification.
class DioClient {
  static Dio create({void Function()? onUnauthorized}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  }
}