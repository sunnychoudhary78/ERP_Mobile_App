import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_order_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
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
                        itemBuilder: (_, index) => _PurchaseOrderCard(
                          order: page.orders[index],
                          onTap: () => _showOrderDetails(page.orders[index]),
                        ),
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
    late final List<InventoryItem> items;
    try {
      final results = await Future.wait<dynamic>([
        repo.lookupVendors(limit: 500),
        repo.lookupWarehouses(limit: 500),
        repo.getItems(limit: 500),
      ]);
      vendors = results[0] as List<dynamic>;
      warehouses = results[1] as List<dynamic>;
      items = (results[2] as PagedItems).items;
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

  Future<void> _showOrderDetails(PurchaseOrder order) {
    return showAppSheet<void>(
      context,
      builder: (_) => _PurchaseOrderDetailsSheet(order: order),
    );
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
  final VoidCallback onTap;

  const _PurchaseOrderCard({required this.order, required this.onTap});

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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: statusColor.withValues(alpha: 0.7),
                  ),
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
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'View details  ›',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseOrderDetailsSheet extends StatelessWidget {
  final PurchaseOrder order;

  const _PurchaseOrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final vendor = _nestedMap(order['vendor']);
    final warehouse = _nestedMap(order['warehouse']);
    final items = order.items;
    final createdAt = order.createdAt;
    final updatedAt = order.updatedAt;
    final vendorName = order.vendorName.isEmpty
        ? _detailText(vendor, ['name'])
        : order.vendorName;
    final warehouseName = order.warehouseName.isEmpty
        ? _detailText(warehouse, ['name'])
        : order.warehouseName;

    return AppSheetFrame(
      title: order.poNumber.isEmpty ? 'PO #${order.id}' : order.poNumber,
      subtitle: '${items.length} ${items.length == 1 ? 'item' : 'items'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              AppStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          _OrderDetailsSection(
            title: 'Order information',
            rows: [
              _OrderDetailValue('Purchase order ID', '${order.id}'),
              _OrderDetailValue('Created', _displayDate(createdAt)),
              if (updatedAt != null && updatedAt != createdAt)
                _OrderDetailValue('Last updated', _displayDate(updatedAt)),
              _OrderDetailValue('Total amount', _formatInr(order.totalAmount)),
            ],
          ),
          const SizedBox(height: 16),
          _OrderDetailsSection(
            title: 'Vendor',
            rows: [
              _OrderDetailValue(
                'Name',
                vendorName.isEmpty ? 'Unavailable' : vendorName,
              ),
              if (_detailText(vendor, ['email']).isNotEmpty)
                _OrderDetailValue('Email', _detailText(vendor, ['email'])),
              if (_detailText(vendor, ['phone', 'mobile']).isNotEmpty)
                _OrderDetailValue(
                  'Phone',
                  _detailText(vendor, ['phone', 'mobile']),
                ),
              if (order.vendorId != 0)
                _OrderDetailValue('Vendor ID', '${order.vendorId}'),
            ],
          ),
          const SizedBox(height: 16),
          _OrderDetailsSection(
            title: 'Delivery warehouse',
            rows: [
              _OrderDetailValue(
                'Name',
                warehouseName.isEmpty ? 'Unavailable' : warehouseName,
              ),
              if (_detailText(warehouse, ['address']).isNotEmpty)
                _OrderDetailValue(
                  'Address',
                  _detailText(warehouse, ['address']),
                ),
              if (_detailText(warehouse, ['status']).isNotEmpty)
                _OrderDetailValue(
                  'Warehouse status',
                  _detailText(warehouse, ['status']),
                ),
              if (order.warehouseId != 0)
                _OrderDetailValue('Warehouse ID', '${order.warehouseId}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Items (${items.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'No item details were returned for this purchase order.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (var index = 0; index < items.length; index++)
              _PurchaseOrderItemDetails(index: index + 1, item: items[index]),
        ],
      ),
    );
  }
}

class _PurchaseOrderItemDetails extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;

  const _PurchaseOrderItemDetails({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final nestedItem = _nestedMap(item['item']);
    final name = _detailText(item, ['name', 'itemName', 'item_name']).isNotEmpty
        ? _detailText(item, ['name', 'itemName', 'item_name'])
        : _detailText(nestedItem, ['name']).isNotEmpty
        ? _detailText(nestedItem, ['name'])
        : 'Item ${_detailText(item, ['itemId', 'item_id']).isEmpty ? '?' : _detailText(item, ['itemId', 'item_id'])}';
    final sku = _detailText(item, ['sku', 'itemSku', 'item_sku']).isNotEmpty
        ? _detailText(item, ['sku', 'itemSku', 'item_sku'])
        : _detailText(nestedItem, ['sku', 'productCode', 'product_code']);
    final quantity = _detailNumber(item, [
      'orderedQty',
      'ordered_qty',
      'quantity',
      'qty',
    ]);
    final price = _detailNumber(item, ['price', 'unitPrice', 'unit_price']);
    final lineTotal = _detailNumber(item, [
      'lineTotal',
      'line_total',
      'totalAmount',
      'total_amount',
    ]);
    final amount =
        lineTotal ??
        (quantity != null && price != null ? quantity * price : null);
    final unitCategory = _detailText(item, ['unitCategory', 'unit_category']);
    final unitValue = _detailText(item, ['unitValue', 'unit_value']);
    final measureUnit = _detailText(item, ['measureUnit', 'measure_unit']);
    final received = _detailText(item, ['receivedQty', 'received_qty']);
    final rejected = _detailText(item, ['rejectedQty', 'rejected_qty']);
    final details = <_OrderDetailValue>[
      _OrderDetailValue(
        'Ordered quantity',
        _quantityText(quantity, measureUnit),
      ),
      if (price != null) _OrderDetailValue('Unit price', _formatInr(price)),
      if (amount != null) _OrderDetailValue('Line total', _formatInr(amount)),
      if (unitCategory.isNotEmpty)
        _OrderDetailValue('Unit category', unitCategory),
      if (unitValue.isNotEmpty)
        _OrderDetailValue(
          'Unit value',
          '$unitValue${measureUnit.isEmpty ? '' : ' $measureUnit'}',
        ),
      if (received.isNotEmpty) _OrderDetailValue('Received quantity', received),
      if (rejected.isNotEmpty) _OrderDetailValue('Rejected quantity', rejected),
    ];
    final specifications = _specificationEntries(item);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$index. $name',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (sku.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'SKU: $sku',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 8),
          for (final detail in details)
            _OrderDetailRow(label: detail.label, value: detail.value),
          if (specifications.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Specifications',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            for (final detail in specifications)
              _OrderDetailRow(label: detail.label, value: detail.value),
          ],
        ],
      ),
    );
  }
}

class _OrderDetailsSection extends StatelessWidget {
  final String title;
  final List<_OrderDetailValue> rows;

  const _OrderDetailsSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final row in rows)
            _OrderDetailRow(label: row.label, value: row.value),
        ],
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _OrderDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailValue {
  final String label;
  final String value;

  const _OrderDetailValue(this.label, this.value);
}

Map<String, dynamic> _nestedMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String _detailText(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}

double? _detailNumber(Map<String, dynamic> data, List<String> keys) {
  final value = _detailText(data, keys);
  return value.isEmpty ? null : double.tryParse(value);
}

String _displayDate(String? value) {
  if (value == null || value.trim().isEmpty) return 'Unavailable';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.replaceFirst('T', ' ').replaceFirst('Z', '');
  final date = parsed.toLocal();
  final datePart =
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  final timePart =
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
  return '$datePart $timePart';
}

String _quantityText(double? quantity, String unit) {
  if (quantity == null) return 'Unavailable';
  final formatted = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
  return '$formatted${unit.isEmpty ? '' : ' $unit'}';
}

List<_OrderDetailValue> _specificationEntries(Map<String, dynamic> item) {
  final entries = <_OrderDetailValue>[];
  final specifications = item['specifications'] ?? item['productDimensions'];
  if (specifications is Map) {
    for (final entry in specifications.entries) {
      final value = entry.value;
      if (value != null && value.toString().trim().isNotEmpty) {
        entries.add(
          _OrderDetailValue(appPrettyLabel(entry.key.toString()), '$value'),
        );
      }
    }
  } else if (specifications is List) {
    for (final dimension in specifications.whereType<Map>()) {
      final label = _detailText(Map<String, dynamic>.from(dimension), [
        'label',
        'name',
      ]);
      final value = _detailText(Map<String, dynamic>.from(dimension), [
        'value',
      ]);
      final unit = _detailText(Map<String, dynamic>.from(dimension), ['unit']);
      if (label.isNotEmpty && value.isNotEmpty) {
        entries.add(
          _OrderDetailValue(label, '$value${unit.isEmpty ? '' : ' $unit'}'),
        );
      }
    }
  }
  for (final key in ['length', 'width', 'thickness', 'weight']) {
    final value = _detailText(item, [key]);
    if (value.isNotEmpty &&
        !entries.any(
          (entry) => entry.label.toLowerCase() == key.toLowerCase(),
        )) {
      entries.add(_OrderDetailValue(appPrettyLabel(key), value));
    }
  }
  return entries;
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
  final List<InventoryItem> items;

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
  final List<_PurchaseOrderLineDraft> _lines = [_PurchaseOrderLineDraft()];

  int? _vendorId;
  int? _warehouseId;
  bool _submitted = false;

  late final List<AppPickerOption<int>> _vendorOptions;
  late final List<AppPickerOption<int>> _warehouseOptions;
  late final List<AppPickerOption<int>> _itemOptions;
  static const _categoryOptions = [
    AppPickerOption<String>('Count (pcs)', 'Count (pcs)'),
    AppPickerOption<String>('Weight', 'Weight'),
    AppPickerOption<String>('Volume', 'Volume'),
    AppPickerOption<String>('Length / Size', 'Length / Size'),
    AppPickerOption<String>('Roll / Tape', 'Roll / Tape'),
  ];

  static const _measureUnitOptions = ['kg', 'g'];

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
      for (final i in widget.items) AppPickerOption<int>(i.id, i.name),
    ];
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
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

  InventoryItem? _itemFor(_PurchaseOrderLineDraft line) {
    for (final item in widget.items) {
      if (item.id == line.itemId) return item;
    }
    return null;
  }

  num _lineTotal(_PurchaseOrderLineDraft line) =>
      (num.tryParse(line.quantity.text) ?? 0) *
      (num.tryParse(line.price.text) ?? 0);

  num get _total =>
      _lines.fold<num>(0, (total, line) => total + _lineTotal(line));

  String? _numberValidator(String? value) =>
      num.tryParse(value?.trim() ?? '') == null ? 'Enter a number' : null;

  void _addLine() {
    setState(() => _lines.add(_PurchaseOrderLineDraft()));
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    final line = _lines.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => line.dispose());
  }

  bool _usesMeasure(String? category) =>
      category != null &&
      !category.toLowerCase().contains('count') &&
      !category.toLowerCase().contains('pcs') &&
      !category.toLowerCase().contains('nos');

  String? _categoryForItemUnit(String? unit) {
    final normalized = unit?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (['kg', 'g', 'ton', 'weight'].contains(normalized)) return 'Weight';
    if (['ml', 'l', 'liter', 'litre', 'volume'].contains(normalized)) {
      return 'Volume';
    }
    if (['m', 'cm', 'mm', 'length', 'size'].contains(normalized)) {
      return 'Length / Size';
    }
    if (normalized.contains('roll') || normalized.contains('tape')) {
      return 'Roll / Tape';
    }
    if (['nos', 'pcs', 'piece', 'pieces', 'count'].contains(normalized)) {
      return 'Count (pcs)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: 'Create Purchase Order',
      subtitle: 'Choose the vendor, warehouse and products to order.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatInr(_total),
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
              errorText: _submitted && _vendorId == null
                  ? 'Select a vendor'
                  : null,
              onChanged: (v) => setState(() => _vendorId = v),
            ),
            const SizedBox(height: 12),
            AppPickerField<int>(
              label: 'Warehouse',
              value: _warehouseId,
              options: _warehouseOptions,
              onChanged: (v) => setState(() => _warehouseId = v),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Items',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _lines.length; index++)
              _lineEditor(index, _lines[index]),
          ],
        ),
      ),
    );
  }

  Widget _lineEditor(int index, _PurchaseOrderLineDraft line) {
    final item = _itemFor(line);

    return Container(
      key: ObjectKey(line),
      margin: EdgeInsets.only(bottom: index == _lines.length - 1 ? 0 : 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_lines.length > 1)
                IconButton(
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeLine(index),
                  icon: Icon(Icons.close, size: 20, color: AppColors.muted),
                ),
            ],
          ),
          AppPickerField<int>(
            label: 'Item',
            required: true,
            value: line.itemId,
            options: _itemOptions,
            errorText: _submitted && line.itemId == null
                ? 'Select an item'
                : null,
            onChanged: (id) {
              final selected = widget.items.firstWhere(
                (candidate) => candidate.id == id,
              );
              setState(() {
                line.itemId = id;
                line.unitCategory = _categoryForItemUnit(selected.unit);
                line.unitValue.clear();
                if (_usesMeasure(line.unitCategory) &&
                    line.measureUnit == null) {
                  line.measureUnit = 'kg';
                }
                if (!_usesMeasure(line.unitCategory)) {
                  line.measureUnit = null;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          AppPickerField<String>(
            label: 'Unit',
            value: line.unitCategory,
            options: _categoryOptions,
            onChanged: (value) => setState(() {
              line.unitCategory = value;
              if (!_usesMeasure(value)) {
                line.unitValue.clear();
                line.measureUnit = null;
              }
              if (_usesMeasure(value) && line.measureUnit == null) {
                line.measureUnit = 'kg';
              }
            }),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  scrollPadding: const EdgeInsets.only(bottom: 160),
                  onChanged: (_) => setState(() {}),
                  validator: _numberValidator,
                  decoration: appFieldDecoration('Qty', required: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: line.price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  scrollPadding: const EdgeInsets.only(bottom: 160),
                  onChanged: (_) => setState(() {}),
                  validator: _numberValidator,
                  decoration: appFieldDecoration(
                    'Price',
                    required: true,
                    prefixText: '₹ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_usesMeasure(line.unitCategory))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.unitValue,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return num.tryParse(value.trim()) == null
                          ? 'Enter a number'
                          : null;
                    },
                    decoration: appFieldDecoration('Value'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppPickerField<String>(
                    label: 'Measure',
                    value: line.measureUnit,
                    options: [
                      for (final unit in _measureUnitOptions)
                        AppPickerOption<String>(unit, unit),
                    ],
                    onChanged: (unit) =>
                        setState(() => line.measureUnit = unit),
                  ),
                ),
              ],
            )
          else
            Text(
              'Measure  —',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Line total',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatInr(_lineTotal(line)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (item != null && _hasProductDimensions(item)) ...[
            const SizedBox(height: 8),
            _ProductDimensions(item: item),
          ],
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    final vendorId = _vendorId;
    final warehouseId = _warehouseId;
    if (!formOk || vendorId == null) {
      return;
    }

    final orderItems = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final itemId = line.itemId;
      final item = _itemFor(line);
      final quantity = num.tryParse(line.quantity.text);
      final price = num.tryParse(line.price.text);
      if (itemId == null || item == null || quantity == null || price == null) {
        return;
      }
      orderItems.add({
        'itemId': itemId,
        'orderedQty': quantity,
        'price': price,
        'unitCategory': line.unitCategory,
        'unitValue': num.tryParse(line.unitValue.text.trim()),
        'measureUnit': _usesMeasure(line.unitCategory)
            ? line.measureUnit
            : null,
        'specifications': _purchaseDimensions(item),
        'length': _dimensionNumber(item, 'length') ?? item.rollLengthM,
        'width': _dimensionNumber(item, 'width') ?? item.rollWidthMm,
        'thickness':
            _dimensionNumber(item, 'thickness') ?? item.rollThicknessMic,
        'weight': _dimensionNumber(item, 'weight'),
      });
    }

    Navigator.pop(
      context,
      _CreateOrderResult({
        'vendorId': vendorId,
        if (warehouseId != null) 'warehouseId': warehouseId,
        'items': orderItems,
      }),
    );
  }

  bool _hasProductDimensions(InventoryItem item) =>
      item.productDimensions.isNotEmpty ||
      item.rollLengthM != null ||
      item.rollWidthMm != null ||
      item.rollThicknessMic != null;

  Map<String, dynamic> _purchaseDimensions(InventoryItem item) {
    return {
      if (item.productDimensions.isNotEmpty)
        'productDimensions': item.productDimensions,
      if (item.rollLengthM != null) 'rollLengthM': item.rollLengthM,
      if (item.rollWidthMm != null) 'rollWidthMm': item.rollWidthMm,
      if (item.rollThicknessMic != null)
        'rollThicknessMic': item.rollThicknessMic,
    };
  }

  num? _dimensionNumber(InventoryItem item, String name) {
    for (final dimension in item.productDimensions) {
      final label = dimension['label']?.toString().trim().toLowerCase() ?? '';
      if (label == name ||
          label.startsWith('$name ') ||
          label.startsWith('$name(')) {
        return num.tryParse(dimension['value']?.toString() ?? '');
      }
    }
    return null;
  }
}

class _PurchaseOrderLineDraft {
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  final unitValue = TextEditingController();
  int? itemId;
  String? unitCategory;
  String? measureUnit;

  void dispose() {
    quantity.dispose();
    price.dispose();
    unitValue.dispose();
  }
}

class _ProductDimensions extends StatelessWidget {
  final InventoryItem item;

  const _ProductDimensions({required this.item});

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    for (final dimension in item.productDimensions) {
      final label = dimension['label']?.toString().trim() ?? '';
      final value = dimension['value']?.toString().trim() ?? '';
      final unit = dimension['unit']?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      details.add(
        '$label${value.isEmpty ? '' : ': $value'}${unit.isEmpty ? '' : ' $unit'}',
      );
    }
    if (item.rollLengthM != null &&
        !details.any((detail) => detail.toLowerCase().startsWith('length'))) {
      details.add('Length: ${item.rollLengthM} m');
    }
    if (item.rollWidthMm != null &&
        !details.any((detail) => detail.toLowerCase().startsWith('width'))) {
      details.add('Width: ${item.rollWidthMm} mm');
    }
    if (item.rollThicknessMic != null &&
        !details.any(
          (detail) => detail.toLowerCase().startsWith('thickness'),
        )) {
      details.add('Thickness: ${item.rollThicknessMic} mic');
    }
    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final detail in details)
            Text(
              detail,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
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
