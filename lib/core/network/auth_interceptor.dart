import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

/// Injecte automatiquement le token Bearer sur chaque requête sortante,
/// et gère la déconnexion automatique en cas de 401 (token expiré/invalide).
class AuthInterceptor extends Interceptor {
  final void Function()? onUnauthorized;

  AuthInterceptor({this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await SecureStorage.deleteToken();
      onUnauthorized?.call();
    }

    return handler.next(err);
  }
}