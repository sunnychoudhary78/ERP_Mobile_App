import 'package:erp_app/features/inventory/shared/data/inventory_api_service.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_stock_model.dart';


class InventoryRepository {
  final InventoryApiService _api;

  InventoryRepository(this._api);

  // Simple in-memory cache for warehouse-stock (full dump — expensive to refetch every tap)
  List<WarehouseStockRow>? _warehouseStockCache;
  DateTime? _warehouseStockCachedAt;
  static const _cacheTtl = Duration(seconds: 90);

  Future<PagedItems> searchItems(
    String query, {
    int page = 1,
    int limit = 25,
  }) {
    return _api.searchItems(query, page: page, limit: limit);
  }

  Future<InventoryItem> getItem(int id) {
    return _api.getItem(id);
  }

  Future<List<WarehouseStockRow>> _getAllWarehouseStock({
    bool forceRefresh = false,
  }) async {
    final isFresh = _warehouseStockCache != null &&
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
}