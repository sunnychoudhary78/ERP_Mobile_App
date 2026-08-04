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

  Future<void> ensureCustomer(String leadId) =>
      _mutate(() => _api.ensureCustomer(leadId));
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