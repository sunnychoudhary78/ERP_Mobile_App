import 'package:erp_app/features/inventory/product/data/model/cost_history_model.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/financial_report.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/stock_report_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    final res = await _api.post(ApiEndpoints.boms, body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateBom(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.put(ApiEndpoints.bomById(id.toString()), body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> deleteBom(int id) async {
    final res = await _api.deleteNoBody(ApiEndpoints.bomById(id.toString()));
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
        ? await _api.post(ApiEndpoints.items, body)
        : await _api.postMultipart(
            ApiEndpoints.items,
            FormData.fromMap({
              ...body,
              'image': await MultipartFile.fromFile(
                imagePath,
                filename: imageFilename,
              ),
            }),
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
        ? await _api.put(ApiEndpoints.itemById(id.toString()), body)
        : await _api.putMultipart(
            ApiEndpoints.itemById(id.toString()),
            FormData.fromMap({
              ...body,
              'image': await MultipartFile.fromFile(
                imagePath,
                filename: imageFilename,
              ),
            }),
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
    });
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
    final res = await _api.post(ApiEndpoints.categories, body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateCategory(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.put(ApiEndpoints.categoryById(id.toString()), body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final res = await _api.deleteNoBody(
      ApiEndpoints.categoryById(id.toString()),
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
    final res = await _api.postMultipart(ApiEndpoints.vendors, formData);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> updateVendor(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.put(ApiEndpoints.vendorById(id.toString()), body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> importVendors(
    List<Map<String, dynamic>> rows,
  ) async {
    final res = await _api.post(ApiEndpoints.importVendors, {'rows': rows});
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
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> approvePurchaseDemand(
    dynamic requestId, {
    String? note,
  }) async {
    final res = await _api.post(ApiEndpoints.approvalApprove, {
      'requestId': requestId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> rejectPurchaseDemand(
    dynamic requestId, {
    String? note,
  }) async {
    final res = await _api.post(ApiEndpoints.approvalReject, {
      'requestId': requestId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return Map<String, dynamic>.from(res as Map);
  }

  // ───────── Purchase Orders (section 10) ─────────

  Future<PagedPurchaseOrders> getPurchaseOrders({
    int page = 1,
    int limit = 25,
    String query = '',
  }) async {
    final res = await _api.get(
      ApiEndpoints.purchases,
      queryParams: {
        'page': page,
        'limit': limit,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
      headers: _companyHeader,
    );
    return PagedPurchaseOrders.fromResponse(res);
  }

  Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> body,
  ) async {
    final res = await _api.post(ApiEndpoints.purchases, body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> importPurchaseOrders(
    List<Map<String, dynamic>> rows,
  ) async {
    final res = await _api.post(ApiEndpoints.importPurchases, {'rows': rows});
    return Map<String, dynamic>.from(res as Map);
  }
}
