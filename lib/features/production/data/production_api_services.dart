import 'package:erp_app/core/network/api_endpoints.dart';
import 'package:erp_app/core/network/api_service.dart';
import 'package:erp_app/core/providers/network_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [ApiService] with typed calls for the Production / Work Orders
/// module. Mirrors the doc's READY(ADAPT) endpoints — no dedicated
/// start/hold/resume API exists on the backend yet, so callers must build
/// careful payloads (see method docs below).
class ProductionApiService {
  final ApiService _api;

  ProductionApiService(this._api);

  /// GET /api/production/work-orders?page=&limit=&status=&itemId=
  ///
  /// No `open=true` / multi-status filter / assignment filter / WO-number
  /// search on the backend. For an "open work orders" view, fetch a larger
  /// page (e.g. limit: 200) and filter client-side, excluding terminal
  /// statuses: COMPLETED, CANCELLED, QC_PASSED, FG_RECEIVED.
  Future<dynamic> getWorkOrders({
    int page = 1,
    int limit = 50,
    String? status,
    String? itemId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
    };

    debugPrint('Work Orders Request Query: $query');

    final response = await _api.get(
      ApiEndpoints.workOrders,
      queryParams: query,
    );

    debugPrint('Work Orders Response: $response');

    return response;
  }

  /// GET /api/production/work-orders/summary
  Future<dynamic> getWorkOrdersSummary() {
    return _api.get(ApiEndpoints.workOrdersSummary);
  }

  /// GET /api/production/work-orders/:id
  Future<dynamic> getWorkOrderById(String id) async {
    final response = await _api.get(ApiEndpoints.workOrderById(id));

    debugPrint('========== WORK ORDER BY ID ==========');
    debugPrint('Work Order ID: $id');
    debugPrint('Response: $response');
    debugPrint('======================================');

    return response;
  }

  /// POST /api/production/work-orders/:id/execution
  ///
  /// Merges execution JSON, moves lifecycle toward IN_PROCESS, and
  /// auto-moves to QC_HOLD once all stages are done with output > 0.
  /// IMPORTANT: an empty/minimal body can accidentally flip status to
  /// IN_PROCESS — always send a real operator/machine/log entry, never
  /// call this with an empty map just to "ping" the work order.
  Future<dynamic> updateExecution(
    String id, {
    required String operator,
    required String machine,
    required String logId,
    required String timestamp,
    required String note,
    num outputQty = 0,
    num scrapQty = 0,
    List<Map<String, dynamic>>? stages,
  }) {
    final body = <String, dynamic>{
      'execution': {
        'operator': operator,
        'machine': machine,
        'logs': [
          {
            'id': logId,
            'timestamp': timestamp,
            'operator': operator,
            'note': note,
            'outputQty': outputQty,
            'scrapQty': scrapQty,
          },
        ],
      },
      if (stages != null) 'stages': stages,
    };
    return _api.post(ApiEndpoints.workOrderExecution(id), body);
  }

  /// POST /api/production/work-orders/:id/qc
  ///
  /// QC hold ONLY — this is not a generic shop-floor pause. There is no
  /// backend hold/resume API for the shop floor itself.
  Future<dynamic> setQcHold(String id, {required bool hold}) {
    return _api.post(ApiEndpoints.workOrderQc(id), {'hold': hold});
  }

  /// POST /api/production/work-orders/:id/transition
  /// activeStep e.g. 'shop-floor' | 'qc' | 'release'
  Future<dynamic> transition(String id, {required String activeStep}) {
    return _api.post(ApiEndpoints.workOrderTransition(id), {
      'activeStep': activeStep,
    });
  }

  /// POST /api/production/work-orders/:id/complete
  ///
  /// May issue materials + post FG. Does NOT enforce prior QC — prefer
  /// [finishFromQc] when the work order should be completed after QC.
  Future<dynamic> complete(String id) {
    return _api.post(ApiEndpoints.workOrderComplete(id), const {});
  }

  /// POST /api/production/work-orders/:id/finish-from-qc
  /// Safer QC-complete alternative to [complete].
  Future<dynamic> finishFromQc(String id) {
    return _api.post(ApiEndpoints.workOrderFinishFromQc(id), const {});
  }

  /// PATCH /api/production/work-orders/:id  { "notes": "..." }
  ///
  /// This OVERWRITES the notes field. For an append-style remark trail,
  /// put the `note` inside an execution log entry via [updateExecution]
  /// instead — there is no append-only remark history API.
  Future<dynamic> overwriteNotes(String id, {required String notes}) {
    return _api.patch(ApiEndpoints.workOrderNotesPatch(id), {'notes': notes});
  }
}

final productionApiServiceProvider = Provider<ProductionApiService>((ref) {
  return ProductionApiService(ref.watch(apiServiceProvider));
});
