import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around FlutterSecureStorage for securely storing tokens, user session info,
/// and local encryption keys.
class AppSecureStorage {
  AppSecureStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _keyAuthToken, value: token);

  Future<String?> getAuthToken() => _storage.read(key: _keyAuthToken);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> saveUserRole(String role) =>
      _storage.write(key: _keyUserRole, value: role);

  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  Future<void> clearAll() => _storage.deleteAll();
}
