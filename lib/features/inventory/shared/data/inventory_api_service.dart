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
    return InventoryDashboardStats.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<Warehouse>> getWarehouses() async {
    final res = await _api.get(
      ApiEndpoints.warehouses,
      queryParams: {'page': 1, 'limit': 100},
      headers: _companyHeader,
    );
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    return list.map((e) => Warehouse.fromJson(e as Map<String, dynamic>)).toList();
  }
}