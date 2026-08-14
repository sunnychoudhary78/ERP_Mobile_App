import 'package:erp_app/core/providers/network_providers.dart';
import 'package:erp_app/features/inventory/shared/data/inventory_api_service.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/financial_report.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/stock_report_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_stock_model.dart';
import 'package:erp_app/features/inventory/shared/data/repository/inventory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────── DI ─────────

final inventoryApiServiceProvider = Provider<InventoryApiService>((ref) {
  final api = ref.read(apiServiceProvider);
  return InventoryApiService(api, ref);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final api = ref.read(inventoryApiServiceProvider);
  return InventoryRepository(api);
});

// ───────── Stock Lookup (search) state ─────────

class StockLookupState {
  final bool isLoading;
  final String query;
  final List<InventoryItem> items;
  final int page;
  final int totalPages;
  final String? errorMessage;
  final bool isForbidden; // 403 → "No inventory access"

  const StockLookupState({
    this.isLoading = false,
    this.query = '',
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.errorMessage,
    this.isForbidden = false,
  });

  StockLookupState copyWith({
    bool? isLoading,
    String? query,
    List<InventoryItem>? items,
    int? page,
    int? totalPages,
    String? errorMessage,
    bool? isForbidden,
    bool clearError = false,
  }) {
    return StockLookupState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isForbidden: isForbidden ?? false,
    );
  }
}

final stockLookupProvider =
    NotifierProvider<StockLookupNotifier, StockLookupState>(
      StockLookupNotifier.new,
    );

class StockLookupNotifier extends Notifier<StockLookupState> {
  late final InventoryRepository _repo;

  @override
  StockLookupState build() {
    _repo = ref.read(inventoryRepositoryProvider);
    return const StockLookupState();
  }

  Future<void> search(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      state = const StockLookupState();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      query: query,
      clearError: true,
      isForbidden: false,
    );

    try {
      final result = await _repo.searchItems(query, page: page);
      state = state.copyWith(
        isLoading: false,
        items: page == 1 ? result.items : [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        clearError: true,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final forbidden =
          msg.contains('403') || msg.toLowerCase().contains('forbidden');
      state = state.copyWith(
        isLoading: false,
        isForbidden: forbidden,
        errorMessage: forbidden ? 'No inventory access' : msg,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.page >= state.totalPages) return;
    await search(state.query, page: state.page + 1);
  }

  void clear() {
    state = const StockLookupState();
  }
}

// ───────── Item Lookup (compact typeahead — 6.1b) ─────────

class ItemLookupState {
  final bool isLoading;
  final String query;
  final List<ItemLookupResult> results;
  final String? errorMessage;

  const ItemLookupState({
    this.isLoading = false,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  ItemLookupState copyWith({
    bool? isLoading,
    String? query,
    List<ItemLookupResult>? results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ItemLookupState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final itemLookupProvider =
    NotifierProvider<ItemLookupNotifier, ItemLookupState>(
      ItemLookupNotifier.new,
    );

class ItemLookupNotifier extends Notifier<ItemLookupState> {
  late final InventoryRepository _repo;

  @override
  ItemLookupState build() {
    _repo = ref.read(inventoryRepositoryProvider);
    return const ItemLookupState();
  }

  Future<void> lookup(String query) async {
    if (query.trim().isEmpty) {
      state = const ItemLookupState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query, clearError: true);

    try {
      final results = await _repo.lookupItems(query);
      state = state.copyWith(
        isLoading: false,
        results: results,
        clearError: true,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void clear() {
    state = const ItemLookupState();
  }
}

// ───────── Selected item + its warehouse stock ─────────

final selectedItemIdProvider = StateProvider<int?>((ref) => null);

final itemDetailProvider = FutureProvider.family<InventoryItem, int>((
  ref,
  itemId,
) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getItem(itemId);
});

final warehouseStockForItemProvider =
    FutureProvider.family<List<WarehouseStockRow>, int>((ref, itemId) async {
      final repo = ref.read(inventoryRepositoryProvider);
      return repo.getWarehouseStockForItem(itemId);
    });

// ───────── Low stock (Home badge + list) ─────────

final dashboardStatsProvider = FutureProvider<InventoryDashboardStats>((
  ref,
) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getDashboardStats();
});

final lowStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});

// ───────── Stock report (section 5.3) ─────────

final stockReportProvider = FutureProvider<List<StockReportRow>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getStockReport();
});

final financialReportProvider = FutureProvider.family<FinancialReport, String>((
  ref,
  months,
) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getFinancialReport(months: months);
});
