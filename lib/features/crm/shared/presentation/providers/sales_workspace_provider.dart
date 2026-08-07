import 'package:erp_app/features/crm/shared/data/models/sales_product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/network_providers.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/inventory_customer_model.dart';
import '../../data/models/sales_contact_model.dart';
import '../../data/models/sales_lead_model.dart';
import '../../data/models/sales_quote_model.dart';
import '../../data/models/sales_workspace_model.dart';
import '../../data/sales_crm_api_service.dart';

final salesCrmApiProvider = Provider<SalesCrmApiService>((ref) {
  return SalesCrmApiService(ref.read(apiServiceProvider));
});

final   salesWorkspaceProvider = AsyncNotifierProvider.autoDispose<
    SalesWorkspaceNotifier, SalesWorkspace>(
  SalesWorkspaceNotifier.new,
);

class SalesWorkspaceNotifier extends AsyncNotifier<SalesWorkspace> {
  SalesCrmApiService get _api => ref.read(salesCrmApiProvider);

  @override
  Future<SalesWorkspace> build() async {
    ref.watch(authProvider);
    return _api.getWorkspace();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_api.getWorkspace);
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      await refresh();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesLead> createLead(Map<String, dynamic> payload) =>
      _mutate(() => _api.createLead(payload));

  Future<SalesLead> updateLead(String leadId, Map<String, dynamic> patch) =>
      _mutate(() => _api.updateLead(leadId, patch));

  Future<SalesLead> qualifyLead(
    String leadId,
    Map<String, dynamic> payload,
  ) =>
      _mutate(() => _api.qualifyLead(leadId, payload));

  Future<SalesQuote> createQuote(
    String leadId,
    Map<String, dynamic> payload,
  ) =>
      _mutate(() => _api.createQuote(leadId, payload));

  Future<SalesQuote> updateQuote(
    String quoteId,
    Map<String, dynamic> payload,
  ) =>
      _mutate(() => _api.updateQuote(quoteId, payload));

  Future<SalesQuote> approveQuote(
    String quoteId, [
    Map<String, dynamic>? payload,
  ]) =>
      _mutate(() => _api.approveQuote(quoteId, payload));

  Future<SalesQuote> rejectQuote(String quoteId, String reason) =>
      _mutate(() => _api.rejectQuote(quoteId, reason));

  Future<SalesQuote> sendQuote(String quoteId) =>
      _mutate(() => _api.sendQuote(quoteId));

  Future<void> logFollowUp(String leadId, Map<String, dynamic> payload) =>
      _mutate(() => _api.logFollowUp(leadId, payload));

  Future<void> completeActivity(String activityId, {String? notes}) =>
      _mutate(() => _api.completeActivity(activityId, notes: notes));

  Future<void> markWon(String leadId) =>
      _mutate(() => _api.markWon(leadId));

  Future<void> markLost(String leadId, String reason) =>
      _mutate(() => _api.markLost(leadId, reason));

  Future<void> requestWonApproval(String leadId) =>
      _mutate(() => _api.requestWonApproval(leadId));

  Future<void> approveWon(String leadId, [Map<String, dynamic>? payload]) =>
      _mutate(() => _api.approveWon(leadId, payload));

  Future<void> rejectWon(String leadId, String reason) =>
      _mutate(() => _api.rejectWon(leadId, reason));

  Future<void> checkInVisit(Map<String, dynamic> payload) =>
      _mutate(() => _api.checkInVisit(payload));

  Future<void> linkCustomer(String leadId, String customerId) =>
      _mutate(() => _api.linkCustomer(leadId, customerId));

  Future<({String? customerId, SalesLead? lead, bool created})> ensureCustomer(
    String leadId,
  ) =>
      _mutate(() => _api.ensureCustomer(leadId));
}

/// Team members for lead assignment (`GET sales/team`).
final crmTeamProvider = FutureProvider.autoDispose<List<CrmTeamMember>>((
  ref,
) async {
  ref.watch(authProvider);
  final raw = await ref.read(salesCrmApiProvider).getTeamStats();
  return raw
      .whereType<Map>()
      .map((e) => CrmTeamMember.fromJson(Map<String, dynamic>.from(e)))
      .where((m) => m.id.isNotEmpty)
      .toList();
});

class CrmTeamMember {
  final String id;
  final String name;
  final String? email;

  const CrmTeamMember({required this.id, required this.name, this.email});

  factory CrmTeamMember.fromJson(Map<String, dynamic> json) {
    final id = (json['userId'] ??
            json['id'] ??
            json['_id'] ??
            json['ownerId'] ??
            '')
        .toString();
    final name = (json['name'] ??
            json['ownerName'] ??
            json['fullName'] ??
            json['userName'] ??
            json['email'] ??
            'Unknown')
        .toString();
    return CrmTeamMember(
      id: id,
      name: name,
      email: json['email']?.toString(),
    );
  }
}

// ─── Derived selectors ───────────────────────────────────────────

final crmLeadsProvider = Provider.autoDispose<AsyncValue<List<SalesLead>>>((
  ref,
) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) => ws.leads);
});

final crmActivitiesProvider = Provider.autoDispose((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) => ws.activities);
});

final crmQuotesProvider = Provider.autoDispose((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) => ws.quotes);
});

final crmVisitsProvider = Provider.autoDispose((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) => ws.visits);
});

final crmBillsProvider = Provider.autoDispose((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) => ws.bills);
});

final crmContactsProvider =
    Provider.autoDispose<AsyncValue<List<SalesContact>>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    return ws.leads
        .where(
          (l) =>
              l.contactName.isNotEmpty ||
              l.email.isNotEmpty ||
              l.phone.isNotEmpty,
        )
        .map(SalesContact.fromLead)
        .toList();
  });
});

/// Leads grouped by lifecycleStage (fallback: status).
final crmPipelineProvider =
    Provider.autoDispose<AsyncValue<Map<String, List<SalesLead>>>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    final map = <String, List<SalesLead>>{};
    for (final lead in ws.leads) {
      final key = (lead.lifecycleStage?.isNotEmpty == true)
          ? lead.lifecycleStage!
          : (lead.status.isNotEmpty ? lead.status : 'Other');
      map.putIfAbsent(key, () => []).add(lead);
    }
    return map;
  });
});

final crmApprovalsProvider =
    Provider.autoDispose<AsyncValue<List<CrmApprovalItem>>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    final items = <CrmApprovalItem>[];

    for (final lead in ws.leads) {
      if (lead.hasPendingWonApproval) {
        items.add(
          CrmApprovalItem(
            kind: 'won',
            id: lead.id,
            title: lead.companyName.isEmpty ? lead.contactName : lead.companyName,
            subtitle: 'Won approval · ${lead.status}',
            status: lead.wonApproval?['status']?.toString() ?? 'pending',
            lead: lead,
          ),
        );
      }
    }

    for (final quote in ws.quotes) {
      if (quote.hasPendingApproval) {
        items.add(
          CrmApprovalItem(
            kind: 'quote',
            id: quote.id,
            title: quote.number ?? quote.account ?? quote.id,
            subtitle: 'Quote approval · ${quote.status}',
            status: quote.approval['status']?.toString() ?? 'pending',
            quote: quote,
          ),
        );
      }
    }

    return items;
  });
});

final crmCustomersProvider = AsyncNotifierProvider.autoDispose<
    CrmCustomersNotifier, List<InventoryCustomer>>(
  CrmCustomersNotifier.new,
);

class CrmCustomersNotifier
    extends AsyncNotifier<List<InventoryCustomer>> {
  @override
  Future<List<InventoryCustomer>> build() async {
    ref.watch(authProvider);
    return ref.read(salesCrmApiProvider).fetchCustomers();
  }

  Future<void> refresh({String? q}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(salesCrmApiProvider).fetchCustomers(q: q),
    );
  }
}

final crmLeadByIdProvider =
    Provider.autoDispose.family<SalesLead?, String>((ref, id) {
  return ref.watch(salesWorkspaceProvider).maybeWhen(
        data: (ws) => ws.leadById(id),
        orElse: () => null,
      );
});

final crmQuoteByIdProvider =
    Provider.autoDispose.family<SalesQuote?, String>((ref, id) {
  return ref.watch(salesWorkspaceProvider).maybeWhen(
        data: (ws) => ws.quoteById(id),
        orElse: () => null,
      );
});

// ─── Products (inventory items, for the quote-form product picker) ──────
final crmProductsProvider = AsyncNotifierProvider.autoDispose<
    CrmProductsNotifier, List<InventoryProductItem>>(
  CrmProductsNotifier.new,
);

class CrmProductsNotifier extends AsyncNotifier<List<InventoryProductItem>> {
  @override
  Future<List<InventoryProductItem>> build() async {
    ref.watch(authProvider);
    return ref.read(salesCrmApiProvider).fetchItems();
  }

  Future<void> refresh({String? search}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(salesCrmApiProvider).fetchItems(search: search),
    );
  }
}

// ─── Dashboard stats (mirrors web DashboardSection.jsx client-side calc) ──

/// Computed metrics for the Sales CRM dashboard cards. All numbers are
/// derived on-device from `workspace.leads` / `activities` / `quotes` —
/// there is no dedicated dashboard API (see Sales_CRM_Dashboard_API.md §5).
class CrmDashboardStats {
  final double pipelineValue;
  final int openDeals;
  final double wonValue;
  final int openLeads;
  final int overdueActivities;
  final int pendingApprovals;

  const CrmDashboardStats({
    this.pipelineValue = 0,
    this.openDeals = 0,
    this.wonValue = 0,
    this.openLeads = 0,
    this.overdueActivities = 0,
    this.pendingApprovals = 0,
  });
}

final crmDashboardStatsProvider =
    Provider.autoDispose<AsyncValue<CrmDashboardStats>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    final openLeadsList = ws.leads.where(
      (l) => l.lifecycleStage != 'won' && l.lifecycleStage != 'lost',
    );
    final wonLeads = ws.leads.where((l) => l.lifecycleStage == 'won');

    final pendingQuoteApprovals =
        ws.quotes.where((q) => q.hasPendingApproval).length;
    final pendingWonApprovals =
        ws.leads.where((l) => l.hasPendingWonApproval).length;

    return CrmDashboardStats(
      pipelineValue: openLeadsList.fold<double>(
        0,
        (sum, l) => sum + (num.tryParse('${l.value ?? 0}') ?? 0),
      ),
      openDeals: openLeadsList.length,
      wonValue: wonLeads.fold<double>(
        0,
        (sum, l) => sum + (num.tryParse('${l.value ?? 0}') ?? 0),
      ),
      openLeads: ws.leads.where((l) => l.status == 'Open').length,
      overdueActivities:
          ws.activities.where((a) => a.status == 'overdue').length,
      pendingApprovals: pendingQuoteApprovals + pendingWonApprovals,
    );
  });
});

// ─── Next actions (dashboard "NEXT ACTIONS" list) ──────────────────────

/// First 4 leads, same list order the workspace returns — mirrors the web
/// Dashboard's "Next actions" widget (doc §5: "First 4 leads (recent/list
/// order)").
final crmNextActionsProvider =
    Provider.autoDispose<AsyncValue<List<SalesLead>>>((ref) {
  return ref
      .watch(salesWorkspaceProvider)
      .whenData((ws) => ws.leads.take(4).toList());
});

// ─── Pipeline funnel (dashboard "PIPELINE FUNNEL" widget) ──────────────

class CrmFunnelStage {
  final String key;
  final String label;
  final int count;
  final double value;

  const CrmFunnelStage({
    required this.key,
    required this.label,
    required this.count,
    required this.value,
  });
}

class _StageDef {
  final String key;
  final String label;
  const _StageDef(this.key, this.label);
}

/// Stage order/labels as configured on the web dashboard
/// (Sales_CRM_Dashboard_API.md §3.3 `pipelineStages` + "Won"). If a company's
/// `config.pipelineStages` differs, adjust this list to match.
const List<_StageDef> _kPipelineStageOrder = [
  _StageDef('qualify', 'Qualify'),
  _StageDef('follow_up', 'Follow-up'),
  _StageDef('quoted', 'Quotation'),
  _StageDef('negotiation', 'Negotiation'),
  _StageDef('won', 'Won'),
];

final crmPipelineFunnelProvider =
    Provider.autoDispose<AsyncValue<List<CrmFunnelStage>>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    return _kPipelineStageOrder.map((stage) {
      final stageLeads = ws.leads.where((l) => l.lifecycleStage == stage.key);
      final value = stageLeads.fold<double>(
        0,
        (sum, l) => sum + (num.tryParse('${l.value ?? 0}') ?? 0),
      );
      return CrmFunnelStage(
        key: stage.key,
        label: stage.label,
        count: stageLeads.length,
        value: value,
      );
    }).toList();
  });
});

// ─── Chart data (source / temperature / won-lost / follow-up type) ─────

class CrmChartsData {
  final Map<String, int> bySource;
  final Map<String, int> byTemperature;
  final int won;
  final int lost;
  final Map<String, int> followUpsByType;

  const CrmChartsData({
    this.bySource = const {},
    this.byTemperature = const {},
    this.won = 0,
    this.lost = 0,
    this.followUpsByType = const {},
  });

  double get winRate {
    final total = won + lost;
    if (total == 0) return 0;
    return (won / total) * 100;
  }
}

final crmChartsDataProvider =
    Provider.autoDispose<AsyncValue<CrmChartsData>>((ref) {
  return ref.watch(salesWorkspaceProvider).whenData((ws) {
    final bySource = <String, int>{};
    for (final l in ws.leads) {
      final key = (l.source?.isNotEmpty ?? false) ? l.source! : 'Unknown';
      bySource[key] = (bySource[key] ?? 0) + 1;
    }

    final byTemperature = <String, int>{};
    for (final l in ws.leads) {
      final key = (l.temperature?.isNotEmpty ?? false) ? l.temperature! : 'Unset';
      byTemperature[key] = (byTemperature[key] ?? 0) + 1;
    }

    final followUpsByType = <String, int>{};
    for (final a in ws.activities) {
      final key = (a.type?.isNotEmpty ?? false) ? a.type! : 'Other';
      followUpsByType[key] = (followUpsByType[key] ?? 0) + 1;
    }

    return CrmChartsData(
      bySource: bySource,
      byTemperature: byTemperature,
      won: ws.leads.where((l) => l.lifecycleStage == 'won').length,
      lost: ws.leads.where((l) => l.lifecycleStage == 'lost').length,
      followUpsByType: followUpsByType,
    );
  });
});