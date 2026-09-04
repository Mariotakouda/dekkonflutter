/// Exception métier unifiée pour toute l'app — permet un traitement cohérent
/// des erreurs API dans les providers, quel que soit le domaine.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validationErrors;

  AppException({
    required this.message,
    this.statusCode,
    this.validationErrors,
  });

  bool get isValidationError => validationErrors != null && validationErrors!.isNotEmpty;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Premier message d'erreur de validation, utile pour affichage rapide.
  String? get firstValidationError {
    if (!isValidationError) return null;
    return validationErrors!.values.first.first;
  }

  @override
  String toString() => message;
}