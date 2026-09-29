import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_order_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:erp_app/features/inventory/shared/widget/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1234567.5 -> ₹12,34,567.50 (Indian digit grouping)
String _formatInr(num value) {
  final parts = value.toStringAsFixed(2).split('.');
  var whole = parts[0];
  final negative = whole.startsWith('-');
  if (negative) whole = whole.substring(1);
  if (whole.length > 3) {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    whole = '${groups.join(',')},$last3';
  }
  return '${negative ? '-' : ''}₹$whole.${parts[1]}';
}

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        centerTitle: true,
        title: const Text(
          'Purchase Orders',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Import purchase orders',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _importRows,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: _createOrder,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                // Clearing the box by hand also resets the results.
                if (value.trim().isEmpty && _search.isNotEmpty) {
                  setState(() => _search = '');
                } else {
                  setState(() {});
                }
              },
              onSubmitted: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by PO number',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(Icons.clear, color: AppColors.muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.4),
                ),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _search.isEmpty
                                  ? 'No purchase orders yet'
                                  : 'No purchase orders found',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: page.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final repo = ref.read(inventoryRepositoryProvider);
    late final List<dynamic> vendors;
    late final List<dynamic> warehouses;
    late final List<dynamic> items;
    try {
      final results = await Future.wait<dynamic>([
        repo.lookupVendors(limit: 500),
        repo.lookupWarehouses(limit: 500),
        repo.getItems(limit: 500),
      ]);
      vendors = results[0] as List<dynamic>;
      warehouses = results[1] as List<dynamic>;
      items = (results[2] as dynamic).items as List<dynamic>;
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    final result = await showAppSheet<_CreateOrderResult>(
      context,
      builder: (_) => _CreateOrderSheet(
        vendors: vendors,
        warehouses: warehouses,
        items: items,
      ),
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
    final rows = await showAppSheet<List<Map<String, dynamic>>>(
      context,
      builder: (_) => const _ImportRowsSheet(),
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

// ─────────────────────────────────────────────────────────────────────────────
// List card
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;

  const _PurchaseOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = appStatusColor(order.status);
    final vendor = order.vendorName.isEmpty ? null : order.vendorName;
    final warehouse = order.warehouseName.isEmpty ? null : order.warehouseName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor.withValues(alpha: 0.7)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.poNumber.isEmpty
                                  ? 'PO #${order.id}'
                                  : order.poNumber,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppStatusPill(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        text: vendor ?? 'Vendor unavailable',
                        muted: vendor == null,
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.warehouse_outlined,
                        text: warehouse ?? 'Warehouse unavailable',
                        muted: warehouse == null,
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Total amount',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatInr(order.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoRow({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              color: muted ? AppColors.muted : AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create order sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CreateOrderResult {
  final Map<String, dynamic> body;

  const _CreateOrderResult(this.body);
}

class _CreateOrderSheet extends StatefulWidget {
  final List<dynamic> vendors;
  final List<dynamic> warehouses;
  final List<dynamic> items;

  const _CreateOrderSheet({
    required this.vendors,
    required this.warehouses,
    required this.items,
  });

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'Nos');

  int? _vendorId;
  int? _warehouseId;
  int? _itemId;
  bool _submitted = false;

  late final List<AppPickerOption<int>> _vendorOptions;
  late final List<AppPickerOption<int>> _warehouseOptions;
  late final List<AppPickerOption<int>> _itemOptions;

  @override
  void initState() {
    super.initState();
    _vendorOptions = [
      for (final v in widget.vendors)
        AppPickerOption<int>(_lookupId(v), _lookupName(v)),
    ];
    _warehouseOptions = [
      for (final w in widget.warehouses)
        AppPickerOption<int>(_lookupId(w), _lookupName(w)),
    ];
    _itemOptions = [
      for (final i in widget.items)
        AppPickerOption<int>(i.id as int, '${i.name}'),
    ];
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  int _lookupId(dynamic row) {
    final raw = row is Map ? row['id'] : null;
    return raw is int ? raw : int.tryParse('$raw') ?? 0;
  }

  String _lookupName(dynamic row) {
    if (row is! Map) return 'Unknown';
    return '${row['name'] ?? row['warehouseName'] ?? 'Unknown'}';
  }

  num get _lineTotal {
    final qty = num.tryParse(_quantityController.text) ?? 0;
    final price = num.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  String? _numberValidator(String? value) =>
      num.tryParse(value?.trim() ?? '') == null ? 'Enter a number' : null;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: 'Create Purchase Order',
      subtitle: 'Choose the vendor, warehouse and product to order.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Line total',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatInr(_lineTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Create Order'),
                ),
              ),
            ],
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPickerField<int>(
              label: 'Vendor',
              required: true,
              value: _vendorId,
              options: _vendorOptions,
              errorText:
                  _submitted && _vendorId == null ? 'Select a vendor' : null,
              onChanged: (v) => setState(() => _vendorId = v),
            ),
            const SizedBox(height: 12),
            AppPickerField<int>(
              label: 'Warehouse',
              required: true,
              value: _warehouseId,
              options: _warehouseOptions,
              errorText: _submitted && _warehouseId == null
                  ? 'Select a warehouse'
                  : null,
              onChanged: (v) => setState(() => _warehouseId = v),
            ),
            const SizedBox(height: 12),
            AppPickerField<int>(
              label: 'Product',
              required: true,
              value: _itemId,
              options: _itemOptions,
              errorText:
                  _submitted && _itemId == null ? 'Select a product' : null,
              onChanged: (v) => setState(() => _itemId = v),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    onChanged: (_) => setState(() {}),
                    validator: _numberValidator,
                    decoration:
                        appFieldDecoration('Ordered quantity', required: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    decoration: appFieldDecoration('Measure unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              scrollPadding: const EdgeInsets.only(bottom: 160),
              onChanged: (_) => setState(() {}),
              validator: _numberValidator,
              decoration: appFieldDecoration(
                'Price per unit',
                required: true,
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    final vendorId = _vendorId;
    final warehouseId = _warehouseId;
    final itemId = _itemId;
    final quantity = num.tryParse(_quantityController.text);
    final price = num.tryParse(_priceController.text);
    if (!formOk ||
        vendorId == null ||
        warehouseId == null ||
        itemId == null ||
        quantity == null ||
        price == null) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Import sheet
// ─────────────────────────────────────────────────────────────────────────────

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

class _ImportRowsSheet extends StatefulWidget {
  const _ImportRowsSheet();

  @override
  State<_ImportRowsSheet> createState() => _ImportRowsSheetState();
}

class _ImportRowsSheetState extends State<_ImportRowsSheet> {
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
        setState(
          () => _error = 'PO ${i + 1}: enter valid IDs, quantity, and price',
        );
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
    return AppSheetFrame(
      title: 'Import Purchase Orders',
      subtitle: 'Add one entry per purchase order (up to 500).',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _rows.length == 1
                        ? 'Import 1 order'
                        : 'Import ${_rows.length} orders',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows.length; i++)
            _ImportRowCard(
              index: i,
              row: _rows[i],
              canRemove: _rows.length > 1,
              onRemove: () => _removeRow(i),
            ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('Add another purchase order'),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'PO ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'serif',
                  ),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove this row',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.danger,
                    ),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _idField(row.vendor, 'Vendor ID')),
              const SizedBox(width: 10),
              Expanded(child: _idField(row.warehouse, 'Warehouse ID')),
            ],
          ),
          const SizedBox(height: 10),
          _idField(row.item, 'Item ID'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _numField(row.quantity, 'Qty')),
              const SizedBox(width: 10),
              Expanded(child: _numField(row.price, 'Price')),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: row.unit,
                  scrollPadding: const EdgeInsets.only(bottom: 160),
                  decoration: appFieldDecoration('Unit', dense: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _idField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      scrollPadding: const EdgeInsets.only(bottom: 160),
      decoration: appFieldDecoration(label, dense: true),
    );
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      scrollPadding: const EdgeInsets.only(bottom: 160),
      decoration: appFieldDecoration(label, dense: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 38, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}