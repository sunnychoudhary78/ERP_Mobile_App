

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';
import 'models/user_model.dart';

class AuthApiService {
  final ApiService api;

  AuthApiService(this.api);

  Future<UserModel> login(String email, String password) async {
    final response = await api.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await api.get(ApiEndpoints.userDetails);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<String>> fetchPermissions() async {
    final response = await api.get(ApiEndpoints.permissions);
    final List list = response['permissions'] ?? [];
    return list.map((p) => p['name'] as String).toList();
  }

  Future<void> registerFcmToken({
    required String fcmToken,
    required String platform,
  }) async {
    await api.post(ApiEndpoints.registerFcmToken, {
      'fcmToken': fcmToken,
      'platform': platform,
    });
  }

  Future<void> unregisterFcmToken({required String fcmToken}) async {
    await api.post(ApiEndpoints.unregisterFcmToken, {'fcmToken': fcmToken});
  }

  Future<void> forgotPassword(String email) async{
    await api.post(ApiEndpoints.forgotPassword, {'email': email});
  }
}
