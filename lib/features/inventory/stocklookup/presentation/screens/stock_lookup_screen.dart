import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_stock_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class StockLookupScreen extends ConsumerStatefulWidget {
  const StockLookupScreen({super.key});

  @override
  ConsumerState<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends ConsumerState<StockLookupScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(stockLookupProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      ref.read(stockLookupProvider.notifier).search(value);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockLookupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Lookup')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search by name / SKU / product code...',
                border: const OutlineInputBorder(),
                suffixIcon: state.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(stockLookupProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                ref.read(stockLookupProvider.notifier).search(value);
              },
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(StockLookupState state) {
    if (state.query.isEmpty) {
      return const Center(child: Text('Type to search items'));
    }

    if (state.isForbidden) {
      return const Center(child: Text('No inventory access'));
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.items.length + (state.isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = state.items[index];
        return _ItemTile(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ItemDetailScreen(item: item)),
            );
          },
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(item.name),
      subtitle: Text(
        'SKU: ${item.sku}'
        '${item.productCode != null ? ' | Code: ${item.productCode}' : ''}'
        '${item.brandName != null ? ' | Brand: ${item.brandName}' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${item.currentStock} ${item.unit ?? ''}'),
          if (item.isLowStock)
            const Text(
              'LOW STOCK',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _ItemDetailScreen extends ConsumerWidget {
  final InventoryItem item;

  const _ItemDetailScreen({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(warehouseStockForItemProvider(item.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(warehouseStockForItemProvider(item.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ItemInfoCard(item: item),
            const SizedBox(height: 24),
            const Text(
              'Warehouse Stock',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            stockAsync.when(
              data: (rows) => _WarehouseStockTable(rows: rows),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading warehouse stock: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemInfoCard extends StatelessWidget {
  final InventoryItem item;

  const _ItemInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _row('SKU', item.sku),
            _row('Product Code', item.productCode ?? '-'),
            _row('Brand', item.brandName ?? '-'),
            _row('Unit', item.unit ?? '-'),
            _row('Current Stock (total)', '${item.currentStock}'),
            _row('Reorder Level', item.reorderLevel?.toString() ?? '-'),
            _row('Status', item.status ?? '-'),
            _row('HSN/SAC', item.hsnSac ?? '-'),
            _row('Selling Price', item.sellingPrice?.toString() ?? '-'),
            _row('Category', item.categoryName ?? '-'),
            if (item.isLowStock)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'LOW STOCK',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _WarehouseStockTable extends StatelessWidget {
  final List<WarehouseStockRow> rows;

  const _WarehouseStockTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No warehouse stock found for this item');
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF0F0F0)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Warehouse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...rows.map(
          (r) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(r.warehouseName),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${r.quantity}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
