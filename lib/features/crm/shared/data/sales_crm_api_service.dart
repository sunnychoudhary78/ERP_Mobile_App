import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:erp_app/features/crm/shared/data/models/sales_product_model.dart';
import 'package:flutter/material.dart';

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

    debugPrint("=== API Response get space ===");
    // debugPrint('LEADS RAW: ${jsonEncode(response['data']['leads'])}');
    // debugPrint('DATA KEYS: ${response['data'].keys.toList()}');
    debugPrint('DATA KEYS: ${response['data'].keys.toList()}');
    //debugPrint('compantBilling: ${jsonEncode(response['data']['companyBilling'])}');
    debugPrint('WORKSPACE: ${jsonEncode(response['data']['workspace'])}');
    //debugPrint('compaingBilling: ${jsonEncode(response['data']['companyBilling'])}');
    // debugPrint(response.toString());
    return SalesWorkspace.fromApiResponse(response['data']['workspace']);
  }

  // Future<SalesWorkspace> getWorkspace() async {
  //   final response = await api.get(ApiEndpoints.salesWorkspace);
  //   final ws = SalesWorkspace.fromApiResponse(response['data']['workspace']);

  //   debugPrint('=== APPROVAL-RELEVANT DATA ===');
  //   for (final lead in ws.leads.where((l) => l.hasPendingWonApproval)) {
  //     debugPrint(
  //       'WON PENDING → ${lead.id} | ${lead.companyName} | ${lead.wonApproval}',
  //     );
  //   }
  //   for (final quote in ws.quotes.where((q) => q.hasPendingApproval)) {
  //     debugPrint(
  //       'QUOTE PENDING → ${quote.id} | ${quote.number} | ${quote.approval}',
  //     );
  //   }
  //   debugPrint('===============================');

  //   return ws;
  // }

  Future<Map<String, dynamic>?> getConfig() async {
    final response = await api.get(ApiEndpoints.salesConfig);
    debugPrint(response.toString());
    final map = _asMap(response);
    if (map['config'] is Map) {
      return Map<String, dynamic>.from(map['config'] as Map);
    }
    return map;
  }

  Future<SalesLead> createLead(Map<String, dynamic> payload) async {
    final response = await api.post(ApiEndpoints.salesLeads, payload);

    debugPrint("=== API Response Leads ===");
    debugPrint(response.toString());
    final map = _asMap(response);

    // debugPrint("=== Response Map ===");

    final lead = map['lead'] is Map ? map['lead'] : map;

    // debugPrint("=== Lead Data ===");
    // debugPrint(lead);

    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  // move to negoations

  Future<SalesLead> updateLead(
    String leadId,
    Map<String, dynamic> patch,
  ) async {
    final response = await api.patch(ApiEndpoints.salesLeadById(leadId), patch);
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesLead> qualifyLead(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    final response = await api.patch(
      ApiEndpoints.salesLeadQualify(leadId),
      payload,
    );

    debugPrint("=== API Response Qualify Lead ===");
    debugPrint(response.toString());
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesQuote> createQuote(
    String leadId,
    Map<String, dynamic> payload,
  ) async {
    final response = await api.post(
      ApiEndpoints.salesLeadQuotes(leadId),
      payload,
    );
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> updateQuote(
    String quoteId,
    Map<String, dynamic> payload,
  ) async {
    final response = await api.patch(
      ApiEndpoints.salesQuoteById(quoteId),
      payload,
    );
    debugPrint("=== API Response Update Quote ===");
    debugPrint(response.toString());
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  // Future<SalesQuote> approveQuote(
  //   String quoteId, [
  //   Map<String, dynamic>? payload,
  // ]) async {
  //   try {
  //     final response = await api.post(
  //       ApiEndpoints.salesQuoteApprove(quoteId),
  //       payload ?? {},
  //     );

  //     debugPrint('========== APPROVE QUOTE RESPONSE ==========');
  //     debugPrint(response.toString());
  //     debugPrint('============================================');

  //     final map = _asMap(response);
  //     final quote = map['quote'] is Map ? map['quote'] : map;

  //     return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  //   } on DioException catch (e) {
  //     debugPrint('========== APPROVE QUOTE ERROR ==========');
  //     debugPrint('STATUS: ${e.response?.statusCode}');
  //     debugPrint('DATA: ${e.response?.data}');
  //     debugPrint('==========================================');
  //     rethrow;
  //   }
  // }

  Future<SalesQuote> approveQuote(
    String quoteId, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      print('========== APPROVE QUOTE ==========');
      print('Quote ID: $quoteId');
      print('Payload: $payload');

      final response = await api.post(
        ApiEndpoints.salesQuoteApprove(quoteId),
        payload ?? {},
      );

      print('========== APPROVE RESPONSE ==========');
      print(response);
      print('======================================');

      final map = _asMap(response);
      final quote = map['quote'] is Map ? map['quote'] : map;

      return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
    } catch (e) {
      print('========== APPROVE ERROR ==========');
      print(e);

      if (e is DioException) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Response Headers: ${e.response?.headers}');
        print('Request Data: ${e.requestOptions.data}');
        print('Request URL: ${e.requestOptions.uri}');
      }

      print('===================================');

      rethrow;
    }
  }

  Future<SalesQuote> rejectQuote(String quoteId, String reason) async {
    final response = await api.post(ApiEndpoints.salesQuoteReject(quoteId), {
      'reason': reason,
    });
    final map = _asMap(response);
    final quote = map['quote'] is Map ? map['quote'] : map;
    return SalesQuote.fromJson(Map<String, dynamic>.from(quote as Map));
  }

  Future<SalesQuote> sendQuote(String quoteId) async {
    final response = await api.post(ApiEndpoints.salesQuoteSend(quoteId), {});
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
    debugPrint('=== MARK LOST API ===');
    debugPrint('Lead ID: $leadId');
    debugPrint('Reason: $reason');

    final response = await api.post(ApiEndpoints.salesLeadLost(leadId), {
      'reason': reason,
    });

    debugPrint('=== MARK LOST RESPONSE ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;

    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<SalesLead> requestWonApproval(String leadId) async {
    final response = await api.post(
      ApiEndpoints.salesLeadRequestWonApproval(leadId),
      {},
    );
    final map = _asMap(response);
    final lead = map['lead'] is Map ? map['lead'] : map;
    return SalesLead.fromJson(Map<String, dynamic>.from(lead as Map));
  }

  Future<dynamic> approveWon(
    String leadId, [
    Map<String, dynamic>? payload,
  ]) async {
    return api.post(ApiEndpoints.salesLeadApproveWon(leadId), payload ?? {});
  }

  Future<SalesLead> rejectWon(String leadId, String reason) async {
    final response = await api.post(ApiEndpoints.salesLeadRejectWon(leadId), {
      'reason': reason,
    });
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

    debugPrint("API Response ======");
    debugPrint(response.toString());
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

  Future<({String? customerId, SalesLead? lead, bool created})> ensureCustomer(
    String leadId,
  ) async {
    final response = await api.post(
      ApiEndpoints.salesLeadEnsureCustomer(leadId),
      {},
    );
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
    final response = await api.post(
      ApiEndpoints.salesLeadBills(leadId),
      payload,
    );
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

    debugPrint("=== API Response fetchCustomers ===");
    debugPrint('CUSTOMERS RAW: ${jsonEncode(response)}');

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

      debugPrint("=== API Response fetchCustomers ===");
      debugPrint('CUSTOMERS RAW: ${jsonEncode(list)}');
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

    // Response shape: { success, message, data: { team: [...] } }
    final data = map['data'];
    if (data is Map && data['team'] is List) {
      return data['team'] as List;
    }

    // Fallbacks, just in case backend shape changes later.
    if (map['team'] is List) {
      return map['team'] as List;
    }

    if (response is List) return response;

    return const [];
  }

  Future<Uint8List> downloadQuotePdf(String quoteId) async {
    final bytes = await api.downloadBytes(
      ApiEndpoints.salesPdfdownload(quoteId),
    );
    debugPrint("Download PDF  -----------------$bytes");
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> downloadBillPdf(String billId) async {
    final bytes = await api.downloadBytes(
      ApiEndpoints.salesPdfBillDownload(billId),
    );
    return Uint8List.fromList(bytes);
  }

  // ===========================================================================
  // Create Sales Order flow (Sales_CRM_Create_Sales_Order_APIs.md)
  //   Step 1: ensureCustomer(leadId)                         -- already above
  //   Step 2: createSalesOrder(customerId, items, notes)      -- POST /inventory/sales/auto
  //   Step 3: linkSalesOrderToLead(leadId, salesOrderId)       -- PATCH /sales/leads/:id
  // ===========================================================================

  List<Map<String, dynamic>> _listOfMaps(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Step 2 — creates the order via the Inventory "auto" endpoint (the same
  /// one the web CRM's "Create sales order" modal calls). `items` entries
  /// must each have `quantity` (> 0) and either `itemId` or `description`.
  Future<
    ({
      int? salesOrderId,
      String? invoiceNo,
      String? message,
      List<Map<String, dynamic>> itemsProcessed,
      List<Map<String, dynamic>> productionDemandsCreated,
      List<Map<String, dynamic>> productionOrdersNeeded,
      List<Map<String, dynamic>> purchaseOrdersNeeded,
    })
  >
  createSalesOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'customerId': int.tryParse(customerId) ?? customerId,
      'items': items,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    debugPrint('=== CREATE SALES ORDER REQUEST ===');
    debugPrint(jsonEncode(payload));

    final response = await api.post(ApiEndpoints.inventorySalesAuto, payload);

    debugPrint('=== CREATE SALES ORDER RESPONSE ===');
    debugPrint(response.toString());

    final map = _asMap(response);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final rawSalesOrderId = data['salesOrderId'];
    final salesOrderId = rawSalesOrderId is int
        ? rawSalesOrderId
        : int.tryParse('$rawSalesOrderId');

    return (
      salesOrderId: salesOrderId,
      invoiceNo: data['invoiceNo']?.toString(),
      message: (map['message'] ?? data['message'])?.toString(),
      itemsProcessed: _listOfMaps(data['itemsProcessed']),
      productionDemandsCreated: _listOfMaps(data['productionDemandsCreated']),
      productionOrdersNeeded: _listOfMaps(data['productionOrdersNeeded']),
      purchaseOrdersNeeded: _listOfMaps(data['purchaseOrdersNeeded']),
    );
  }

  /// Step 3 — links the newly created Inventory sales order back onto the
  /// CRM lead. Without this the order is orphaned and the lead still shows
  /// "Create sales order". Reuses the existing generic PATCH lead call.
  Future<SalesLead> linkSalesOrderToLead(
    String leadId,
    int salesOrderId, {
    String? timelineNote,
  }) {
    return updateLead(leadId, {
      'salesOrderId': salesOrderId,
      if (timelineNote != null && timelineNote.trim().isNotEmpty)
        'timelineEntry': {'type': 'note', 'text': timelineNote.trim()},
    });
  }

  Future<List<InventoryProductItem>> fetchItems({
    int page = 1,
    int limit = 25,
    String? search,
  }) async {
    final response = await api.get(
      ApiEndpoints.items,
      queryParams: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    debugPrint("=== API Response fetchItems ===");
    debugPrint('ITEMS RAW: ${jsonEncode(response)}');

    final map = _asMap(response);

    final List list = (map['data']?['items'] as List?) ?? [];

    return list
        .map((e) => InventoryProductItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}