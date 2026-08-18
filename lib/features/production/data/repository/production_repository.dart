import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/production_api_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductionRepository {
  final ProductionApiService _api;

  ProductionRepository(this._api);

  /// Raw paginated fetch — mirrors the backend query as-is.
  Future<WorkOrdersPage> getWorkOrders({
    int page = 1,
    int limit = 50,
    String? status,
    String? itemId,
  }) async {
    final data = await _api.getWorkOrders(
      page: page,
      limit: limit,
      status: status,
      itemId: itemId,
    );
    return WorkOrdersPage.fromJson(data as Map<String, dynamic>);
  }

  /// "Open work orders" view — the backend has no open=true / multi-status
  /// filter, so per the doc we fetch a larger page and filter terminal
  /// statuses (COMPLETED, CANCELLED, QC_PASSED, FG_RECEIVED) client-side.
  Future<List<WorkOrder>> getOpenWorkOrders({int fetchLimit = 200}) async {
    final page = await getWorkOrders(page: 1, limit: fetchLimit);
    return page.items.where((wo) => wo.isOpen).toList();
  }

  Future<WorkOrdersSummary> getSummary() async {
    final data = await _api.getWorkOrdersSummary();
    return WorkOrdersSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<WorkOrder> getWorkOrderById(String id) async {
    final data = await _api.getWorkOrderById(id);
    final map = data as Map<String, dynamic>;
    // Backend wraps single-object responses as { success, message, data: {...} }
    final woJson = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map;
    return WorkOrder.fromJson(woJson);
  }

  /// Logs a shop-floor execution entry. Always pass a real operator/machine/
  /// note — an empty body can accidentally push status to IN_PROCESS.
  Future<WorkOrder> logExecution(
    String id, {
    required String operator,
    required String machine,
    required String note,
    num outputQty = 0,
    num scrapQty = 0,
    List<WorkOrderStage>? stages,
  }) async {
    final logId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    final data = await _api.updateExecution(
      id,
      operator: operator,
      machine: machine,
      logId: logId,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      note: note,
      outputQty: outputQty,
      scrapQty: scrapQty,
      stages: stages?.map((s) => s.toJson()).toList(),
    );
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }

  /// QC hold only — not a shop-floor pause (backend has no generic hold API).
  Future<WorkOrder> setQcHold(String id, {required bool hold}) async {
    final data = await _api.setQcHold(id, hold: hold);
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }

  Future<WorkOrder> transition(String id, {required String activeStep}) async {
    final data = await _api.transition(id, activeStep: activeStep);
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }

  /// Prefer [finishFromQc] when the work order has gone through QC.
  Future<WorkOrder> complete(String id) async {
    final data = await _api.complete(id);
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }

  Future<WorkOrder> finishFromQc(String id) async {
    final data = await _api.finishFromQc(id);
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }

  /// Overwrites the notes field (not append — see doc).
  Future<WorkOrder> overwriteNotes(String id, {required String notes}) async {
    final data = await _api.overwriteNotes(id, notes: notes);
    return WorkOrder.fromJson(data as Map<String, dynamic>);
  }
}

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository(ref.watch(productionApiServiceProvider));
});
