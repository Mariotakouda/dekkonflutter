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
      // Ne déconnecter que si la requête qui a échoué avait bien envoyé un
      // token. Un 401 sur une requête partie SANS Authorization (ex: lecture
      // du secure storage pas encore prête au tout premier appel concurrent)
      // ne signifie pas que le token stocké est invalide : le supprimer dans
      // ce cas déconnecte l'utilisateur à tort (ex: juste après avoir validé
      // une commande, en pleine navigation).
      final hadToken = err.requestOptions.headers['Authorization'] != null;

      if (hadToken) {
        await SecureStorage.deleteToken();
        onUnauthorized?.call();
      }
    }

    return handler.next(err);
  }
}