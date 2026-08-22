import 'package:erp_app/core/network/api_endpoints.dart';
import 'package:erp_app/core/network/api_service.dart';
import 'package:flutter/material.dart';

/// Wraps your existing [ApiService] (Dio + CryptoHelper encrypt/decrypt
/// already handled inside `get()`) for the HRMS dashboard endpoints
/// documented in `HRMS_Dashboard_Mobile_APIs.md`.
///
/// `ApiService.get()` already returns the *decrypted* payload directly
/// (not a Response object), so every method here just shapes that
/// payload — no `.data` unwrapping needed.
///
/// NOTE: `ApiService._extractException` converts DioExceptions into a
/// plain `Exception(message)` and loses the HTTP status code, so we
/// can't reliably branch on "403 specifically" here. For the
/// permission-gated endpoints we catch *any* failure and treat it as
/// "not available" — the caller (repository) hides those cards.
class HrmsApiService {
  final ApiService _api;

  HrmsApiService(this._api);

  /// 4.1 Today punch status — GET attendance?from&to
  Future<Map<String, dynamic>> getTodayAttendance() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final res = await _api.get(
      'attendance',
      queryParams: {'from': today, 'to': today},
    );

    debugPrint('========== TODAY ATTENDANCE RESPONSE ==========');
    debugPrint('$res');
    debugPrint('===============================================');

    return Map<String, dynamic>.from(res as Map);
  }

  /// 4.2 Mobile punch config — GET attendance/mobile-config
  Future<Map<String, dynamic>> getMobileConfig() async {
    final res = await _api.get(ApiEndpoints.mobileAttendanceConfig);
    return Map<String, dynamic>.from(res as Map);
  }

  /// 4.4 Leave balance — GET employees/leave-balance (raw array)
  Future<List<dynamic>> getLeaveBalance() async {
    final res = await _api.get(ApiEndpoints.employeeLeaveBalance);
    return (res as List?) ?? [];
  }

  /// 4.5 My pending leaves count
  Future<int> getMyPendingLeavesCount() async {
    final res = await _api.get(
      ApiEndpoints.leaveRequestsUserAll,
      queryParams: {'page': 1, 'limit': 1, 'status': 'Pending'},
    );
    final data = res as Map;
    final meta = data['meta'] as Map?;
    if (meta != null && meta['total'] != null) {
      return (meta['total'] as num).toInt();
    }
    final list = data['data'] as List? ?? [];
    return list.length;
  }

  /// 4.6 Attendance month summary — permission-gated.
  /// Returns null on ANY failure (403 or otherwise) so the dashboard
  /// just hides the "This Month" card instead of crashing.
  Future<Map<String, dynamic>?> getAttendanceSummary(String month) async {
    try {
      final res = await _api.get(
        ApiEndpoints.attendanceSummary,
        queryParams: {'month': month},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {
      return null;
    }
  }

  /// 5.1 Manager — pending leave approvals count.
  /// Soft-fails (returns 0) on 403 / any error so dashboard still loads.
  Future<int> getManagerPendingLeavesCount() async {
    try {
      final res = await _api.get(
        ApiEndpoints.getManagerPendingLeaves,
        queryParams: {'page': 1, 'limit': 1},
      );
      final meta = (res as Map)['meta'] as Map?;
      return (meta?['total'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 5.2 Manager — pending attendance corrections, permission-gated.
  /// Returns null on failure so the caller can hide the count instead
  /// of showing a wrong "0".
  Future<int?> getPendingCorrectionsCount() async {
    try {
      final res = await _api.get(ApiEndpoints.attendanceCorrectionPending);
      if (res is List) return res.length;
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).length;
      }
      return 0;
    } catch (_) {
      return null;
    }
  }

  /// 5.3 Team dashboard — { success, data: { stats, employees } }.
  /// Soft-fails to null on 403 / any error.
  Future<Map<String, dynamic>?> getTeamDashboard() async {
    try {
      final res = await _api.get(ApiEndpoints.getTeamDashboard);
      final data = res as Map;
      final inner = data['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  /// 6. Admin overview — soft-fails to null on 403 / any error.
  Future<Map<String, dynamic>?> getAdminOverview() async {
    try {
      final res = await _api.get(ApiEndpoints.getstatsAdminOverviews);
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {
      return null;
    }
  }
}
