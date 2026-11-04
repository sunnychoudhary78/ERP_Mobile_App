import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/sales_claim_model.dart';
import '../../data/sales_claim_api_service.dart';

final salesClaimApiProvider = Provider<SalesClaimApiService>((ref) {
  return SalesClaimApiService(ref.read(apiServiceProvider));
});

/// Parses a `YYYY-MM` month key into its UTC day bounds
/// (`from` = first instant, `to` = last second of the month).
({DateTime from, DateTime to}) monthKeyBounds(String monthKey) {
  final parts = monthKey.split('-');
  final year = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (year == null || month == null || month < 1 || month > 12) {
    final now = DateTime.now();
    final first = DateTime.utc(now.year, now.month, 1);
    return (
      from: first,
      to: DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }
  return (
    from: DateTime.utc(year, month, 1),
    to: DateTime.utc(year, month + 1, 0, 23, 59, 59),
  );
}

/// My claim — `GET /api/sales/claims/my/preview`.
final claimPreviewProvider =
    AsyncNotifierProvider.autoDispose<ClaimPreviewNotifier, ClaimPreview>(
      ClaimPreviewNotifier.new,
    );

class ClaimPreviewNotifier extends AsyncNotifier<ClaimPreview> {
  SalesClaimApiService get _api => ref.read(salesClaimApiProvider);

  @override
  Future<ClaimPreview> build() async {
    ref.watch(authProvider);
    return _api.fetchPreview();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_api.fetchPreview);
  }

  /// Submits this month's claim, then reloads the preview so `existing`
  /// is populated and Submit is disabled.
  Future<SalesClaim> submit({
    required String action,
    double? userDistanceKm,
    List<ExtraExpense> extraExpenses = const [],
    double advancePaymentAmount = 0,
    String remarks = '',
  }) async {
    final claim = await _api.submitClaim(
      action: action,
      userDistanceKm: userDistanceKm,
      extraExpenses: extraExpenses,
      advancePaymentAmount: advancePaymentAmount,
      remarks: remarks,
    );
    state = await AsyncValue.guard(_api.fetchPreview);
    ref.invalidate(myClaimsProvider);
    return claim;
  }
}

/// My claim history — `GET /api/sales/claims?mine=1`.
final myClaimsProvider =
    AsyncNotifierProvider.autoDispose<MyClaimsNotifier, List<SalesClaim>>(
      MyClaimsNotifier.new,
    );

class MyClaimsNotifier extends AsyncNotifier<List<SalesClaim>> {
  String? _status;

  @override
  Future<List<SalesClaim>> build() async {
    ref.watch(authProvider);
    return _load();
  }

  Future<List<SalesClaim>> _load() =>
      ref.read(salesClaimApiProvider).fetchClaims(mine: true, status: _status);

  Future<void> setStatus(String? status) async {
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

/// Team claim requests (manager only) — `GET /api/sales/claims`.
/// Without `mine=1` a manager sees their whole reporting tree.
final teamClaimsProvider =
    AsyncNotifierProvider.autoDispose<TeamClaimsNotifier, List<SalesClaim>>(
      TeamClaimsNotifier.new,
    );

class TeamClaimsNotifier extends AsyncNotifier<List<SalesClaim>> {
  String? _status = 'Pending';

  @override
  Future<List<SalesClaim>> build() async {
    ref.watch(authProvider);
    return _load();
  }

  Future<List<SalesClaim>> _load() =>
      ref.read(salesClaimApiProvider).fetchClaims(status: _status);

  /// `status: null` fetches every status.
  Future<void> setStatus(String? status) async {
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// `POST /api/sales/claims/:id/review` — approve / reject, then reload.
  Future<SalesClaim> review(
    String id, {
    required String action,
    double? approvedDistanceKm,
    String remarks = '',
  }) async {
    final claim = await ref
        .read(salesClaimApiProvider)
        .reviewClaim(
          id,
          action: action,
          approvedDistanceKm: approvedDistanceKm,
          remarks: remarks,
        );
    state = await AsyncValue.guard(_load);
    return claim;
  }
}

/// Day-wise KM for a month — `GET /api/sales/tracking/my-history`.
final claimDistanceHistoryProvider = FutureProvider.autoDispose
    .family<List<ClaimHistoryDay>, String>((ref, monthKey) async {
      ref.watch(authProvider);
      final bounds = monthKeyBounds(monthKey);
      return ref
          .read(salesClaimApiProvider)
          .fetchDistanceHistory(from: bounds.from, to: bounds.to);
    });
