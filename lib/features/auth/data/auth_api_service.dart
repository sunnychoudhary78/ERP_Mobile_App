import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';
import 'models/employee_self_model.dart';
import 'models/team_member_model.dart';
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

  /// Self employee record — `GET /api/employees/single` (doc 05).
  Future<EmployeeSelf> fetchSelfEmployee() async {
    final response = await api.get(ApiEndpoints.employeeSingle);
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final inner = map['data'] ?? map['employee'];
      return EmployeeSelf.fromJson(
        inner is Map ? Map<String, dynamic>.from(inner) : map,
      );
    }
    throw Exception('Unexpected employee profile response');
  }

  /// Change password — `POST /api/auth/change-password` (doc 05).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await api.post(ApiEndpoints.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Profile photo — `POST /api/employee-photo/photo` multipart field `photo`.
  Future<void> uploadEmployeePhoto(File photo) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split(Platform.pathSeparator).last,
      ),
    });
    await api.postMultipart(ApiEndpoints.employeePhoto, formData);
  }

  /// Vehicle type for the profile — `GET /api/sales/claims/my/preview`.
  ///
  /// Returns `two_wheeler` / `four_wheeler`, or null when the user has no
  /// claims permission (403) or the call fails — the UI then omits the row.
  Future<String?> fetchVehicleType() async {
    try {
      final response = await api.get(ApiEndpoints.salesClaimsMyPreview);
      if (response is! Map) return null;
      final map = Map<String, dynamic>.from(response);
      final preview = map['preview'];
      final value = preview is Map
          ? (preview['vehicleType'] ?? preview['vehicle_type'])
          : (map['vehicleType'] ?? map['vehicle_type']);
      final text = value?.toString();
      return (text == null || text.isEmpty) ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// My team (managers only) — `GET /api/employees/team-dashboard`.
  ///
  /// Permission: `team.dashboard.view`. Read-only names list — the field app
  /// never edits employees.
  Future<List<TeamMember>> fetchMyTeam() async {
    final response = await api.get(ApiEndpoints.getTeamDashboard);
    if (response is! Map) return const [];
    final map = Map<String, dynamic>.from(response);
    final inner = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final employees = inner['employees'] ?? inner['team'];
    if (employees is! List) return const [];
    return employees
        .whereType<Map>()
        .map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e)))
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
