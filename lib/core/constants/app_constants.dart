class AppConstants {
  AppConstants._();

  static const String appName = 'DEKKON';
  static const String currency = 'FCFA';

  static const String secureStorageTokenKey = 'dekkon_auth_token';
  static const String secureStorageUserKey = 'dekkon_user_data';

  static const int defaultPageSize = 15;

  // Régule le format des prix affichés (section 39 : devise FCFA, pas de décimales)
  static const String currencyLocale = 'fr_FR';
}