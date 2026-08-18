/// Models for the Production / Work Orders module.
///
/// NOTE: the shared doc (section 7) only specifies the REQUEST shapes for
/// execution/transition/complete — it doesn't give the exact list/detail
/// RESPONSE schema. Fields below are named from common ERP work-order
/// conventions + the terminal-status list mentioned in the doc
/// (COMPLETED, CANCELLED, QC_PASSED, FG_RECEIVED, IN_PROCESS, QC_HOLD).
/// Treat unknown/extra backend fields as safe to ignore (fromJson below
/// won't throw on missing optional fields) — but please diff this against
/// one real GET /work-orders response and adjust field names if they
/// don't match; I've marked the guessy ones with // ADAPT.

class WorkOrderStage {
  final String code;
  final bool completed;
  final num outputQty;
  final num scrapQty;

  const WorkOrderStage({
    required this.code,
    this.completed = false,
    this.outputQty = 0,
    this.scrapQty = 0,
  });

  factory WorkOrderStage.fromJson(Map<String, dynamic> json) {
    return WorkOrderStage(
      code: json['code']?.toString() ?? '',
      completed: json['completed'] == true,
      outputQty: (json['outputQty'] as num?) ?? 0,
      scrapQty: (json['scrapQty'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'completed': completed,
        'outputQty': outputQty,
        'scrapQty': scrapQty,
      };
}

class ExecutionLog {
  final String id;
  final String timestamp;
  final String operator;
  final String note;
  final num outputQty;
  final num scrapQty;

  const ExecutionLog({
    required this.id,
    required this.timestamp,
    required this.operator,
    required this.note,
    this.outputQty = 0,
    this.scrapQty = 0,
  });

  factory ExecutionLog.fromJson(Map<String, dynamic> json) {
    return ExecutionLog(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      operator: json['operator']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      outputQty: (json['outputQty'] as num?) ?? 0,
      scrapQty: (json['scrapQty'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'operator': operator,
        'note': note,
        'outputQty': outputQty,
        'scrapQty': scrapQty,
      };
}

class WorkOrderExecution {
  final String? operator;
  final String? machine;
  final List<ExecutionLog> logs;

  const WorkOrderExecution({
    this.operator,
    this.machine,
    this.logs = const [],
  });

  factory WorkOrderExecution.fromJson(Map<String, dynamic> json) {
    return WorkOrderExecution(
      operator: json['operator']?.toString(),
      machine: json['machine']?.toString(),
      logs: (json['logs'] as List<dynamic>? ?? [])
          .map((e) => ExecutionLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Statuses the doc explicitly calls out as terminal — used to build the
/// client-side "open work orders" filter since the backend has no
/// open=true / multi-status filter.
class WorkOrderStatus {
  static const String demandOpen = 'DEMAND_OPEN'; // confirmed from real API
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const String qcPassed = 'QC_PASSED';
  static const String fgReceived = 'FG_RECEIVED';
  static const String inProcess = 'IN_PROCESS'; // ADAPT if backend differs
  static const String qcHold = 'QC_HOLD';

  static const List<String> terminal = [
    completed,
    cancelled,
    qcPassed,
    fgReceived,
  ];

  static bool isTerminal(String? status) =>
      status != null && terminal.contains(status.toUpperCase());
}

class WorkOrder {
  final String id;
  final String? woNumber;
  final String? itemId;
  final String? itemName;
  final num? quantity;
  final String? status; // backend field: lifecycleStatus
  final String? activeStep;
  final String? dueDate;
  final String? notes;
  final String? priority;
  final String? warehouse;
  final String? customerName;
  final String? factoryName;
  final String? sourceType;
  final String? salesOrderNo;
  final List<WorkOrderStage> stages;
  final WorkOrderExecution? execution;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> raw; // full payload, for fields not yet modeled

  const WorkOrder({
    required this.id,
    this.woNumber,
    this.itemId,
    this.itemName,
    this.quantity,
    this.status,
    this.activeStep,
    this.dueDate,
    this.notes,
    this.priority,
    this.warehouse,
    this.customerName,
    this.factoryName,
    this.sourceType,
    this.salesOrderNo,
    this.stages = const [],
    this.execution,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  bool get isOpen => !WorkOrderStatus.isTerminal(status);

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      woNumber: (json['workOrderNo'] ??
              json['woNumber'] ??
              json['workOrderNumber'])
          ?.toString(),
      itemId: json['itemId']?.toString(),
      itemName: (json['itemName'] ??
              (json['item'] is Map ? json['item']['name'] : null))
          ?.toString(),
      quantity: json['quantity'] as num?,
      status: (json['lifecycleStatus'] ?? json['status'])?.toString(),
      activeStep: json['activeStep']?.toString(),
      dueDate: json['dueDate']?.toString(),
      notes: json['notes']?.toString(),
      priority: json['priority']?.toString(),
      warehouse: json['warehouse']?.toString(),
      customerName: json['customerName']?.toString(),
      factoryName: json['factoryName']?.toString(),
      sourceType: json['sourceType']?.toString(),
      salesOrderNo: json['salesOrderNo']?.toString(),
      stages: (json['stages'] as List<dynamic>? ??
              (json['execution'] is Map
                  ? (json['execution']['stages'] as List<dynamic>?)
                  : null) ??
              [])
          .map((e) => WorkOrderStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      execution: json['execution'] is Map<String, dynamic>
          ? WorkOrderExecution.fromJson(json['execution'])
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      raw: json,
    );
  }
}

class WorkOrdersPage {
  final List<WorkOrder> items;
  final int page;
  final int limit;
  final int? total; // ADAPT — confirm the backend's total-count field name

  const WorkOrdersPage({
    required this.items,
    required this.page,
    required this.limit,
    this.total,
  });

  factory WorkOrdersPage.fromJson(Map<String, dynamic> json) {
    // Backend response shape isn't fixed in the doc — handle both:
    //   flat:   { "data": [ ... ], "page": 1, "total": 42 }
    //   nested: { "data": { "items": [ ... ], "page": 1, "total": 42 } }
    final candidate = json['data'] ?? json['items'] ?? json['results'];

    List<dynamic> rawList = [];
    Map<String, dynamic> meta = json; // where page/limit/total live

    if (candidate is List) {
      rawList = candidate;
    } else if (candidate is Map<String, dynamic>) {
      meta = candidate;
      final inner = candidate['items'] ??
          candidate['data'] ??
          candidate['results'] ??
          candidate['workOrders'];
      if (inner is List) rawList = inner;
    }

    return WorkOrdersPage(
      items: rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => WorkOrder.fromJson(e))
          .toList(),
      page: (meta['page'] as num?)?.toInt() ??
          (json['page'] as num?)?.toInt() ??
          1,
      limit: (meta['limit'] as num?)?.toInt() ??
          (json['limit'] as num?)?.toInt() ??
          rawList.length,
      total: (meta['total'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt(),
    );
  }
}

/// GET /production/work-orders/summary — response.data shape, confirmed by
/// the "Production Dashboard APIs (Mobile)" doc (18 Aug 2026):
/// { total, demandOpen, planned, shortage, released, inProduction, qcHold,
///   completed, pendingApprovals }
///
/// Pass the UNWRAPPED `data` object to fromJson (not the full
/// {success,message,data} envelope) — see ProductionSummaryNotifier.
class ProductionSummary {
  final int total;
  final int demandOpen;
  final int planned;
  final int shortage;
  final int released;
  final int inProduction;
  final int qcHold;
  final int completed;
  final int pendingApprovals;
  final Map<String, dynamic> raw;

  const ProductionSummary({
    this.total = 0,
    this.demandOpen = 0,
    this.planned = 0,
    this.shortage = 0,
    this.released = 0,
    this.inProduction = 0,
    this.qcHold = 0,
    this.completed = 0,
    this.pendingApprovals = 0,
    this.raw = const {},
  });

  /// Doc's mobile helper: total - completed. Use as a rough "open WIP"
  /// figure without re-fetching the full list.
  int get openApprox => total - completed;

  factory ProductionSummary.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
    return ProductionSummary(
      total: _i(json['total']),
      demandOpen: _i(json['demandOpen']),
      planned: _i(json['planned']),
      shortage: _i(json['shortage']),
      released: _i(json['released']),
      inProduction: _i(json['inProduction']),
      qcHold: _i(json['qcHold']),
      completed: _i(json['completed']),
      pendingApprovals: _i(json['pendingApprovals']),
      raw: json,
    );
  }

  static const empty = ProductionSummary();
}

/// Kept for backward compatibility if anything still references the old
/// permissive/guessy summary shape — prefer [ProductionSummary] now that
/// the doc confirms exact fields.
@Deprecated('Use ProductionSummary — the doc now confirms the exact shape.')
class WorkOrdersSummary {
  final Map<String, int> countsByStatus;
  final Map<String, dynamic> raw;

  const WorkOrdersSummary({this.countsByStatus = const {}, this.raw = const {}});

  factory WorkOrdersSummary.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    json.forEach((key, value) {
      if (value is num) counts[key] = value.toInt();
    });
    return WorkOrdersSummary(countsByStatus: counts, raw: json);
  }
}