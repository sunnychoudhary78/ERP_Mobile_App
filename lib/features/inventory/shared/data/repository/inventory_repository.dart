import 'package:erp_app/features/inventory/product/data/model/cost_history_model.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/shared/data/inventory_api_service.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/financial_report.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/stock_report_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_stock_model.dart';
import 'package:erp_app/features/inventory/purchase/vendors/data/model/vendor_model.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_demand_model.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_order_model.dart';

class InventoryRepository {
  final InventoryApiService _api;

  InventoryRepository(this._api);

  // Simple in-memory cache for warehouse-stock (full dump — expensive to refetch every tap)
  List<WarehouseStockRow>? _warehouseStockCache;
  DateTime? _warehouseStockCachedAt;
  static const _cacheTtl = Duration(seconds: 90);

  Future<PagedItems> searchItems(String query, {int page = 1, int limit = 25}) {
    return _api.searchItems(query, page: page, limit: limit);
  }

  Future<InventoryItem> getItem(int id) {
    return _api.getItem(id);
  }

  Future<List<WarehouseStockRow>> _getAllWarehouseStock({
    bool forceRefresh = false,
  }) async {
    final isFresh =
        _warehouseStockCache != null &&
        _warehouseStockCachedAt != null &&
        DateTime.now().difference(_warehouseStockCachedAt!) < _cacheTtl;

    if (!forceRefresh && isFresh) {
      return _warehouseStockCache!;
    }

    final rows = await _api.getWarehouseStock();
    _warehouseStockCache = rows;
    _warehouseStockCachedAt = DateTime.now();
    return rows;
  }

  /// Fetches (or reuses cached) full warehouse-stock dump and filters
  /// client-side for [itemId], since the backend ignores ?itemId= today.
  Future<List<WarehouseStockRow>> getWarehouseStockForItem(
    int itemId, {
    bool forceRefresh = false,
  }) async {
    final all = await _getAllWarehouseStock(forceRefresh: forceRefresh);
    return all.where((r) => r.itemId == itemId).toList();
  }

  Future<List<InventoryItem>> getLowStockItems() {
    return _api.getLowStockItems();
  }

  Future<InventoryDashboardStats> getDashboardStats() {
    return _api.getDashboardStats();
  }

  Future<List<Warehouse>> getWarehouses() {
    return _api.getWarehouses();
  }

  Future<List<StockReportRow>> getStockReport() {
    return _api.getStockReport();
  }

  /// Section 5.4 — period financial summary.
  Future<FinancialReport> getFinancialReport({String months = '12'}) {
    return _api.getFinancialReport(months: months);
  }

  /// Compact typeahead lookup (6.1b) — lighter than searchItems(), no stock qty.
  Future<List<ItemLookupResult>> lookupItems(
    String query, {
    int limit = 200,
    String? purpose,
  }) {
    if (query.trim().isEmpty) return Future.value(const []);
    return _api.lookupItems(query, limit: limit, purpose: purpose);
  }

  Future<List<ItemLookupResult>> lookupBomItems() => _api.lookupBomItems();

  Future<List<BillOfMaterials>> getBoms() => _api.getBoms();

  Future<BillOfMaterials> getBom(int id) => _api.getBom(id);

  Future<Map<String, dynamic>> createBom(Map<String, dynamic> body) =>
      _api.createBom(body);

  Future<Map<String, dynamic>> updateBom(int id, Map<String, dynamic> body) =>
      _api.updateBom(id, body);

  Future<Map<String, dynamic>> deleteBom(int id) => _api.deleteBom(id);

  // ───────── Products (section 5) ─────────

  Future<PagedItems> getItems({
    String search = '',
    int page = 1,
    int limit = 25,
  }) {
    return _api.getItems(search: search, page: page, limit: limit);
  }

  Future<Map<String, dynamic>> createItem(
    Map<String, dynamic> body, {
    String? imagePath,
    String? imageFilename,
  }) {
    return _api.createItem(
      body,
      imagePath: imagePath,
      imageFilename: imageFilename,
    );
  }

  Future<Map<String, dynamic>> updateItem(
    int id,
    Map<String, dynamic> body, {
    String? imagePath,
    String? imageFilename,
  }) {
    return _api.updateItem(
      id,
      body,
      imagePath: imagePath,
      imageFilename: imageFilename,
    );
  }

  Future<Map<String, dynamic>> updateItemStock(
    int id, {
    required num quantity,
    String? warehouseHint,
  }) {
    return _api.updateItemStock(
      id,
      quantity: quantity,
      warehouseHint: warehouseHint,
    );
  }

  Future<String?> getNextProductCode() {
    return _api.getNextProductCode();
  }

  Future<List<CostHistoryEntry>> getItemCostHistory(int id) {
    return _api.getItemCostHistory(id);
  }

  // Categories rarely change mid-session — cache for the form's dropdown.
  List<ProductCategoryLite>? _categoriesCache;

  Future<List<ProductCategoryLite>> getProductCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _categoriesCache != null) return _categoriesCache!;
    final list = await _api.getProductCategories();
    _categoriesCache = list;
    return list;
  }

  Future<List<ProductCategory>> getCategoryManagementList() {
    return _api.getCategoryManagementList();
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final result = await _api.createCategory(body);
    _categoriesCache = null;
    return result;
  }

  Future<Map<String, dynamic>> updateCategory(
    int id,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.updateCategory(id, body);
    _categoriesCache = null;
    return result;
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final result = await _api.deleteCategory(id);
    _categoriesCache = null;
    return result;
  }

  // ───────── Vendors (section 8) ─────────

  Future<PagedVendors> getVendors({
    int page = 1,
    int limit = 25,
    String query = '',
  }) {
    return _api.getVendors(page: page, limit: limit, query: query);
  }

  Future<Vendor> getVendor(int id) => _api.getVendor(id);

  Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> body, {
    String? panCardPath,
    String? aadharCardPath,
    String? panCardFilename,
    String? aadharCardFilename,
  }) {
    return _api.createVendor(
      body,
      panCardPath: panCardPath,
      aadharCardPath: aadharCardPath,
      panCardFilename: panCardFilename,
      aadharCardFilename: aadharCardFilename,
    );
  }

  Future<Map<String, dynamic>> updateVendor(
    int id,
    Map<String, dynamic> body,
  ) => _api.updateVendor(id, body);

  Future<Map<String, dynamic>> importVendors(List<Map<String, dynamic>> rows) =>
      _api.importVendors(rows);

  Future<PagedPurchaseDemands> getPurchaseDemands({
    int page = 1,
    int limit = 25,
    String? status,
  }) => _api.getPurchaseDemands(page: page, limit: limit, status: status);

  Future<Map<String, dynamic>> raisePurchases(
    String workOrderId, {
    required Map<String, dynamic> vendorByItemId,
    bool persistVendorOnItems = false,
  }) => _api.raisePurchases(
    workOrderId,
    vendorByItemId: vendorByItemId,
    persistVendorOnItems: persistVendorOnItems,
  );

  Future<Map<String, dynamic>> approvePurchaseDemand(
    dynamic requestId, {
    String? note,
  }) => _api.approvePurchaseDemand(requestId, note: note);

  Future<Map<String, dynamic>> rejectPurchaseDemand(
    dynamic requestId, {
    String? note,
  }) => _api.rejectPurchaseDemand(requestId, note: note);

  Future<PagedPurchaseOrders> getPurchaseOrders({
    int page = 1,
    int limit = 25,
    String query = '',
  }) => _api.getPurchaseOrders(page: page, limit: limit, query: query);

  Future<Map<String, dynamic>> createPurchaseOrder(Map<String, dynamic> body) =>
      _api.createPurchaseOrder(body);

  Future<Map<String, dynamic>> importPurchaseOrders(
    List<Map<String, dynamic>> rows,
  ) => _api.importPurchaseOrders(rows);
}
