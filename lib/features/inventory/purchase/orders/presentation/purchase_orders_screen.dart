import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_order_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PurchaseOrderQuery get _query => PurchaseOrderQuery(search: _search);

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(purchaseOrdersProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            tooltip: 'Import JSON rows',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _importRows,
          ),
          IconButton(
            tooltip: 'Create purchase order',
            icon: const Icon(Icons.add),
            onPressed: _createOrder,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                labelText: 'Search PO number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(purchaseOrdersProvider(_query)),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(purchaseOrdersProvider(_query));
                  await ref.read(purchaseOrdersProvider(_query).future);
                },
                child: page.orders.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No purchase orders found')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: page.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _PurchaseOrderCard(order: page.orders[index]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder() async {
    final result = await showDialog<_CreateOrderResult>(
      context: context,
      builder: (_) => const _CreateOrderDialog(),
    );
    if (result == null || !mounted) return;

    try {
      final response = await ref
          .read(inventoryRepositoryProvider)
          .createPurchaseOrder(result.body);
      ref.invalidate(purchaseOrdersProvider(_query));
      _message(
        response['approvalId'] == null
            ? 'Purchase order created'
            : 'Purchase order sent for approval',
      );
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _importRows() async {
    final rows = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => const _ImportRowsDialog(),
    );
    if (rows == null || rows.isEmpty || !mounted) return;

    try {
      final response = await ref
          .read(inventoryRepositoryProvider)
          .importPurchaseOrders(rows);
      ref.invalidate(purchaseOrdersProvider(_query));
      _message(
        response['approvalId'] == null
            ? 'Purchase orders imported'
            : 'Purchase orders sent for approval',
      );
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// One purchase-order row inside the import form: holds its own controllers
/// so each row can be added/removed independently without touching others.
class _ImportRowControllers {
  final vendor = TextEditingController();
  final warehouse = TextEditingController();
  final item = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  final unit = TextEditingController(text: 'Nos');

  void dispose() {
    for (final c in [vendor, warehouse, item, quantity, price, unit]) {
      c.dispose();
    }
  }
}

class _ImportRowsDialog extends StatefulWidget {
  const _ImportRowsDialog();

  @override
  State<_ImportRowsDialog> createState() => _ImportRowsDialogState();
}

class _ImportRowsDialogState extends State<_ImportRowsDialog> {
  final List<_ImportRowControllers> _rows = [_ImportRowControllers()];
  String? _error;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    if (_rows.length >= 500) return;
    setState(() => _rows.add(_ImportRowControllers()));
  }

  void _removeRow(int index) {
    if (_rows.length == 1) return; // always keep at least one row
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _submit() {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final vendorId = int.tryParse(row.vendor.text);
      final warehouseId = int.tryParse(row.warehouse.text);
      final itemId = int.tryParse(row.item.text);
      final quantity = num.tryParse(row.quantity.text);
      final price = num.tryParse(row.price.text);
      if (vendorId == null ||
          warehouseId == null ||
          itemId == null ||
          quantity == null ||
          price == null) {
        setState(() => _error = 'Row ${i + 1}: enter valid IDs, quantity, and price');
        return;
      }
      result.add({
        'vendorId': vendorId,
        'warehouseId': warehouseId,
        'items': [
          {
            'itemId': itemId,
            'orderedQty': quantity,
            'price': price,
            'unitCategory': null,
            'unitValue': null,
            'measureUnit': row.unit.text.trim(),
            'specifications': <String, dynamic>{},
            'length': null,
            'width': null,
            'thickness': null,
            'weight': null,
          },
        ],
      });
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import purchase orders'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add one entry per purchase order (up to 500).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _rows.length; i++)
                _ImportRowCard(
                  index: i,
                  row: _rows[i],
                  canRemove: _rows.length > 1,
                  onRemove: () => _removeRow(i),
                ),
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Add another purchase order'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Import')),
      ],
    );
  }
}

class _ImportRowCard extends StatelessWidget {
  final int index;
  final _ImportRowControllers row;
  final bool canRemove;
  final VoidCallback onRemove;

  const _ImportRowCard({
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PO ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove this row',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onRemove,
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _numField(row.vendor, 'Vendor ID')),
                const SizedBox(width: 8),
                Expanded(child: _numField(row.warehouse, 'Warehouse ID')),
              ],
            ),
            const SizedBox(height: 8),
            _numField(row.item, 'Item ID'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _numField(row.quantity, 'Qty')),
                const SizedBox(width: 8),
                Expanded(child: _numField(row.price, 'Price')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;

  const _PurchaseOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          order.poNumber.isEmpty ? 'PO #${order.id}' : order.poNumber,
        ),
        subtitle: Text(
          '${order.vendorName.isEmpty ? 'Vendor unavailable' : order.vendorName}\n'
          '${order.warehouseName.isEmpty ? 'Warehouse unavailable' : order.warehouseName}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(order.status, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text('₹${order.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _CreateOrderResult {
  final Map<String, dynamic> body;

  const _CreateOrderResult(this.body);
}

class _CreateOrderDialog extends StatefulWidget {
  const _CreateOrderDialog();

  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  final _vendorController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'Nos');

  @override
  void dispose() {
    for (final controller in [
      _vendorController,
      _warehouseController,
      _itemController,
      _quantityController,
      _priceController,
      _unitController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create purchase order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _numberField(_vendorController, 'Vendor ID'),
            _numberField(_warehouseController, 'Warehouse ID'),
            _numberField(_itemController, 'Item ID'),
            _numberField(_quantityController, 'Ordered quantity'),
            _numberField(_priceController, 'Price'),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Measure unit'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  void _submit() {
    final vendorId = int.tryParse(_vendorController.text);
    final warehouseId = int.tryParse(_warehouseController.text);
    final itemId = int.tryParse(_itemController.text);
    final quantity = num.tryParse(_quantityController.text);
    final price = num.tryParse(_priceController.text);
    if (vendorId == null ||
        warehouseId == null ||
        itemId == null ||
        quantity == null ||
        price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid IDs, quantity, and price')),
      );
      return;
    }
    Navigator.pop(
      context,
      _CreateOrderResult({
        'vendorId': vendorId,
        'warehouseId': warehouseId,
        'items': [
          {
            'itemId': itemId,
            'orderedQty': quantity,
            'price': price,
            'unitCategory': null,
            'unitValue': null,
            'measureUnit': _unitController.text.trim(),
            'specifications': <String, dynamic>{},
            'length': null,
            'width': null,
            'thickness': null,
            'weight': null,
          },
        ],
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}