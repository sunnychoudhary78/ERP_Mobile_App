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
import 'package:erp_app/features/inventory/purchase/recives/data/model/purchase_bill_model.dart';

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

  Future<List<WarehouseStockRow>> getWarehouseStock({
    bool forceRefresh = false,
  }) => _getAllWarehouseStock(forceRefresh: forceRefresh);

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

  Future<List<String>> getPurchaseDemandStatuses() async {
    final statuses = <String>{};
    var result = await getPurchaseDemands();
    void collectStatuses(PagedPurchaseDemands page) {
      for (final demand in page.demands) {
        final status = demand.raw['status']?.toString().trim() ?? '';
        if (status.isNotEmpty) statuses.add(status);
      }
    }

    collectStatuses(result);
    for (var page = result.page + 1; page <= result.totalPages; page++) {
      result = await getPurchaseDemands(page: page);
      collectStatuses(result);
    }
    return statuses.toList();
  }

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
    String? status,
  }) => _api.getPurchaseOrders(
    page: page,
    limit: limit,
    query: query,
    status: status ?? '',
  );

  Future<Map<String, dynamic>> createPurchaseOrder(Map<String, dynamic> body) =>
      _api.createPurchaseOrder(body);

  Future<Map<String, dynamic>> importPurchaseOrders(
    List<Map<String, dynamic>> rows,
  ) => _api.importPurchaseOrders(rows);

  Future<Map<String, dynamic>> receivePurchase(
    int purchaseId, {
    required int warehouseId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
  }) => _api.receivePurchase(
    purchaseId,
    warehouseId: warehouseId,
    invoiceNumber: invoiceNumber,
    items: items,
  );

  Future<Map<String, dynamic>> receivePurchaseWithPhoto(
    int purchaseId, {
    required int warehouseId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required String invoicePhotoPath,
    String? invoicePhotoFilename,
  }) => _api.receivePurchaseWithPhoto(
    purchaseId,
    warehouseId: warehouseId,
    invoiceNumber: invoiceNumber,
    items: items,
    invoicePhotoPath: invoicePhotoPath,
    invoicePhotoFilename: invoicePhotoFilename,
  );

  Future<Map<String, dynamic>> rejectPurchase(int purchaseId) =>
      _api.rejectPurchase(purchaseId);

  Future<PurchaseBills> getPurchaseBills({
    int page = 1,
    int limit = 200,
    String query = '',
  }) => _api.getPurchaseBills(page: page, limit: limit, query: query);

  Future<Map<String, dynamic>> createBillFromPurchase(
    int purchaseId, {
    Map<String, dynamic>? extra,
  }) => _api.createBillFromPurchase(purchaseId, extra: extra);

  Future<Map<String, dynamic>> getVendorRaw(int id) => _api.getVendorRaw(id);

  Future<List<dynamic>> getPurchasesRaw({
    int page = 1,
    int limit = 200,
    String query = '',
  }) => _api.getPurchasesRaw(page: page, limit: limit, query: query);

  Future<List<dynamic>> getVendorPayments({
    int page = 1,
    int limit = 25,
    String query = '',
    int? vendorId,
    int? billId,
  }) => _api.getVendorPayments(
    page: page,
    limit: limit,
    query: query,
    vendorId: vendorId,
    billId: billId,
  );
  Future<Map<String, dynamic>> createVendorPayment(Map<String, dynamic> body) =>
      _api.createVendorPayment(body);
  Future<List<dynamic>> getVendorCredits() => _api.getVendorCredits();
  Future<Map<String, dynamic>> createVendorCredit(Map<String, dynamic> body) =>
      _api.createVendorCredit(body);
  Future<Map<String, dynamic>> createManualBill(Map<String, dynamic> body) =>
      _api.createManualBill(body);
  Future<List<dynamic>> getPaymentsReceived({int page = 1, int limit = 25}) =>
      _api.getPaymentsReceived(page: page, limit: limit);
  Future<Map<String, dynamic>> createPaymentReceived(
    Map<String, dynamic> body,
  ) => _api.createPaymentReceived(body);
  Future<List<dynamic>> getLots({
    int page = 1,
    int limit = 500,
    String status = '',
    String query = '',
  }) => _api.getLots(page: page, limit: limit, status: status, query: query);
  Future<Map<String, dynamic>> getLotSummary(int id) => _api.getLotSummary(id);
  Future<List<dynamic>> getLotProcessings(int id) => _api.getLotProcessings(id);
  Future<Map<String, dynamic>> startLotProcessing(
    int id,
    Map<String, dynamic> body,
  ) => _api.startLotProcessing(id, body);
  Future<Map<String, dynamic>> completeLotProcessing(
    int id,
    Map<String, dynamic> body,
  ) => _api.completeLotProcessing(id, body);
  Future<Map<String, dynamic>> sendLotForSelling(
    int id,
    Map<String, dynamic> body,
  ) => _api.sendLotForSelling(id, body);
  Future<Map<String, dynamic>> allocateDirectStock(Map<String, dynamic> body) =>
      _api.allocateDirectStock(body);
  Future<Map<String, dynamic>> stockIn(Map<String, dynamic> body) =>
      _api.stockIn(body);
  Future<Map<String, dynamic>> stockOut(Map<String, dynamic> body) =>
      _api.stockOut(body);
  Future<Map<String, dynamic>> transferStock(Map<String, dynamic> body) =>
      _api.transferStock(body);
  Future<List<dynamic>> getStockOutBills({int page = 1, int limit = 25}) =>
      _api.getStockOutBills(page: page, limit: limit);
  Future<dynamic> getStockOutBill(int id) => _api.getStockOutBill(id);
  Future<dynamic> getStockOutWarehouseStock(int id) =>
      _api.getStockOutWarehouseStock(id);
  Future<List<dynamic>> getTransactions({
    int page = 1,
    int limit = 500,
    String direction = '',
    String type = '',
    int? itemId,
  }) => _api.getTransactions(
    page: page,
    limit: limit,
    direction: direction,
    type: type,
    itemId: itemId,
  );
  Future<Map<String, dynamic>> saveWarehouse(Map<String, dynamic> body) =>
      _api.saveWarehouse(body);
  Future<Map<String, dynamic>> updateWarehouse(Map<String, dynamic> body) =>
      _api.updateWarehouse(body);
  Future<List<dynamic>> getDocuments({
    int page = 1,
    int limit = 25,
    int? lotId,
    String? startDate,
    String query = '',
  }) => _api.getDocuments(
    page: page,
    limit: limit,
    lotId: lotId,
    startDate: startDate,
    query: query,
  );
  Future<Map<String, dynamic>> uploadDocument({
    required String name,
    String? type,
    int? lotId,
    required String filePath,
  }) => _api.uploadDocument(
    name: name,
    type: type,
    lotId: lotId,
    filePath: filePath,
  );

  Future<Map<String, dynamic>> createDocumentLink({
    required String url,
    required String name,
    String? type,
    int? lotId,
  }) => _api.createDocumentLink(url: url, name: name, type: type, lotId: lotId);
  Future<Map<String, dynamic>> getInventoryApprovals({
    int page = 1,
    int limit = 25,
    String? status,
    String? type,
  }) => _api.getInventoryApprovals(
    page: page,
    limit: limit,
    status: status,
    type: type,
  );
  Future<Map<String, dynamic>> getMyApprovalRequests({
    int page = 1,
    int limit = 25,
  }) => _api.getMyApprovalRequests(page: page, limit: limit);
  Future<Map<String, dynamic>> getMyPendingApprovals({
    int page = 1,
    int limit = 25,
    String? status,
    String? type,
  }) => _api.getMyPendingApprovals(
    page: page,
    limit: limit,
    status: status,
    type: type,
  );
  Future<Map<String, dynamic>> approveInventoryRequest(
    dynamic id, {
    String? note,
    Map<String, dynamic>? data,
  }) => _api.approveInventoryRequest(id, note: note, data: data);
  Future<Map<String, dynamic>> rejectInventoryRequest(
    dynamic id, {
    String? note,
  }) => _api.rejectInventoryRequest(id, note: note);
  Future<Map<String, dynamic>> forwardInventoryRequest(
    dynamic id, {
    required String forwardToUserId,
    String? note,
  }) => _api.forwardInventoryRequest(
    id,
    forwardToUserId: forwardToUserId,
    note: note,
  );
  Future<Map<String, dynamic>> resubmitInventoryRequest(dynamic id) =>
      _api.resubmitInventoryRequest(id);
  Future<Map<String, dynamic>> updateInventoryRequest(
    dynamic id,
    Map<String, dynamic> data,
  ) => _api.updateInventoryRequest(id, data);
  Future<List<dynamic>> getLegacyCustomers({
    int page = 1,
    int limit = 25,
    String query = '',
  }) => _api.getLegacyCustomers(page: page, limit: limit, query: query);
  Future<Map<String, dynamic>> createLegacyCustomer(
    Map<String, dynamic> body,
  ) => _api.createLegacyCustomer(body);
  Future<Map<String, dynamic>> updateLegacyCustomer(
    int id,
    Map<String, dynamic> body,
  ) => _api.updateLegacyCustomer(id, body);
  Future<Map<String, dynamic>> deleteLegacyCustomer(int id) =>
      _api.deleteLegacyCustomer(id);
  Future<List<dynamic>> getLegacySales({
    int page = 1,
    int limit = 25,
    String query = '',
  }) => _api.getLegacySales(page: page, limit: limit, query: query);
  Future<Map<String, dynamic>> createLegacySale(
    Map<String, dynamic> body, {
    bool automatic = false,
  }) => _api.createLegacySale(body, automatic: automatic);
  Future<Map<String, dynamic>> fulfillLegacySale(int id) =>
      _api.fulfillLegacySale(id);
  Future<List<dynamic>> getLegacyInvoices({
    int page = 1,
    int limit = 25,
    String query = '',
  }) => _api.getLegacyInvoices(page: page, limit: limit, query: query);
  Future<List<dynamic>> getGstSlabs({bool activeOnly = true}) =>
      _api.getGstSlabs(activeOnly: activeOnly);
  Future<List<dynamic>> getCreditNotes({int page = 1, int limit = 25}) =>
      _api.getCreditNotes(page: page, limit: limit);
  Future<List<dynamic>> getSalesReturns({int page = 1, int limit = 25}) =>
      _api.getSalesReturns(page: page, limit: limit);
  Future<Map<String, dynamic>> updateSalesReturnStatus(int id, String status) =>
      _api.updateSalesReturnStatus(id, status);
  Future<List<dynamic>> getLegacyProductionOrders({
    int page = 1,
    int limit = 25,
  }) => _api.getLegacyProductionOrders(page: page, limit: limit);
  Future<Map<String, dynamic>> createLegacyProductionOrder({
    required int itemId,
    required num quantity,
  }) => _api.createLegacyProductionOrder(itemId: itemId, quantity: quantity);
  Future<Map<String, dynamic>> completeLegacyProductionOrder(
    int id, {
    int? rmWarehouse,
    int? fgWarehouse,
    String? workOrderId,
  }) => _api.completeLegacyProductionOrder(
    id,
    rmWarehouse: rmWarehouse,
    fgWarehouse: fgWarehouse,
    workOrderId: workOrderId,
  );
  Future<Map<String, dynamic>> getStockReconciliation() =>
      _api.getStockReconciliation();
  Future<List<dynamic>> getStockJournals({
    int limit = 100,
    String? journalType,
  }) => _api.getStockJournals(limit: limit, journalType: journalType);
  Future<Map<String, dynamic>> createStockJournal(Map<String, dynamic> body) =>
      _api.createStockJournal(body);
  Future<Map<String, dynamic>> getGodownStockValuation() =>
      _api.getGodownStockValuation();
  Future<Map<String, dynamic>> importItems(List<Map<String, dynamic>> rows) =>
      _api.importItems(rows);
  Future<List<dynamic>> lookupVendors({String search = '', int limit = 100}) =>
      _api.lookupVendors(search: search, limit: limit);
  Future<List<dynamic>> lookupWarehouses({
    String search = '',
    int limit = 100,
  }) => _api.lookupWarehouses(search: search, limit: limit);
}