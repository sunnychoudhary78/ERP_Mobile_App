import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryProductsScreen extends ConsumerStatefulWidget {
  const InventoryProductsScreen({super.key});

  @override
  ConsumerState<InventoryProductsScreen> createState() =>
      _InventoryProductsScreenState();
}

class _InventoryProductsScreenState
    extends ConsumerState<InventoryProductsScreen> {
  final _searchController = TextEditingController();
  late Future<List<_InventoryProduct>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_InventoryProduct>> _fetch() async {
    final repository = ref.read(inventoryRepositoryProvider);
    final catalogItemsFuture = repository.getAllItems();
    final lotsFuture = repository.getInventoryLots();
    final catalogItems = await catalogItemsFuture;
    final rows = await lotsFuture;
    final catalogById = {
      for (final item in catalogItems) item.id.toString(): item,
    };
    final products = <String, _InventoryProduct>{};
    for (final item in catalogItems) {
      products[item.id.toString()] = _InventoryProduct(item: item);
    }
    for (final raw in rows) {
      final lot = Map<String, dynamic>.from(raw as Map);
      final nestedItem = lot['item'] is Map
          ? Map<String, dynamic>.from(lot['item'] as Map)
          : <String, dynamic>{};
      final itemId = nestedItem['id'] ?? lot['itemId'];
      final itemIdValue = int.tryParse('$itemId');
      final fallbackKey =
          '${nestedItem['sku'] ?? lot['sku'] ?? ''}:${nestedItem['name'] ?? lot['itemName'] ?? ''}';
      final key = itemId?.toString() ?? fallbackKey;
      final product = products.putIfAbsent(key, () {
        return _InventoryProduct(
          item: itemId == null ? null : catalogById[key],
          fallback: nestedItem,
          lot: lot,
          productId: itemIdValue,
        );
      });
      product.lots.add(lot);
    }
    return products.values
        .where((product) => product.onHand > 0 || product.lots.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _reload() => setState(() => _load = _fetch());

  Future<void> _allocateStock(_InventoryProduct product) async {
    final itemId = product.productId;
    if (itemId == null) {
      _showMessage('Could not identify this product for allocation.');
      return;
    }

    final repository = ref.read(inventoryRepositoryProvider);
    final qtyController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final warehouses = await repository.getWarehouses();
      if (!mounted) return;
      if (warehouses.isEmpty) {
        _showMessage('No warehouses are available.');
        return;
      }
      int? warehouseId;
      var destination = 'processed';
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Allocate ${product.name}'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: warehouseId,
                      decoration: const InputDecoration(labelText: 'Warehouse'),
                      items: [
                        for (final warehouse in warehouses)
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => warehouseId = value),
                      validator: (value) =>
                          value == null ? 'Select a warehouse' : null,
                    ),
                    TextFormField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) =>
                          (num.tryParse(value ?? '') ?? 0) <= 0
                          ? 'Enter a positive quantity'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: destination,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'processed',
                          child: Text('Processed stock'),
                        ),
                        DropdownMenuItem(
                          value: 'sellable',
                          child: Text('Sellable stock'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => destination = value ?? destination,
                      ),
                    ),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Reason / note',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'A note is required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Allocate'),
              ),
            ],
          ),
        ),
      );
      if (save != true || warehouseId == null) return;

      await repository.allocateDirectStock({
        'itemId': itemId,
        'warehouseId': warehouseId,
        'quantity': num.parse(qtyController.text),
        'destination': destination,
        'noteMessage': noteController.text.trim(),
      });
      if (!mounted) return;
      _showMessage('Stock allocated');
      _reload();
    } catch (error) {
      if (mounted) _showMessage('Allocation failed: $error');
    } finally {
      qtyController.dispose();
      noteController.dispose();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canAllocate =
        auth.can(AppPermissions.inventoryManage) ||
        auth.can(AppPermissions.lotProcessingProcess);
    final query = _searchController.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory products'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_InventoryProduct>>(
              future: _load,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageView(
                    message:
                        'Could not load inventory: ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                    onRetry: _reload,
                  );
                }

                final allProducts = snapshot.data ?? const [];
                final filtered = allProducts.where((product) {
                  return product.name.toLowerCase().contains(query) ||
                      product.sku.toLowerCase().contains(query) ||
                      product.productCode.toLowerCase().contains(query);
                }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      allProducts.isEmpty
                          ? 'No inventory products found'
                          : 'No matching products',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                        child: Text(
                          '${filtered.length} ${filtered.length == 1 ? 'product' : 'products'}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      for (final product in filtered)
                        _ProductCard(
                          product: product,
                          canAllocate: canAllocate,
                          onAllocate: () => _allocateStock(product),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryProduct {
  _InventoryProduct({
    this.item,
    this.fallback = const {},
    this.lot,
    int? productId,
  }) : _productId = productId;

  final InventoryItem? item;
  final Map<String, dynamic> fallback;
  final Map<String, dynamic>? lot;
  final int? _productId;
  final List<Map<String, dynamic>> lots = [];

  int? get productId => _productId ?? item?.id;

  String get name =>
      item?.name ??
      (fallback['name'] ?? lot?['itemName'] ?? 'Unnamed product').toString();
  String get sku => item?.sku ?? (fallback['sku'] ?? '').toString();
  String get productCode => item?.productCode ?? '';
  String get unit => item?.unit ?? (fallback['unit'] ?? '').toString();
  num get onHand => item?.currentStock ?? _sum('availableQty');
  num get rawQty => _sum('rawQty');
  num get processingQty => _sum('processingQty');
  int get lotCount => lots.length;

  num _sum(String field) =>
      lots.fold<num>(0, (sum, lot) => sum + (_number(lot[field]) ?? 0));
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.canAllocate,
    required this.onAllocate,
  });

  final _InventoryProduct product;
  final bool canAllocate;
  final VoidCallback onAllocate;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _showLots = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _showLots = !_showLots),
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.inventory_2_outlined, color: scheme.primary),
            ),
            title: Text(
              widget.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                if (widget.product.sku.isNotEmpty) 'SKU: ${widget.product.sku}',
                if (widget.product.productCode.isNotEmpty)
                  'Code: ${widget.product.productCode}',
                '${widget.product.lotCount} ${widget.product.lotCount == 1 ? 'lot' : 'lots'}',
                'Raw: ${widget.product.rawQty}',
                'Processing: ${widget.product.processingQty}',
              ].join('  •  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.product.onHand} ${widget.product.unit}'.trim(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('On hand', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.canAllocate)
                  OutlinedButton.icon(
                    onPressed: widget.onAllocate,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Allocate'),
                  ),
                if (widget.canAllocate && widget.product.lotCount > 0)
                  const SizedBox(width: 8),
                if (widget.product.lotCount > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showLots = !_showLots),
                    icon: Icon(
                      _showLots ? Icons.expand_less : Icons.layers_outlined,
                    ),
                    label: Text(
                      _showLots
                          ? 'Hide lots'
                          : 'View lots (${widget.product.lotCount})',
                    ),
                  ),
              ],
            ),
          ),
          if (_showLots)
            if (widget.product.lots.isEmpty)
              const ListTile(
                dense: true,
                title: Text('No lots for this product'),
              )
            else
              for (final lot in widget.product.lots)
                ListTile(
                  dense: true,
                  title: Text(
                    (lot['lotNumber'] ??
                            'Lot #${lot['id'] ?? lot['lotId'] ?? ''}')
                        .toString(),
                  ),
                  subtitle: Text('Status: ${lot['status'] ?? '—'}'),
                  trailing: Text(
                    '${lot['availableQty'] ?? 0} ${widget.product.unit}'.trim(),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

num? _number(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}
