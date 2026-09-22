import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/repository/inventory_repository.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BomState {
  final bool isLoading;
  final List<BillOfMaterials> boms;
  final String query;
  final String? errorMessage;

  const BomState({
    this.isLoading = false,
    this.boms = const [],
    this.query = '',
    this.errorMessage,
  });

  List<BillOfMaterials> get filteredBoms {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return boms;
    return boms.where((bom) {
      final itemName = bom.item?.name.toLowerCase() ?? '';
      return itemName.contains(value) ||
          (bom.description ?? '').toLowerCase().contains(value);
    }).toList();
  }

  BomState copyWith({
    bool? isLoading,
    List<BillOfMaterials>? boms,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BomState(
      isLoading: isLoading ?? this.isLoading,
      boms: boms ?? this.boms,
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final bomProvider = NotifierProvider<BomNotifier, BomState>(BomNotifier.new);

final bomItemsProvider = FutureProvider<List<ItemLookupResult>>((ref) {
  return ref.read(inventoryRepositoryProvider).lookupBomItems();
});

class BomNotifier extends Notifier<BomState> {
  late final InventoryRepository _repo;

  @override
  BomState build() {
    _repo = ref.read(inventoryRepositoryProvider);
    Future.microtask(load);
    return const BomState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final boms = await _repo.getBoms();
      state = state.copyWith(isLoading: false, boms: boms, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void search(String query) => state = state.copyWith(query: query);

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final result = await _repo.createBom(body);
    await load();
    return result;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final result = await _repo.updateBom(id, body);
    await load();
    return result;
  }

  Future<Map<String, dynamic>> delete(int id) async {
    final result = await _repo.deleteBom(id);
    await load();
    return result;
  }
}
