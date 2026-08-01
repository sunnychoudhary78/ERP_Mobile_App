import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import 'models/inventory_customer_model.dart';
import 'models/sales_activity_model.dart';
import 'models/sales_bill_model.dart';
import 'models/sales_lead_model.dart';
import 'models/sales_quote_model.dart';
import 'models/sales_visit_model.dart';
import 'models/sales_workspace_model.dart';

class SalesCrmApiService {
  final ApiService api;

  SalesCrmApiService(this.api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'data': response};
  }

  Future<SalesWorkspace> getWorkspace() async {
    final response = await api.get(ApiEndpoints.salesWorkspace);
    return SalesWorkspace.fromApiResponse(response);
  }

  Future<Map<String, dynamic>?> getConfig() async {
    final response = await api.get(ApiEndpoints.salesConfig);
    final map = _asMap(response);
    if (map['config'] is Map) {
      return Map<String, dynamic>.from(map['config'] as Map);
    }
    return map;
  }

  Future<SalesLead> createLead(Map<String, dynamic> payload) async {
    final response = await api.post(ApiEndpoints.salesLeads, payload);
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesLead> updateLead(String leadId, Map<String, dynamic> patch) async {
    final response =
        await api.patch(ApiEndpoints.salesLeadById(leadId), patch);
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesLead> qualifyLead(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await api.patch(ApiEndpoints.salesLeadQualify(leadId), payload);
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesQuote> createQuote(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await api.post(ApiEndpoints.salesLeadQuotes(leadId), payload);
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> updateQuote(
    String quoteId,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await api.patch(ApiEndpoints.salesQuoteById(quoteId), payload);
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> approveQuote(
    String quoteId, [
    Map<String, dynamic>? payload,
  ]) async {
    final response = await api.post(
      ApiEndpoints.salesQuoteApprove(quoteId),
      payload ?? {},
    );
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> rejectQuote(String quoteId, String reason) async {
    final response = await api.post(
      ApiEndpoints.salesQuoteReject(quoteId),
      {'reason': reason},
    );
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> sendQuote(String quoteId) async {
    final response =
        await api.post(ApiEndpoints.salesQuoteSend(quoteId), {});
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<dynamic> logFollowUp(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    return api.post(ApiEndpoints.salesLeadFollowUps(leadId), payload);
  }

  Future<SalesActivity> completeActivity(
    String activityId, {
    String? notes,
  }) async {
    final response = await api.post(
      ApiEndpoints.salesActivityComplete(activityId),
      {'notes': notes ?? ''},
    );
    final map = _asMap(response);
    final activity = map['activity'] is Map ? map['activity'] : map;
    return SalesActivity.fromJson(Map<String, dynamic>.from(activity as Map));
  }

  Future<dynamic> markWon(String leadId) async {
    return api.post(ApiEndpoints.salesLeadWon(leadId), {});
  }

  Future<SalesLead> markLost(String leadId, String reason) async {
    final response = await api.post(
      ApiEndpoints.salesLeadLost(leadId),
      {'reason': reason},
    );
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesLead> requestWonApproval(String leadId) async {
    final response =
        await api.post(ApiEndpoints.salesLeadRequestWonApproval(leadId), {});
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<dynamic> approveWon(
    String leadId, [
    Map<String, dynamic>? payload,
  ]) async {
    return api.post(
      ApiEndpoints.salesLeadApproveWon(leadId),
      payload ?? {},
    );
  }

  Future<SalesLead> rejectWon(String leadId, String reason) async {
    final response = await api.post(
      ApiEndpoints.salesLeadRejectWon(leadId),
      {'reason': reason},
    );
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesVisit> checkInVisit(Map<String, dynamic> payload) async {
    final response = await api.post(ApiEndpoints.salesVisits, payload);
    final map = _asMap(response);
    final visit = map['visit'] is Map ? map['visit'] : map;
    return SalesVisit.fromJson(Map<String, dynamic>.from(visit as Map));
  }

  Future<InventoryCustomer?> matchCustomer({
    String? phone,
    String? email,
  }) async {
    final query = <String, dynamic>{};
    if (phone != null && phone.isNotEmpty) query['phone'] = phone;
    if (email != null && email.isNotEmpty) query['email'] = email;
    if (query.isEmpty) return null;

    final response = await api.get(
      ApiEndpoints.salesCustomersMatch,
      queryParams: query,
    );
    final map = _asMap(response);
    final customer = map['customer'];
    if (customer is Map) {
      return InventoryCustomer.fromJson(Map<String, dynamic>.from(customer));
    }
    return null;
  }

  Future<SalesLead> linkCustomer(String leadId, String customerId) async {
    final response = await api.post(
      ApiEndpoints.salesLeadLinkCustomer(leadId),
      {'customerId': customerId},
    );
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<({String? customerId, SalesLead? lead, bool created})>
      ensureCustomer(String leadId) async {
    final response =
        await api.post(ApiEndpoints.salesLeadEnsureCustomer(leadId), {});
    final map = _asMap(response);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    SalesLead? lead;
    if (data['lead'] is Map) {
      lead = SalesLead.fromJson(Map<String, dynamic>.from(data['lead'] as Map));
    }

    return (
      customerId: data['customerId']?.toString(),
      lead: lead,
      created: data['created'] == true,
    );
  }

  Future<SalesBill> createBill(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await api.post(ApiEndpoints.salesLeadBills(leadId), payload);
    final map = _asMap(response);
    final bill = map['bill'] is Map ? map['bill'] : map;
    return SalesBill.fromJson(Map<String, dynamic>.from(bill as Map));
  }

  Future<List<InventoryCustomer>> fetchCustomers({
    int page = 1,
    int limit = 50,
    String? q,
  }) async {
    final response = await api.get(
      ApiEndpoints.customers,
      queryParams: {
        'page': page,
        'limit': limit,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );

    List list;
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['customers'] is List) {
        list = map['customers'] as List;
      } else if (map['data'] is Map &&
          (map['data'] as Map)['customers'] is List) {
        list = (map['data'] as Map)['customers'] as List;
      } else if (map['data'] is List) {
        list = map['data'] as List;
      } else {
        list = const [];
      }
    } else if (response is List) {
      list = response;
    } else {
      list = const [];
    }

    return list
        .whereType<Map>()
        .map((e) => InventoryCustomer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<dynamic>> getTeamStats() async {
    final response = await api.get(ApiEndpoints.salesTeam);
    final map = _asMap(response);
    if (map['team'] is List) return map['team'] as List;
    if (response is List) return response;
    return const [];
  }
}
