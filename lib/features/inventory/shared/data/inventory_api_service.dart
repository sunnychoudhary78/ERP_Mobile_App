import 'package:erp_app/features/inventory/product/data/model/cost_history_model.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/financial_report.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/stock_report_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../purchase/recives/data/model/purchase_bill_model.dart';
import 'models/inventory_item_model.dart';
import 'models/warehouse_stock_model.dart';
import 'models/warehouse_model.dart';
import 'models/dashboard_stats_model.dart';
import '../../purchase/vendors/data/model/vendor_model.dart';
import '../../purchase/orders/data/model/purchase_demand_model.dart';
import '../../purchase/orders/data/model/purchase_order_model.dart';

class InventoryApiService {
  final ApiService _api;
  final Ref _ref;

  InventoryApiService(this._api, this._ref);

  Map<String, dynamic> get _companyHeader {
    final companyId = _ref.read(authProvider).profile?.companyId;
    if (companyId == null || companyId.isEmpty) return {};
    return {'x-company-id': companyId};
  }

  Future<PagedItems> searchItems(
    String query, {
    int page = 1,
    int limit = 25,
  }) async {
    final res = await _api.get(
      ApiEndpoints.items,
      queryParams: {'search': query, 'page': page, 'limit': limit},
      headers: _companyHeader,
    );
    return PagedItems.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<InventoryItem> getItem(int id) async {
    final res = await _api.get(
      ApiEndpoints.itemById(id.toString()),
      headers: _companyHeader,
    );
    return InventoryItem.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<WarehouseStockRow>> getWarehouseStock() async {
    final res = await _api.get(
      ApiEndpoints.inventoryWarehouseStock,
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => WarehouseStockRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final res = await _api.get(
      ApiEndpoints.inventoryLowStock,
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryDashboardStats> getDashboardStats() async {
    final res = await _api.get(
      ApiEndpoints.inventoryDashboardStats,
      headers: _companyHeader,
    );
    return InventoryDashboardStats.fromJson(
      res['data'] as Map<String, dynamic>,
    );
  }

  Future<List<Warehouse>> getWarehouses() async {
    final res = await _api.get(
      ApiEndpoints.warehouses,
      queryParams: {'page': 1, 'limit': 100},
      headers: _companyHeader,
    );
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    return list
        .map((e) => Warehouse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StockReportRow>> getStockReport() async {
    final res = await _api.get(
      ApiEndpoints.inventoryReport,
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => StockReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FinancialReport> getFinancialReport({String months = '12'}) async {
    final res = await _api.get(
      ApiEndpoints.inventoryReportsFinancial,
      queryParams: {'months': months},
      headers: _companyHeader,
    );
    return FinancialReport.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<ItemLookupResult>> lookupItems(
    String query, {
    int limit = 200,
    String? purpose,
  }) async {
    final res = await _api.get(
      ApiEndpoints.lookupItems,
      queryParams: {
        'search': query,
        'limit': limit,
        if (purpose != null) 'purpose': purpose,
      },
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => ItemLookupResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BillOfMaterials>> getBoms() async {
    final res = await _api.get(ApiEndpoints.boms, headers: _companyHeader);
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    return list
        .map((e) => BillOfMaterials.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BillOfMaterials> getBom(int id) async {
    final res = await _api.get(
      ApiEndpoints.bomById(id.toString()),
      headers: _companyHeader,
    );
    return BillOfMaterials.fromJson(
      Map<String, dynamic>.from(res['data'] as Map),
    );
  }

  Future<List<ItemLookupResult>> lookupBomItems() {
    return lookupItems('', limit: 1000, purpose: 'bom');
  }

  Future<Map<String, dynamic>> createBom(Map<String, dynamic> body) async {
    final res = await _api.post(
      ApiEndpoints.boms,
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateBom(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.put(
      ApiEndpoints.bomById(id.toString()),
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> deleteBom(int id) async {
    final res = await _api.deleteNoBody(
      ApiEndpoints.bomById(id.toString()),
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────── Products (doc section 5) ─────────

  /// Full Products list. Reuses the same `GET /items` endpoint as
  /// [searchItems] — `search` may be an empty string for "show everything".
  Future<PagedItems> getItems({
    String search = '',
    int page = 1,
    int limit = 25,
  }) {
    return searchItems(search, page: page, limit: limit);
  }

  /// `POST /api/items` — JSON or multipart when [imagePath] is supplied.
  /// Returns the full response envelope so the caller can check for
  /// `approvalId` (write went to approval instead of applying immediately).
  Future<Map<String, dynamic>> createItem(
    Map<String, dynamic> body, {
    String? imagePath,
    String? imageFilename,
  }) async {
    final res = imagePath == null
        ? await _api.post(ApiEndpoints.items, body, headers: _companyHeader)
        : await _api.postMultipart(
            ApiEndpoints.items,
            FormData.fromMap({
              ...body,
              'image': await MultipartFile.fromFile(
                imagePath,
                filename: imageFilename,
              ),
            }),
            headers: _companyHeader,
          );
    return Map<String, dynamic>.from(res as Map);
  }

  /// `PUT /api/items/:id` — JSON or multipart when [imagePath] is supplied.
  Future<Map<String, dynamic>> updateItem(
    int id,
    Map<String, dynamic> body, {
    String? imagePath,
    String? imageFilename,
  }) async {
    final res = imagePath == null
        ? await _api.put(
            ApiEndpoints.itemById(id.toString()),
            body,
            headers: _companyHeader,
          )
        : await _api.putMultipart(
            ApiEndpoints.itemById(id.toString()),
            FormData.fromMap({
              ...body,
              'image': await MultipartFile.fromFile(
                imagePath,
                filename: imageFilename,
              ),
            }),
            headers: _companyHeader,
          );
    return Map<String, dynamic>.from(res as Map);
  }

  /// `PATCH /api/items/:id/stock` — direct stock quantity correction.
  Future<Map<String, dynamic>> updateItemStock(
    int id, {
    required num quantity,
    String? warehouseHint,
  }) async {
    final res = await _api.patch(ApiEndpoints.itemStock(id.toString()), {
      'quantity': quantity,
      if (warehouseHint != null) 'warehouseHint': warehouseHint,
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  /// `GET /api/items/next-product-code` → `{ productCode }`
  Future<String?> getNextProductCode() async {
    final res = await _api.get(
      ApiEndpoints.nextProductCode,
      headers: _companyHeader,
    );
    final data = res['data'];
    if (data is Map) return data['productCode']?.toString();
    return null;
  }

  Future<Map<String, dynamic>> importItems(
    List<Map<String, dynamic>> rows,
  ) async => Map<String, dynamic>.from(
    await _api.post(ApiEndpoints.importItems, {
          'rows': rows,
        }, headers: _companyHeader)
        as Map,
  );

  Future<List<dynamic>> lookupVendors({
    String search = '',
    int limit = 100,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.lookupVendors, {
      'search': search,
      'limit': limit,
    }),
    const ['vendors', 'data'],
  );

  Future<List<dynamic>> lookupWarehouses({
    String search = '',
    int limit = 100,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.lookupWarehouses, {
      'search': search,
      'limit': limit,
    }),
    const ['warehouses', 'data'],
  );

  /// `GET /api/items/:id/cost-history?limit=`
  Future<List<CostHistoryEntry>> getItemCostHistory(
    int id, {
    int limit = 25,
  }) async {
    final res = await _api.get(
      ApiEndpoints.itemCostHistory(id.toString()),
      queryParams: {'limit': limit},
      headers: _companyHeader,
    );
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    return list
        .map((e) => CostHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/lookups/product-categories` — used by the product form's
  /// category dropdown.
  Future<List<ProductCategoryLite>> getProductCategories({
    String search = '',
    int limit = 100,
  }) async {
    final res = await _api.get(
      ApiEndpoints.lookupProductCategories,
      queryParams: {'search': search, 'limit': limit},
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => ProductCategoryLite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductCategory>> getCategoryManagementList() async {
    final res = await _api.get(
      ApiEndpoints.categories,
      headers: _companyHeader,
    );
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    return list
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final res = await _api.post(
      ApiEndpoints.categories,
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateCategory(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.put(
      ApiEndpoints.categoryById(id.toString()),
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final res = await _api.deleteNoBody(
      ApiEndpoints.categoryById(id.toString()),
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────── Vendors (section 8) ─────────

  Future<PagedVendors> getVendors({
    int page = 1,
    int limit = 25,
    String query = '',
  }) async {
    final res = await _api.get(
      ApiEndpoints.vendors,
      queryParams: {
        'page': page,
        'limit': limit,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
      headers: _companyHeader,
    );
    final data = res['data'];
    if (data is Map) {
      return PagedVendors.fromJson(Map<String, dynamic>.from(data));
    }
    return const PagedVendors(
      vendors: [],
      page: 1,
      limit: 0,
      total: 0,
      totalPages: 1,
    );
  }

  Future<Vendor> getVendor(int id) async {
    final res = await _api.get(
      ApiEndpoints.vendorById(id.toString()),
      headers: _companyHeader,
    );
    debugPrint('getVendor response:---->>>>>>>>>>> $res');
    return Vendor.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> body, {
    String? panCardPath,
    String? aadharCardPath,
    String? panCardFilename,
    String? aadharCardFilename,
  }) async {
    final formData = FormData.fromMap({
      ...body,
      if (panCardPath != null)
        'panCard': await MultipartFile.fromFile(
          panCardPath,
          filename: panCardFilename,
        ),
      if (aadharCardPath != null)
        'aadharCard': await MultipartFile.fromFile(
          aadharCardPath,
          filename: aadharCardFilename,
        ),
    });
    final res = await _api.postMultipart(
      ApiEndpoints.vendors,
      formData,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateVendor(
    int id,
    Map<String, dynamic> body,
  ) async {
    debugPrint('updateVendor request body: $body');
    try {
      final res = await _api.put(
        ApiEndpoints.vendorById(id.toString()),
        body,
        headers: _companyHeader,
      );
      return Map<String, dynamic>.from(res as Map);
    } on DioException catch (e) {
      debugPrint('updateVendor DIO ERROR status: ${e.response?.statusCode}');
      debugPrint('updateVendor DIO ERROR response body: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> importVendors(
    List<Map<String, dynamic>> rows,
  ) async {
    final res = await _api.post(ApiEndpoints.importVendors, {
      'rows': rows,
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────── Purchase Demand (section 9) ─────────

  Future<PagedPurchaseDemands> getPurchaseDemands({
    int page = 1,
    int limit = 25,
    String? status,
  }) async {
    final res = await _api.get(
      ApiEndpoints.purchaseDemands,
      queryParams: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      headers: _companyHeader,
    );
    return PagedPurchaseDemands.fromResponse(res);
  }

  Future<Map<String, dynamic>> raisePurchases(
    String workOrderId, {
    required Map<String, dynamic> vendorByItemId,
    bool persistVendorOnItems = false,
  }) async {
    final res = await _api.post(ApiEndpoints.raisePurchases(workOrderId), {
      'vendorByItemId': vendorByItemId,
      'persistVendorOnItems': persistVendorOnItems,
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> approvePurchaseDemand(
    dynamic requestId, {
    String? note,
  }) async {
    final res = await _api.post(ApiEndpoints.approvalApprove, {
      'requestId': requestId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> rejectPurchaseDemand(
    dynamic requestId, {
    String? note,
  }) async {
    final res = await _api.post(ApiEndpoints.approvalReject, {
      'requestId': requestId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────── Purchase Orders (section 10) ─────────

  Future<PagedPurchaseOrders> getPurchaseOrders({
    int page = 1,
    int limit = 25,
    String query = '',
    String status = '',
  }) async {
    final res = await _api.get(
      ApiEndpoints.purchases,
      queryParams: {
        'page': page,
        'limit': limit,
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
      headers: _companyHeader,
    );
    return PagedPurchaseOrders.fromResponse(res);
  }

  Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> body,
  ) async {
    final res = await _api.post(
      ApiEndpoints.purchases,
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> importPurchaseOrders(
    List<Map<String, dynamic>> rows,
  ) async {
    final res = await _api.post(ApiEndpoints.importPurchases, {
      'rows': rows,
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> receivePurchase(
    int purchaseId, {
    required int warehouseId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'warehouseId': warehouseId,
      'invoiceNumber': invoiceNumber,
      'items': items,
    };
    final res = await _api.post(
      ApiEndpoints.purchaseReceive(purchaseId.toString()),
      body,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> receivePurchaseWithPhoto(
    int purchaseId, {
    required int warehouseId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required String invoicePhotoPath,
    String? invoicePhotoFilename,
  }) async {
    final formItems = <String, dynamic>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      for (final entry in item.entries) {
        formItems['items[$i][${entry.key}]'] = entry.value;
      }
    }

    final formData = FormData.fromMap({
      'warehouseId': warehouseId,
      'invoiceNumber': invoiceNumber,
      ...formItems,
      'invoicePhoto': await MultipartFile.fromFile(
        invoicePhotoPath,
        filename: invoicePhotoFilename,
      ),
    });
    final res = await _api.postMultipart(
      ApiEndpoints.purchaseReceive(purchaseId.toString()),
      formData,
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> rejectPurchase(int purchaseId) async {
    final res = await _api.post(
      ApiEndpoints.purchaseReject(purchaseId.toString()),
      <String, dynamic>{},
      headers: _companyHeader,
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<PurchaseBills> getPurchaseBills() async {
    final res = await _api.get(ApiEndpoints.bills, headers: _companyHeader);
    return PurchaseBills.fromResponse(res);
  }

  Future<Map<String, dynamic>> createBillFromPurchase(int purchaseId) async {
    final res = await _api.post(ApiEndpoints.billFromPurchase, {
      'purchaseId': purchaseId,
    }, headers: _companyHeader);
    return Map<String, dynamic>.from(res as Map);
  }

  // Inventory API guide sections 12–18: payables, lots, movements, warehouses,
  // ledger, reports and documents. Keep envelopes intact for approvalId.
  Future<dynamic> _getInventory(String path, [Map<String, dynamic>? query]) =>
      _api.get(path, queryParams: query, headers: _companyHeader);

  Future<Map<String, dynamic>> _postInventory(
    String path,
    Map<String, dynamic> body,
  ) async => Map<String, dynamic>.from(
    await _api.post(path, body, headers: _companyHeader) as Map,
  );

  Future<List<dynamic>> getVendorPayments({
    int page = 1,
    int limit = 25,
    String query = '',
    int? vendorId,
    int? billId,
  }) async {
    final res = await _getInventory(ApiEndpoints.vendorPayments, {
      'page': page,
      'limit': limit,
      if (query.isNotEmpty) 'q': query,
      if (vendorId != null) 'vendorId': vendorId,
      if (billId != null) 'billId': billId,
    });
    return _extractList(res, const ['payments', 'data']);
  }

  Future<Map<String, dynamic>> createVendorPayment(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.vendorPayments, body);
  Future<List<dynamic>> getVendorCredits() async => _extractList(
    await _getInventory(ApiEndpoints.vendorCredits),
    const ['credits', 'data'],
  );
  Future<Map<String, dynamic>> createVendorCredit(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.vendorCredits, body);
  Future<Map<String, dynamic>> createManualBill(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.bills, body);
  Future<List<dynamic>> getPaymentsReceived({
    int page = 1,
    int limit = 25,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.paymentsReceived, {
      'page': page,
      'limit': limit,
    }),
    const ['payments', 'data'],
  );
  Future<Map<String, dynamic>> createPaymentReceived(
    Map<String, dynamic> body,
  ) => _postInventory(ApiEndpoints.paymentsReceived, body);

  Future<List<dynamic>> getLots({
    int page = 1,
    int limit = 500,
    String status = '',
    String query = '',
  }) async => _extractList(
    await _getInventory(ApiEndpoints.lots, {
      'page': page,
      'limit': limit,
      if (status.isNotEmpty) 'status': status,
      if (query.isNotEmpty) 'q': query,
    }),
    const ['lots', 'data'],
  );
  Future<Map<String, dynamic>> getLotSummary(int id) async =>
      Map<String, dynamic>.from(
        (await _getInventory(ApiEndpoints.lotSummary('$id')))['data'] as Map,
      );
  Future<List<dynamic>> getLotProcessings(int id) async => _extractList(
    await _getInventory(ApiEndpoints.lotProcessings('$id')),
    const ['processings', 'data'],
  );
  Future<Map<String, dynamic>> startLotProcessing(
    int id,
    Map<String, dynamic> body,
  ) => _postInventory(ApiEndpoints.lotStartProcessing('$id'), body);
  Future<Map<String, dynamic>> completeLotProcessing(
    int processingId,
    Map<String, dynamic> body,
  ) =>
      _postInventory(ApiEndpoints.lotProcessingComplete('$processingId'), body);
  Future<Map<String, dynamic>> sendLotForSelling(
    int id,
    Map<String, dynamic> body,
  ) => _postInventory(ApiEndpoints.lotSendForSelling('$id'), body);
  Future<Map<String, dynamic>> allocateDirectStock(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.allocateDirectStock, body);

  Future<Map<String, dynamic>> stockIn(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.stockIn, body);
  Future<Map<String, dynamic>> stockOut(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.stockOut, body);
  Future<Map<String, dynamic>> transferStock(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.stockTransfer, body);
  Future<List<dynamic>> getStockOutBills({
    int page = 1,
    int limit = 25,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.stockOutBills, {
      'page': page,
      'limit': limit,
    }),
    const ['bills', 'data'],
  );
  Future<dynamic> getStockOutBill(int id) =>
      _getInventory(ApiEndpoints.stockOutBillById('$id'));
  Future<dynamic> getStockOutWarehouseStock(int itemId) =>
      _getInventory(ApiEndpoints.stockOutWarehouseStock, {'itemId': itemId});
  Future<List<dynamic>> getTransactions({
    int page = 1,
    int limit = 500,
    String direction = '',
    String type = '',
    int? itemId,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.inventoryTransactions, {
      'page': page,
      'limit': limit,
      if (direction.isNotEmpty) 'direction': direction,
      if (type.isNotEmpty) 'type': type,
      if (itemId != null) 'itemId': itemId,
    }),
    const ['transactions', 'data'],
  );

  Future<Map<String, dynamic>> saveWarehouse(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.warehouses, body);
  Future<Map<String, dynamic>> updateWarehouse(
    Map<String, dynamic> body,
  ) async => Map<String, dynamic>.from(
    await _api.put(ApiEndpoints.warehouses, body, headers: _companyHeader)
        as Map,
  );
  Future<List<dynamic>> getDocuments({
    int page = 1,
    int limit = 25,
    int? lotId,
    String? startDate,
    String query = '',
  }) async => _extractList(
    await _getInventory(ApiEndpoints.documents, {
      'page': page,
      'limit': limit,
      if (lotId != null) 'lotId': lotId,
      if (startDate != null) 'startDate': startDate,
      if (query.isNotEmpty) 'q': query,
    }),
    const ['documents', 'data'],
  );
  Future<Map<String, dynamic>> uploadDocument({
    required String name,
    String? type,
    int? lotId,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      if (type != null) 'type': type,
      if (lotId != null) 'lotId': lotId,
      'file': await MultipartFile.fromFile(filePath),
    });
    return Map<String, dynamic>.from(
      await _api.postMultipart(
            ApiEndpoints.documents,
            form,
            headers: _companyHeader,
          )
          as Map,
    );
  }

  Future<Map<String, dynamic>> createDocumentLink({
    required String url,
    required String name,
    String? type,
    int? lotId,
  }) => _postInventory(ApiEndpoints.documents, {
    'url': url,
    'name': name,
    if (type != null) 'type': type,
    if (lotId != null) 'lotId': lotId,
  });

  // Section 19: Inventory approval request lifecycle.
  Future<Map<String, dynamic>> getInventoryApprovals({
    int page = 1,
    int limit = 25,
    String? status,
    String? type,
  }) => _postInventory(ApiEndpoints.approvalList, {
    'page': page,
    'limit': limit,
    if (status != null && status.isNotEmpty) 'status': status,
    if (type != null && type.isNotEmpty) 'type': type,
  });
  Future<Map<String, dynamic>> getMyApprovalRequests({
    int page = 1,
    int limit = 25,
  }) => _postInventory(ApiEndpoints.approvalMyRequests, {
    'page': page,
    'limit': limit,
  });
  Future<Map<String, dynamic>> getMyPendingApprovals({
    int page = 1,
    int limit = 25,
    String? status,
    String? type,
  }) => _postInventory(ApiEndpoints.approvalMyPending, {
    'page': page,
    'limit': limit,
    if (status != null && status.isNotEmpty) 'status': status,
    if (type != null && type.isNotEmpty) 'type': type,
  });
  Future<Map<String, dynamic>> approveInventoryRequest(
    dynamic requestId, {
    String? note,
    Map<String, dynamic>? data,
  }) => _postInventory(ApiEndpoints.approvalApprove, {
    'requestId': requestId,
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    if (data != null) 'data': data,
  });
  Future<Map<String, dynamic>> rejectInventoryRequest(
    dynamic requestId, {
    String? note,
  }) => _postInventory(ApiEndpoints.approvalReject, {
    'requestId': requestId,
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  });
  Future<Map<String, dynamic>> forwardInventoryRequest(
    dynamic requestId, {
    required String forwardToUserId,
    String? note,
  }) => _postInventory(ApiEndpoints.approvalForward, {
    'requestId': requestId,
    'forwardToUserId': forwardToUserId,
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  });
  Future<Map<String, dynamic>> resubmitInventoryRequest(dynamic requestId) =>
      _postInventory(ApiEndpoints.approvalMyResubmit, {'requestId': requestId});
  Future<Map<String, dynamic>> updateInventoryRequest(
    dynamic requestId,
    Map<String, dynamic> data,
  ) => _postInventory(ApiEndpoints.approvalMyUpdate, {
    'requestId': requestId,
    'data': data,
  });

  // Section 20: legacy Inventory sales endpoints.
  Future<List<dynamic>> getLegacyCustomers({
    int page = 1,
    int limit = 25,
    String query = '',
  }) async => _extractList(
    await _getInventory(ApiEndpoints.customers, {
      'page': page,
      'limit': limit,
      if (query.isNotEmpty) 'q': query,
    }),
    const ['customers', 'data'],
  );
  Future<Map<String, dynamic>> createLegacyCustomer(
    Map<String, dynamic> body,
  ) => _postInventory(ApiEndpoints.customers, body);
  Future<Map<String, dynamic>> updateLegacyCustomer(
    int id,
    Map<String, dynamic> body,
  ) async => Map<String, dynamic>.from(
    await _api.put(
          ApiEndpoints.customerById('$id'),
          body,
          headers: _companyHeader,
        )
        as Map,
  );
  Future<Map<String, dynamic>> deleteLegacyCustomer(int id) async =>
      Map<String, dynamic>.from(
        await _api.deleteNoBody(
              ApiEndpoints.customerById('$id'),
              headers: _companyHeader,
            )
            as Map,
      );
  Future<List<dynamic>> getLegacySales({
    int page = 1,
    int limit = 25,
    String query = '',
  }) async => _extractList(
    await _getInventory(ApiEndpoints.legacySales, {
      'page': page,
      'limit': limit,
      if (query.isNotEmpty) 'q': query,
    }),
    const ['sales', 'data'],
  );
  Future<Map<String, dynamic>> createLegacySale(
    Map<String, dynamic> body, {
    bool automatic = false,
  }) => _postInventory(
    automatic ? ApiEndpoints.legacySalesAuto : ApiEndpoints.legacySales,
    body,
  );
  Future<Map<String, dynamic>> fulfillLegacySale(int id) =>
      _postInventory(ApiEndpoints.legacySaleFulfill('$id'), {});
  Future<List<dynamic>> getLegacyInvoices({
    int page = 1,
    int limit = 25,
    String query = '',
  }) async => _extractList(
    await _getInventory(ApiEndpoints.customerInvoices, {
      'page': page,
      'limit': limit,
      if (query.isNotEmpty) 'q': query,
    }),
    const ['invoices', 'data'],
  );
  Future<List<dynamic>> getGstSlabs({bool activeOnly = true}) async =>
      _extractList(
        await _getInventory(ApiEndpoints.accountGstSlabs, {
          'activeOnly': activeOnly,
        }),
        const ['gstSlabs', 'data'],
      );
  Future<List<dynamic>> getCreditNotes({int page = 1, int limit = 25}) async =>
      _extractList(
        await _getInventory(ApiEndpoints.accountCreditNotes, {
          'page': page,
          'limit': limit,
        }),
        const ['creditNotes', 'data'],
      );
  Future<List<dynamic>> getSalesReturns({int page = 1, int limit = 25}) async =>
      _extractList(
        await _getInventory(ApiEndpoints.accountSalesReturns, {
          'page': page,
          'limit': limit,
        }),
        const ['salesReturns', 'returns', 'data'],
      );
  Future<Map<String, dynamic>> updateSalesReturnStatus(
    int id,
    String status,
  ) async => Map<String, dynamic>.from(
    await _api.patch(ApiEndpoints.accountSalesReturnStatus('$id'), {
          'status': status,
        }, headers: _companyHeader)
        as Map,
  );

  // Section 21: legacy Inventory ProductionOrder APIs.
  Future<List<dynamic>> getLegacyProductionOrders({
    int page = 1,
    int limit = 25,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.legacyProduction, {
      'page': page,
      'limit': limit,
    }),
    const ['production', 'orders', 'data'],
  );
  Future<Map<String, dynamic>> createLegacyProductionOrder({
    required int itemId,
    required num quantity,
  }) => _postInventory(ApiEndpoints.legacyProduction, {
    'itemId': itemId,
    'quantity': quantity,
  });
  Future<Map<String, dynamic>> completeLegacyProductionOrder(
    int id, {
    int? rmWarehouse,
    int? fgWarehouse,
    String? workOrderId,
  }) => _postInventory(ApiEndpoints.legacyProductionComplete('$id'), {
    if (rmWarehouse != null) 'rmWarehouse': rmWarehouse,
    if (fgWarehouse != null) 'fgWarehouse': fgWarehouse,
    if (workOrderId != null) 'workOrderId': workOrderId,
  });

  // Section 22: Accounts inventory.
  Future<Map<String, dynamic>> getStockReconciliation() async =>
      Map<String, dynamic>.from(
        await _getInventory(ApiEndpoints.stockReconciliation) as Map,
      );
  Future<List<dynamic>> getStockJournals({
    int limit = 100,
    String? journalType,
  }) async => _extractList(
    await _getInventory(ApiEndpoints.stockJournals, {
      'limit': limit,
      if (journalType != null && journalType.isNotEmpty)
        'journalType': journalType,
    }),
    const ['journals', 'data'],
  );
  Future<Map<String, dynamic>> createStockJournal(Map<String, dynamic> body) =>
      _postInventory(ApiEndpoints.stockJournals, body);
  Future<Map<String, dynamic>> getGodownStockValuation() async =>
      Map<String, dynamic>.from(
        await _getInventory(ApiEndpoints.godownStockValuation) as Map,
      );

  List<dynamic> _extractList(dynamic response, List<String> keys) {
    dynamic value = response;
    if (value is Map && value['data'] != null) value = value['data'];
    if (value is Map) {
      for (final key in keys) {
        if (value[key] is List) return List<dynamic>.from(value[key] as List);
      }
    }
    return value is List ? List<dynamic>.from(value) : const [];
  }
}
