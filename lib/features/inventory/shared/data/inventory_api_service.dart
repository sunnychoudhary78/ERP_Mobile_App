import 'package:erp_app/features/inventory/product/data/model/cost_history_model.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
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
  }) async {
    final res = await _api.get(
      ApiEndpoints.lookupItems,
      queryParams: {'search': query, 'limit': limit},
      headers: _companyHeader,
    );
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => ItemLookupResult.fromJson(e as Map<String, dynamic>))
        .toList();
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
    Map<String, dynamic> body,
    {
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
}