import 'package:flutter/material.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import 'models/sales_claim_model.dart';

/// Expense & Claim (distance claim) API client — doc 04.
///
/// Endpoints:
/// - `GET  /api/sales/claims/my/preview`            (preview for last month)
/// - `POST /api/sales/claims/my/submit`             (agree / disagree)
/// - `GET  /api/sales/claims`                        (mine or team scoped)
/// - `POST /api/sales/claims/:id/review`            (manager approve / reject)
/// - `GET  /api/sales/tracking/my-history`          (day-wise KM)
class SalesClaimApiService {
  final ApiService api;

  SalesClaimApiService(this.api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'data': response};
  }

  Map<String, dynamic> _data(dynamic response) {
    final map = _asMap(response);
    final data = map['data'];
    return data is Map ? Map<String, dynamic>.from(data) : map;
  }

  /// `GET /api/sales/claims/my/preview` — no body, always last calendar month.
  Future<ClaimPreview> fetchPreview() async {
    final response = await api.get(ApiEndpoints.salesClaimsMyPreview);
    debugPrint('=== CLAIM PREVIEW ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = _data(response);
    final raw = data['preview'] ?? map['preview'] ?? data;
    return ClaimPreview.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : data,
    );
  }

  /// `POST /api/sales/claims/my/submit`.
  ///
  /// [action] is `agree` or `disagree`. On disagree, [userDistanceKm] and
  /// [remarks] are meaningful (remarks required in the UI).
  Future<SalesClaim> submitClaim({
    required String action,
    double? userDistanceKm,
    List<ExtraExpense> extraExpenses = const [],
    double advancePaymentAmount = 0,
    String remarks = '',
  }) async {
    final payload = <String, dynamic>{
      'action': action,
      if (action == 'disagree' && userDistanceKm != null)
        'userDistanceKm': userDistanceKm,
      'extraExpenses': extraExpenses.map((e) => e.toJson()).toList(),
      'advancePaymentAmount': advancePaymentAmount,
      'remarks': remarks,
    };

    debugPrint('=== SUBMIT CLAIM REQUEST ===');
    debugPrint(payload.toString());

    final response = await api.post(ApiEndpoints.salesClaimsMySubmit, payload);

    debugPrint('=== SUBMIT CLAIM RESPONSE ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = _data(response);
    final raw = data['claim'] ?? map['claim'] ?? data;
    return SalesClaim.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : data,
    );
  }

  /// `GET /api/sales/claims`.
  ///
  /// - `mine: true` → only the logged-in user (My claim history).
  /// - otherwise a manager sees their reporting tree; an executive sees self.
  Future<List<SalesClaim>> fetchClaims({
    bool mine = false,
    String? status,
    String? monthKey,
    int? limit,
  }) async {
    final response = await api.get(
      ApiEndpoints.salesClaims,
      queryParams: {
        if (mine) 'mine': 1,
        if (status != null && status.isNotEmpty) 'status': status,
        if (monthKey != null && monthKey.isNotEmpty) 'monthKey': monthKey,
        'limit': ?limit,
      },
    );

    debugPrint('=== CLAIMS LIST (mine=$mine) ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = _data(response);
    final raw = data['claims'] ?? map['claims'] ?? data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SalesClaim.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `POST /api/sales/claims/:id/review` — manager approve / reject.
  ///
  /// [action] is `approve` or `reject`. On approve, [approvedDistanceKm]
  /// recalculates the amount server-side.
  Future<SalesClaim> reviewClaim(
    String id, {
    required String action,
    double? approvedDistanceKm,
    String remarks = '',
  }) async {
    final payload = <String, dynamic>{
      'action': action,
      'approvedDistanceKm': ?approvedDistanceKm,
      'remarks': remarks,
    };

    debugPrint('=== REVIEW CLAIM $id ===');
    debugPrint(payload.toString());

    final response = await api.post(
      ApiEndpoints.salesClaimReview(id),
      payload,
    );

    debugPrint('=== REVIEW CLAIM RESPONSE ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = _data(response);
    final raw = data['claim'] ?? map['claim'] ?? data;
    return SalesClaim.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : data,
    );
  }

  /// `GET /api/sales/tracking/my-history?from=&to=` — day-wise KM rows.
  Future<List<ClaimHistoryDay>> fetchDistanceHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await api.get(
      ApiEndpoints.salesTrackingMyHistory,
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    debugPrint('=== DISTANCE HISTORY ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = _data(response);
    final raw =
        data['days'] ?? data['history'] ?? map['history'] ?? data['sessions'];
    final list = raw is List ? raw : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => ClaimHistoryDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
