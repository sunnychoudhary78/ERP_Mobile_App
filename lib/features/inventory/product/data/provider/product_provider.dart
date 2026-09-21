// lib/features/inventory/products/presentation/providers/products_providers.dart
//
// NOTE: adjust the import below to wherever `inventory_providers.dart`
// (with `inventoryRepositoryProvider`) actually lives in your project —
// it's assumed to sit at features/inventory/shared/providers/.

import 'package:erp_app/features/inventory/product/data/model/cost_history_model.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────── Status tabs (client-side — /items has no status query param) ─────────

enum ProductStatusFilter { all, active, pending, rejected, inactive }

extension ProductStatusFilterX on ProductStatusFilter {
  String get label {
    switch (this) {
      case ProductStatusFilter.all:
        return 'All';
      case ProductStatusFilter.active:
        return 'Active';
      case ProductStatusFilter.pending:
        return 'Pending';
      case ProductStatusFilter.rejected:
        return 'Rejected';
      case ProductStatusFilter.inactive:
        return 'Inactive';
    }
  }

  /// Backend status string this tab matches against, e.g. "ACTIVE".
  String get _apiValue => name.toUpperCase();

  bool matches(String? status) {
    if (this == ProductStatusFilter.all) return true;
    return (status ?? '').toUpperCase() == _apiValue;
  }
}

// ───────── List state ─────────

class ProductsListState {
  final bool isLoading;
  final bool isLoadingMore;
  final String query;
  final ProductStatusFilter statusFilter;
  final List<InventoryItem> items;
  final int page;
  final int totalPages;
  final int total;
  final String? errorMessage;
  final bool isForbidden;

  const ProductsListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.query = '',
    this.statusFilter = ProductStatusFilter.all,
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.errorMessage,
    this.isForbidden = false,
  });

  /// Items after applying the active status tab. Note: this only filters
  /// what's currently loaded — counts/tabs are not exact across pages you
  /// haven't fetched yet (the backend doesn't support a status query param).
  List<InventoryItem> get filteredItems =>
      items.where((i) => statusFilter.matches(i.status)).toList();

  Map<ProductStatusFilter, int> get statusCounts {
    return {
      for (final f in ProductStatusFilter.values)
        f: f == ProductStatusFilter.all
            ? items.length
            : items.where((i) => f.matches(i.status)).length,
    };
  }

  bool get hasMore => page < totalPages;

  ProductsListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? query,
    ProductStatusFilter? statusFilter,
    List<InventoryItem>? items,
    int? page,
    int? totalPages,
    int? total,
    String? errorMessage,
    bool? isForbidden,
    bool clearError = false,
  }) {
    return ProductsListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      statusFilter: statusFilter ?? this.statusFilter,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

final productsListProvider =
    NotifierProvider<ProductsListNotifier, ProductsListState>(
  ProductsListNotifier.new,
);

class ProductsListNotifier extends Notifier<ProductsListState> {
  late final dynamic _repo; // InventoryRepository

  @override
  ProductsListState build() {
    _repo = ref.read(inventoryRepositoryProvider);
    Future.microtask(() => load(page: 1));
    return const ProductsListState();
  }

  Future<void> load({int page = 1}) async {
    state = state.copyWith(
      isLoading: page == 1,
      isLoadingMore: page != 1,
      clearError: true,
    );

    try {
      final result = await _repo.getItems(
        search: state.query,
        page: page,
        limit: 25,
      );
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        items: page == 1 ? result.items : [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
        clearError: true,
        isForbidden: false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final forbidden =
          msg.contains('403') || msg.toLowerCase().contains('forbidden');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isForbidden: forbidden,
        errorMessage: forbidden ? 'No inventory access' : msg,
      );
    }
  }

  Future<void> refresh() => load(page: 1);

  Future<void> loadMore() {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return Future.value();
    }
    return load(page: state.page + 1);
  }

  void search(String query) {
    state = state.copyWith(query: query);
    load(page: 1);
  }

  void setStatusFilter(ProductStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }
}

// ───────── Categories (form dropdown) ─────────

final productCategoriesProvider =
    FutureProvider<List<ProductCategoryLite>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getProductCategories();
});

// ───────── Cost history (product detail screen) ─────────

final itemCostHistoryProvider =
    FutureProvider.family<List<CostHistoryEntry>, int>((ref, itemId) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getItemCostHistory(itemId);
});