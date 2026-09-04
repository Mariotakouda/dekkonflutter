import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Convertit toute erreur Dio en AppException exploitable par l'UI,
/// en s'appuyant sur le format JSON uniforme renvoyé par le backend Laravel
/// ({success, message, errors}) défini dans ApiResponse côté Laravel.
class ErrorHandler {
  ErrorHandler._();

  static AppException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }

    return AppException(message: 'Une erreur inattendue est survenue.');
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(message: 'La connexion a expiré. Vérifiez votre réseau.');

      case DioExceptionType.connectionError:
        return AppException(message: 'Impossible de contacter le serveur. Vérifiez votre connexion.');

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return AppException(message: 'Requête annulée.');

      default:
        return AppException(message: 'Une erreur inattendue est survenue.');
    }
  }

  static AppException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'Une erreur est survenue.';
    Map<String, List<String>>? validationErrors;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;

      if (data['errors'] is Map) {
        validationErrors = (data['errors'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
      }
    }

    return AppException(
      message: message,
      statusCode: statusCode,
      validationErrors: validationErrors,
    );
  }
}