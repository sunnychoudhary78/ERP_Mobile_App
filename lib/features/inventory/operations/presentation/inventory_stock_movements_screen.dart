import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryStockMovementsScreen extends ConsumerStatefulWidget {
  const InventoryStockMovementsScreen({super.key});

  @override
  ConsumerState<InventoryStockMovementsScreen> createState() =>
      _InventoryStockMovementsScreenState();
}

class _InventoryStockMovementsScreenState
    extends ConsumerState<InventoryStockMovementsScreen>
    with InventoryUiHelpers<InventoryStockMovementsScreen> {
  int _view = 0;
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    return asList(
      _view == 0 ? repo.getStockOutBills() : repo.getPaymentsReceived(),
    );
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canAdd =
        auth.can(AppPermissions.inventoryManage) ||
        auth.can(AppPermissions.productManage);
    return Scaffold(
      appBar: AppBar(title: const Text('Stock movements')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _stockActions,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Stock movement'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Stock out bills'),
                  icon: Icon(Icons.receipt_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Payments received'),
                  icon: Icon(Icons.payments_outlined),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (v) => setState(() {
                _view = v.first;
                _load = _fetch();
              }),
            ),
          ),
          Expanded(
            child: loadBody<List<dynamic>>(
              future: _load,
              what: _view == 0 ? 'stock out bills' : 'payments received',
              builder: (rows) => cardList<dynamic>(
                rows,
                emptyTitle: _view == 0
                    ? 'No stock out bills'
                    : 'No payments received',
                emptyMessage:
                    'Records will appear here after they are created.',
                itemBuilder: (r) => dataCard(
                  title: pickText(
                    mapOf(r),
                    ['billNo', 'customer', 'partyName', 'reference'],
                    fallback: _view == 0
                        ? 'Stock out bill'
                        : 'Payment received',
                  ),
                  subtitle:
                      '${pickText(mapOf(r), ['itemName', 'method', 'paymentStatus', 'receivedAt'])}  •  ${fmtDate(mapOf(r)['createdAt'])}',
                  amount:
                      '₹${fmtMoney(mapOf(r)['totalAmount'] ?? mapOf(r)['amount'])}',
                  icon: _view == 0
                      ? Icons.receipt_long_outlined
                      : Icons.payments_outlined,
                  onTap: _view == 0
                      ? () => _showStockOutBill(toInt(mapOf(r)['id']))
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warehouseStockChips(dynamic response) {
    dynamic rows = response;
    if (rows is Map && rows['data'] != null) rows = rows['data'];
    if (rows is Map) {
      rows =
          rows['warehouseStock'] ?? rows['stocks'] ?? rows['data'] ?? const [];
    }
    final balances = rows is List ? rows : const [];
    if (balances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No stock available in the warehouses'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available by warehouse',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final raw in balances)
                Builder(
                  builder: (context) {
                    final row = mapOf(raw);
                    final warehouse = mapOf(row['warehouse']);
                    final label = pickText(
                      row,
                      ['warehouseName'],
                      fallback: pickText(warehouse, [
                        'name',
                      ], fallback: 'Warehouse'),
                    );
                    return Chip(
                      label: Text(
                        '$label: ${pickText(row, ['quantity', 'availableQty'], fallback: '0')}',
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _stockActions() async {
    final auth = ref.read(authProvider);
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            if (auth.canAny(const [
              AppPermissions.inventoryManage,
              AppPermissions.productManage,
            ]))
              ListTile(
                leading: const Icon(Icons.call_received),
                title: const Text('Stock in'),
                onTap: () => Navigator.pop(c, 'in'),
              ),
            if (auth.canAny(const [
              AppPermissions.inventoryManage,
              AppPermissions.productManage,
            ]))
              ListTile(
                leading: const Icon(Icons.call_made),
                title: const Text('Stock out'),
                onTap: () => Navigator.pop(c, 'out'),
              ),
            if (auth.canAny(const [
              AppPermissions.inventoryManage,
              AppPermissions.inventoryTransfer,
            ]))
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transfer between warehouses'),
                onTap: () => Navigator.pop(c, 'transfer'),
              ),
            if (auth.can(AppPermissions.vendorPaymentManage))
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Record customer payment'),
                onTap: () => Navigator.pop(c, 'payment'),
              ),
          ],
        ),
      ),
    );
    if (kind == null) return;
    if (kind == 'payment') {
      await _receivePayment();
      return;
    }
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final items = (await repo.getItems(limit: 500)).items;
      final selectableItems = kind == 'out'
          ? items.where((item) => item.currentStock > 0).toList()
          : items;
      final warehouses = await repo.getWarehouses();
      if (!mounted) return;
      // All controllers/state live inside the dialog widget, so they are
      // disposed together with the dialog (not while it is still animating
      // out) and survive validation / server errors.
      final submitted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _StockMovementDialog(
          kind: kind,
          items: selectableItems,
          warehouses: warehouses,
          loadAvailability: (id) => repo.getStockOutWarehouseStock(id),
          availabilityBuilder: _warehouseStockChips,
          onSubmit: (body) => _saveMovement(kind, body),
        ),
      );
      if (submitted != true || !mounted) return;
      showSuccess(
        kind == 'in'
            ? 'Stock added'
            : kind == 'out'
            ? 'Stock issued'
            : 'Stock transferred',
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _saveMovement(String kind, Map<String, dynamic> body) async {
    final repo = ref.read(inventoryRepositoryProvider);
    if (kind == 'in') {
      await repo.stockIn(body);
    } else if (kind == 'out') {
      await repo.stockOut(body);
    } else {
      await repo.transferStock(body);
    }
  }

  Future<void> _receivePayment() async {
    final customer = TextEditingController();
    final billNo = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    String method = 'Bank Transfer';
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Record customer payment'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: customer,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter customer name'
                        : null,
                  ),
                  TextFormField(
                    controller: billNo,
                    decoration: const InputDecoration(labelText: 'Bill number'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter bill number'
                        : null,
                  ),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                    ),
                    validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Enter a positive amount'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: [
                      for (final value in [
                        'Bank Transfer',
                        'UPI',
                        'Cheque',
                        'Cash',
                      ])
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: (v) => setModal(() => method = v ?? method),
                  ),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save payment'),
            ),
          ],
        ),
      ),
    );
    if (submit != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).createPaymentReceived({
        'customer': customer.text.trim(),
        'billNo': billNo.text.trim(),
        'amount': num.parse(amount.text),
        'method': method,
        'receivedAt': DateTime.now().toIso8601String().substring(0, 10),
        'note': note.text.trim(),
      });
      showSuccess('Customer payment recorded');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _showStockOutBill(int id) async {
    if (id <= 0) return;
    try {
      final response = await ref
          .read(inventoryRepositoryProvider)
          .getStockOutBill(id);
      final payload = response is Map && response['data'] is Map
          ? response['data']
          : response;
      if (!mounted) return;
      await showDetails(mapOf(payload));
    } catch (e) {
      showError(e);
    }
  }
}

/// Pulls a human-readable message out of an API / network error.
String _readableError(Object e) {
  try {
    final data = (e as dynamic).response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m is List) return m.join('\n');
      if (m != null) return '$m';
    }
  } catch (_) {}
  try {
    final m = (e as dynamic).message;
    if (m is String && m.isNotEmpty) return m;
  } catch (_) {}
  return e.toString().replaceFirst(RegExp(r'^(Exception|Error): '), '');
}

class _StockMovementDialog extends StatefulWidget {
  const _StockMovementDialog({
    required this.kind,
    required this.items,
    required this.warehouses,
    required this.loadAvailability,
    required this.availabilityBuilder,
    required this.onSubmit,
  });

  final String kind; // 'in' | 'out' | 'transfer'
  final List<dynamic> items;
  final List<dynamic> warehouses;
  final Future<dynamic> Function(int itemId) loadAvailability;
  final Widget Function(dynamic response) availabilityBuilder;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  static final _gstinRegex = RegExp(
    r'^\d{2}[A-Z]{5}\d{4}[A-Z][A-Z\d]Z[A-Z\d]$',
  );

  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController(text: '0');
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  final _partyName = TextEditingController();
  final _partyGstin = TextEditingController();
  final _unitRate = TextEditingController();
  final _gstRate = TextEditingController(text: '18');

  int? _itemId;
  int? _warehouseId;
  int? _toWarehouseId;
  Future<dynamic>? _availability;
  bool _generateBill = false;
  bool _submitting = false;
  String? _error;

  bool get _isIn => widget.kind == 'in';
  bool get _isOut => widget.kind == 'out';
  bool get _isTransfer => widget.kind == 'transfer';

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    _reference.dispose();
    _notes.dispose();
    _partyName.dispose();
    _partyGstin.dispose();
    _unitRate.dispose();
    _gstRate.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final qty = int.parse(_quantity.text.trim());
    final refNo = _reference.text.trim();
    final note = _notes.text.trim();
    if (_isTransfer) {
      return {
        'itemId': _itemId,
        'fromWarehouseId': _warehouseId,
        'toWarehouseId': _toWarehouseId,
        'quantity': qty,
        if (refNo.isNotEmpty) 'referenceNo': refNo,
        if (note.isNotEmpty) 'notes': note,
      };
    }
    return {
      'itemId': _itemId,
      'warehouseId': _warehouseId,
      'quantity': qty,
      if (refNo.isNotEmpty) 'referenceNo': refNo,
      if (note.isNotEmpty) 'notes': note,
      if (_isIn) 'unitCost': num.tryParse(_unitCost.text.trim()) ?? 0,
      if (_isOut) 'generateBill': _generateBill,
      if (_isOut && _generateBill) 'partyName': _partyName.text.trim(),
      if (_isOut && _generateBill)
        'partyGstin': _partyGstin.text.trim().toUpperCase(),
      if (_isOut && _generateBill) 'unitRate': num.parse(_unitRate.text.trim()),
      if (_isOut && _generateBill) 'gstRate': num.parse(_gstRate.text.trim()),
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_buildBody());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Keep the dialog open with every field intact and show the reason.
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _readableError(e);
      });
    }
  }

  InputDecoration _dec(
    String label, {
    IconData? icon,
    String? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      errorMaxLines: 2,
    );
  }

  List<dynamic> _availabilityRows(dynamic response) {
    dynamic rows = response;
    if (rows is Map && rows['data'] != null) rows = rows['data'];
    if (rows is Map) {
      rows =
          rows['warehouseStock'] ?? rows['stocks'] ?? rows['data'] ?? const [];
    }
    return rows is List ? rows : const [];
  }

  int? _stockWarehouseId(Map<String, dynamic> row) {
    final nestedWarehouse = row['warehouse'];
    final nestedId = nestedWarehouse is Map ? nestedWarehouse['id'] : null;
    final value = row['warehouseId'] ?? row['warehouse_id'] ?? nestedId;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  num _warehouseQuantity(Map<String, dynamic> row) {
    final value =
        row['quantity'] ??
        row['availableQty'] ??
        row['available_qty'] ??
        row['availableQuantity'] ??
        row['available_quantity'] ??
        row['qty'];
    return value is num ? value : num.tryParse('$value') ?? 0;
  }

  Widget _warehouseField() {
    if (!_isOut) return _warehouseDropdown(widget.warehouses);
    if (_itemId == null || _availability == null) {
      return _warehouseDropdown(
        const [],
        enabled: false,
        helperText: 'Select a product to see available warehouses',
      );
    }

    return FutureBuilder<dynamic>(
      future: _availability,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Could not load warehouse stock: '
                '${_readableError(snapshot.error!)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton.icon(
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                        _availability = widget.loadAvailability(_itemId!);
                      }),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _warehouseDropdown(
                const [],
                enabled: false,
                helperText: 'Loading available warehouses',
              ),
              const LinearProgressIndicator(),
            ],
          );
        }

        final quantitiesByWarehouse = <int, num>{};
        for (final raw in _availabilityRows(snapshot.data)) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          final warehouseId = _stockWarehouseId(row);
          if (warehouseId == null) continue;
          quantitiesByWarehouse.update(
            warehouseId,
            (quantity) => quantity + _warehouseQuantity(row),
            ifAbsent: () => _warehouseQuantity(row),
          );
        }
        final availableWarehouses = widget.warehouses
            .where(
              (warehouse) => (quantitiesByWarehouse[warehouse.id] ?? 0) > 0,
            )
            .toList();
        return _warehouseDropdown(
          availableWarehouses,
          helperText: availableWarehouses.isEmpty
              ? 'No warehouses have stock for this product'
              : null,
        );
      },
    );
  }

  Widget _warehouseDropdown(
    List<dynamic> warehouses, {
    bool enabled = true,
    String? helperText,
  }) {
    final selectableIds = warehouses.map((warehouse) => warehouse.id).toList()
      ..sort();
    final selectedWarehouseId = selectableIds.contains(_warehouseId)
        ? _warehouseId
        : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('warehouse-$_itemId-$selectableIds'),
      isExpanded: true,
      value: selectedWarehouseId,
      decoration: _dec(
        _isTransfer ? 'From warehouse' : 'Warehouse',
        icon: Icons.warehouse_outlined,
      ).copyWith(helperText: helperText),
      items: [
        for (final warehouse in warehouses)
          DropdownMenuItem<int>(
            value: warehouse.id as int,
            child: Text(
              '${warehouse.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: _submitting || !enabled
          ? null
          : (value) => setState(() {
              _warehouseId = value;
              if (_toWarehouseId == value) _toWarehouseId = null;
            }),
      validator: (value) {
        if (value != null) return null;
        if (_isOut && _itemId == null) return 'Select a product first';
        if (_isOut && enabled && warehouses.isEmpty) {
          return 'No warehouse has stock for this product';
        }
        return 'Select a warehouse';
      },
    );
  }

  Widget _section(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = _isIn
        ? 'Stock in'
        : _isOut
        ? 'Stock out'
        : 'Warehouse transfer';
    final subtitle = _isIn
        ? 'Add incoming stock to a warehouse.'
        : _isOut
        ? 'Issue stock from a warehouse.'
        : 'Move stock from one warehouse to another.';
    final icon = _isIn
        ? Icons.call_received
        : _isOut
        ? Icons.call_made
        : Icons.swap_horiz;
    final actionLabel = _isIn
        ? 'Add stock'
        : _isOut
        ? 'Issue stock'
        : 'Transfer';
    final badgeBg = _isIn
        ? scheme.tertiaryContainer
        : _isOut
        ? scheme.secondaryContainer
        : scheme.primaryContainer;
    final badgeFg = _isIn
        ? scheme.onTertiaryContainer
        : _isOut
        ? scheme.onSecondaryContainer
        : scheme.onPrimaryContainer;

    return PopScope(
      canPop: !_submitting,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: badgeFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Inline error (form data is kept)
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Product & warehouse'),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _itemId,
                          decoration: _dec(
                            'Product',
                            icon: Icons.inventory_2_outlined,
                          ),
                          items: [
                            for (final item in widget.items)
                              DropdownMenuItem<int>(
                                value: item.id as int,
                                child: Text(
                                  _isTransfer || _isOut
                                      ? item.name
                                      : '${item.name} (${item.sku})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (v) => setState(() {
                                  _itemId = v;
                                  _warehouseId = null;
                                  _availability = _isOut && v != null
                                      ? widget.loadAvailability(v)
                                      : null;
                                }),
                          validator: (v) =>
                              v == null ? 'Select a product' : null,
                        ),
                        const SizedBox(height: 14),
                        _warehouseField(),
                        if (_isTransfer) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            key: ValueKey('to-$_warehouseId'),
                            isExpanded: true,
                            value: _toWarehouseId,
                            decoration: _dec(
                              'To warehouse',
                              icon: Icons.local_shipping_outlined,
                            ),
                            items: [
                              for (final w in widget.warehouses.where(
                                (w) => w.id != _warehouseId,
                              ))
                                DropdownMenuItem<int>(
                                  value: w.id as int,
                                  child: Text(
                                    '${w.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (v) => setState(() => _toWarehouseId = v),
                            validator: (v) =>
                                v == null ? 'Select destination' : null,
                          ),
                        ],
                        if (_isOut && _availability != null)
                          FutureBuilder<dynamic>(
                            future: _availability,
                            builder: (context, snap) {
                              if (snap.hasError) return const SizedBox.shrink();
                              if (!snap.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              return widget.availabilityBuilder(snap.data);
                            },
                          ),

                        const SizedBox(height: 10),
                        _section('Quantity'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantity,
                                enabled: !_submitting,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _dec(
                                  'Quantity',
                                  icon: Icons.numbers,
                                  suffix: 'units',
                                ),
                                validator: (v) =>
                                    (int.tryParse((v ?? '').trim()) ?? 0) <= 0
                                    ? 'Enter a positive whole quantity'
                                    : null,
                              ),
                            ),
                            if (_isIn) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _unitCost,
                                  enabled: !_submitting,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _dec('Unit cost', prefix: '₹ '),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),
                        _section('Details (optional)'),
                        TextFormField(
                          controller: _reference,
                          enabled: !_submitting,
                          decoration: _dec('Reference number', icon: Icons.tag),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _notes,
                          enabled: !_submitting,
                          minLines: 1,
                          maxLines: 3,
                          decoration: _dec('Notes', icon: Icons.notes),
                        ),

                        if (_isOut) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: .45,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Create stock out bill',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Generate a GST bill for the buyer',
                                  ),
                                  value: _generateBill,
                                  onChanged: _submitting
                                      ? null
                                      : (v) =>
                                            setState(() => _generateBill = v),
                                ),
                                if (_generateBill) ...[
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _partyName,
                                    enabled: !_submitting,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: _dec(
                                      'Buyer / party name',
                                      icon: Icons.person_outline,
                                    ),
                                    validator: (v) =>
                                        _generateBill &&
                                            (v == null || v.trim().isEmpty)
                                        ? 'Buyer name is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _partyGstin,
                                    enabled: !_submitting,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    decoration: _dec(
                                      'Buyer GSTIN',
                                      icon: Icons.badge_outlined,
                                    ),
                                    validator: (v) =>
                                        _generateBill &&
                                            !_gstinRegex.hasMatch(
                                              (v ?? '').trim().toUpperCase(),
                                            )
                                        ? 'Invalid GST number'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _unitRate,
                                    enabled: !_submitting,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _dec('Unit rate', prefix: '₹ '),
                                    validator: (v) =>
                                        _generateBill &&
                                            (num.tryParse((v ?? '').trim()) ??
                                                    0) <=
                                                0
                                        ? 'Enter a unit rate'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _gstRate,
                                    enabled: !_submitting,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    decoration: _dec('GST rate', suffix: '%'),
                                    validator: (value) {
                                      if (!_generateBill) return null;
                                      final text = (value ?? '').trim();
                                      if (text.isEmpty) {
                                        return 'Enter GST rate';
                                      }
                                      final rate = num.tryParse(text);
                                      if (rate == null) {
                                        return 'Enter a valid number';
                                      }
                                      return rate < 0 || rate > 100
                                          ? 'GST rate must be 0 to 100'
                                          : null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(icon),
                        label: Text(_submitting ? 'Saving...' : actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
