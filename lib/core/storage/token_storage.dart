import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _jwtKey = 'jwt_token';
  static const _fcmKey = 'fcm_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveJwt(String token) async {
    await _storage.write(key: _jwtKey, value: token);
  }

  Future<String?> getJwt() async {
    return await _storage.read(key: _jwtKey);
  }

  Future<void> saveFcm(String token) async {
    await _storage.write(key: _fcmKey, value: token);
  }

  Future<String?> getFcm() async {
    return await _storage.read(key: _fcmKey);
  }

  /// Clears JWT only (FCM token kept for re-register after login).
  Future<void> clear() async {
    await _storage.delete(key: _jwtKey);
  }
}
