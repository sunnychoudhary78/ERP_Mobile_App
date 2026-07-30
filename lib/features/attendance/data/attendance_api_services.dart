import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:erp_app/features/attendance/models/mobile_config.dart';
import 'package:erp_app/features/attendance/models/attendance_session_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';


class AttendanceApiService {
  final ApiService api;

  AttendanceApiService(this.api);

  Future<AttendanceConfig> fetchMobileConfig() async {
    try {
      final response = await api.get(ApiEndpoints.mobileAttendanceConfig);
      debugPrint('Mobile config response: $response');
      return AttendanceConfig.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

  
    } catch (_) {
    
      return const AttendanceConfig();
    }
  }

  
  Future<AttendanceSession?> fetchTodayStatus() async {
    final today = _formatDate(DateTime.now());
    final response = await api.get(
      ApiEndpoints.checkIn,
      queryParams: {'from': today, 'to': today},
    );
    debugPrint('Today status response: $response');

    final list = _extractList(response);
    if (list.isEmpty) return null;

    final sessions = list
        .map((e) => AttendanceSession.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort(
        (a, b) => (b.checkInTime ?? DateTime(0))
            .compareTo(a.checkInTime ?? DateTime(0)),
      );

    return sessions.first;
  }

  Future<AttendanceSession> checkIn({
    double? lat,
    double? lng,
    double? accuracy,
    XFile? selfie,
    bool remoteRequested = false,
    String? remoteReason,
  }) async {
    final formMap = <String, dynamic>{
      'source': 'mobile',
      if (lat != null && lng != null)
        'location': jsonEncode({
          'lat': lat,
          'lng': lng,
          if (accuracy != null) 'accuracy': accuracy,
        }),
      'remoteRequested': remoteRequested.toString(),
      if (remoteReason != null && remoteReason.trim().isNotEmpty)
        'remoteReason': remoteReason.trim(),
    };

    if (selfie != null) {
      formMap['checkInSelfie'] = await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.name,
      );
    }

    final response = await api.postMultipart(
      ApiEndpoints.checkIn,
      FormData.fromMap(formMap),
    );
    return AttendanceSession.fromJson(_extractSession(response));
  }

  Future<AttendanceSession> checkOut({
    double? lat,
    double? lng,
    double? accuracy,
    XFile? selfie,
  }) async {
    final formMap = <String, dynamic>{
      'source': 'mobile',
      if (lat != null && lng != null)
        'location': jsonEncode({
          'lat': lat,
          'lng': lng,
          if (accuracy != null) 'accuracy': accuracy,
        }),
    };

    if (selfie != null) {
      formMap['checkOutSelfie'] = await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.name,
      );
    }

    final response = await api.postMultipart(
      ApiEndpoints.checkOut,
      FormData.fromMap(formMap),
    );
    debugPrint('Check-out response: $response');
    return AttendanceSession.fromJson(_extractSession(response));
  }

  // ── helpers ──────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      for (final key in ['data', 'attendance', 'records', 'result']) {
        final v = response[key];
        if (v is List) return v;
      }
    }
    return [];
  }

  Map<String, dynamic> _extractSession(dynamic response) {
    if (response is Map) {
      for (final key in ['data', 'attendance', 'session']) {
        final v = response[key];
        if (v is Map) return Map<String, dynamic>.from(v);
      }
      return Map<String, dynamic>.from(response);
    }
    return {};
  }
}