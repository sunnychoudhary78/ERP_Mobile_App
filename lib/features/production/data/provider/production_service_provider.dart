import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/production_api_services.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/legacy.dart';

// NOTE: adjust the two import paths above to match wherever
// production_api_services.dart / production_model.dart actually live in
// your project — I don't have your folder structure for this module.

/// Doc suggests a 30–60s cache TTL for the summary card. Using 45s.
const _summaryCacheTtl = Duration(seconds: 45);

class ProductionSummaryState {
  final ProductionSummary summary;
  final bool isLoading;
  final String? error;
  final DateTime? fetchedAt;

  const ProductionSummaryState({
    this.summary = ProductionSummary.empty,
    this.isLoading = false,
    this.error,
    this.fetchedAt,
  });

  bool get isStale =>
      fetchedAt == null || DateTime.now().difference(fetchedAt!) > _summaryCacheTtl;

  ProductionSummaryState copyWith({
    ProductionSummary? summary,
    bool? isLoading,
    String? error,
    DateTime? fetchedAt,
    bool clearError = false,
  }) {
    return ProductionSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class ProductionSummaryNotifier extends StateNotifier<ProductionSummaryState> {
  final ProductionApiService _api;

  ProductionSummaryNotifier(this._api) : super(const ProductionSummaryState());

  /// Fetches the summary. Skips the network call if we fetched within the
  /// TTL window, unless [force] is true (e.g. pull-to-refresh).
  Future<void> fetch({bool force = false}) async {
    if (!force && !state.isStale && state.fetchedAt != null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.getWorkOrdersSummary();
      // response is the full {success, message, data} envelope — unwrap it.
      final data = (response is Map && response['data'] is Map)
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};

      state = state.copyWith(
        summary: ProductionSummary.fromJson(data),
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('ProductionSummary fetch failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final productionSummaryProvider =
    StateNotifierProvider<ProductionSummaryNotifier, ProductionSummaryState>(
  (ref) => ProductionSummaryNotifier(ref.watch(productionApiServiceProvider)),
);