import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Stocke le token Sanctum de façon sécurisée (Keychain iOS / Keystore Android).
/// Jamais de token en SharedPreferences brut (section 31 du cahier des charges : gestion sécurisée des tokens).
class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.secureStorageTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConstants.secureStorageTokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.secureStorageTokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}