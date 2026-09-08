import 'package:flutter/material.dart';

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

    debugPrint('LOGIN EMAIL: $email');
    debugPrint('LOGIN RESPONSE: $response');

    return UserModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await api.get(ApiEndpoints.userDetails);

    debugPrint("Profile:->>>>>>>>>>>>>>>>>>>>>>>>${response}");

    final map = Map<String, dynamic>.from(response as Map);
    // Real /auth/me response nests everything under "user":
    // {user: {id, name, email, ..., company: {...}}}.
    // UserDetails.fromJson expects a flat object at the top level,
    // so unwrap it here before parsing.
    if (map['user'] is Map) {
      return Map<String, dynamic>.from(map['user'] as Map);
    }
    return map;
  }

  Future<List<String>> fetchPermissions() async {
    final response = await api.get(ApiEndpoints.permissions);
    final dynamic rawPermissions = response is Map
        ? response['permissions']
        : response;

    if (rawPermissions is! List) {
      return const [];
    }

    return rawPermissions
        .map((permission) {
          if (permission is String) {
            return permission;
          }
          if (permission is Map && permission['name'] is String) {
            return permission['name'] as String;
          }
          return null;
        })
        .whereType<String>()
        .map((permission) => permission.trim())
        .where((permission) => permission.isNotEmpty)
        .toList(growable: false);
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

  Future<void> forgotPassword(String email) async {
    await api.post(ApiEndpoints.forgotPassword, {'email': email});
  }
}
