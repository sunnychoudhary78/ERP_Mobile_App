import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryStockMovementsScreen extends ConsumerStatefulWidget {
  const InventoryStockMovementsScreen({super.key});

  @override
  ConsumerState<InventoryStockMovementsScreen> createState() => _InventoryStockMovementsScreenState();
}

class _InventoryStockMovementsScreenState extends ConsumerState<InventoryStockMovementsScreen>
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
                emptyMessage: 'Records will appear here after they are created.',
                itemBuilder: (r) => dataCard(
                  title: pickText(
                    mapOf(r),
                    ['billNo', 'customer', 'partyName', 'reference'],
                    fallback: _view == 0 ? 'Stock out bill' : 'Payment received',
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
      int? itemId, warehouseId, toWarehouseId;
      final quantity = TextEditingController();
      final unitCost = TextEditingController(text: '0');
      final reference = TextEditingController();
      final notes = TextEditingController();
      Future<dynamic>? availabilityFuture;
      final partyName = TextEditingController();
      final partyGstin = TextEditingController();
      final unitRate = TextEditingController();
      bool generateBill = false;
      final formKey = GlobalKey<FormState>();
      final submitted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: Text(
              kind == 'in'
                  ? 'Stock in'
                  : kind == 'out'
                  ? 'Stock out'
                  : 'Warehouse transfer',
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            kind == 'in'
                                ? 'Choose the product and destination for the incoming stock.'
                                : kind == 'out'
                                ? 'Choose the product and warehouse to issue stock from.'
                                : 'Choose a product, source warehouse, and destination.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: [
                          for (final item in selectableItems)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                '${item.name} (${item.sku})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setModal(() {
                          itemId = v;
                          availabilityFuture = kind == 'out' && v != null
                              ? repo.getStockOutWarehouseStock(v)
                              : null;
                        }),
                        validator: (v) => v == null ? 'Select a product' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: kind == 'transfer'
                              ? 'From warehouse'
                              : 'Warehouse',
                        ),
                        items: [
                          for (final w in warehouses)
                            DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setModal(() => warehouseId = v),
                        validator: (v) =>
                            v == null ? 'Select a warehouse' : null,
                      ),
                      if (kind == 'transfer')
                        const SizedBox(height: 12),
                      if (kind == 'transfer')
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'To warehouse',
                          ),
                          items: [
                            for (final w in warehouses.where(
                              (w) => w.id != warehouseId,
                            ))
                              DropdownMenuItem(
                                value: w.id,
                                child: Text(
                                  w.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setModal(() => toWarehouseId = v),
                          validator: (v) =>
                              v == null ? 'Select destination' : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          suffixText: 'units',
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter a positive whole quantity'
                            : null,
                      ),
                      if (kind == 'in')
                        const SizedBox(height: 12),
                      if (kind == 'in')
                        TextFormField(
                          controller: unitCost,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Unit cost',
                            prefixText: '₹ ',
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reference,
                        decoration: const InputDecoration(
                          labelText: 'Reference number (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notes,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      if (kind == 'out') ...[
                        const Divider(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Create stock out bill'),
                          value: generateBill,
                          onChanged: (value) =>
                              setModal(() => generateBill = value),
                        ),
                        if (generateBill) ...[
                          TextFormField(
                            controller: partyName,
                            decoration: const InputDecoration(
                              labelText: 'Buyer / party name',
                            ),
                            validator: (v) =>
                                generateBill && (v == null || v.trim().isEmpty)
                                ? 'Buyer name is required'
                                : null,
                          ),
                          TextFormField(
                            controller: partyGstin,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Buyer GSTIN',
                            ),
                            validator: (v) =>
                                generateBill &&
                                    !RegExp(
                                      r'^\d{2}[A-Z]{5}\d{4}[A-Z][A-Z\d]Z[A-Z\d]$',
                                    ).hasMatch((v ?? '').trim().toUpperCase())
                                ? 'Enter a valid GSTIN'
                                : null,
                          ),
                          TextFormField(
                            controller: unitRate,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Unit rate',
                              prefixText: '₹ ',
                            ),
                            validator: (v) =>
                                generateBill &&
                                    (num.tryParse(v ?? '') ?? 0) <= 0
                                ? 'Enter a positive unit rate'
                                : null,
                          ),
                        ],
                      ],
                      if (kind == 'out' && availabilityFuture != null)
                        FutureBuilder<dynamic>(
                          future: availabilityFuture,
                          builder: (context, stockSnapshot) {
                            if (!stockSnapshot.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return _warehouseStockChips(stockSnapshot.data);
                          },
                        ),
                    ],
                  ),
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
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
      if (submitted != true || itemId == null || warehouseId == null) return;
      final body = <String, dynamic>{
        'itemId': itemId,
        'warehouseId': warehouseId,
        'quantity': int.parse(quantity.text),
        if (reference.text.trim().isNotEmpty)
          'referenceNo': reference.text.trim(),
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      };
      if (kind == 'in')
        await repo.stockIn({
          ...body,
          'unitCost': num.tryParse(unitCost.text) ?? 0,
        });
      if (kind == 'out') {
        await repo.stockOut({
          ...body,
          'generateBill': generateBill,
          if (generateBill) 'partyName': partyName.text.trim(),
          if (generateBill) 'partyGstin': partyGstin.text.trim().toUpperCase(),
          if (generateBill) 'unitRate': num.parse(unitRate.text),
        });
      }
      if (kind == 'transfer' && toWarehouseId != null) {
        await repo.transferStock({
          'itemId': itemId,
          'fromWarehouseId': warehouseId,
          'toWarehouseId': toWarehouseId,
          'quantity': int.parse(quantity.text),
          if (reference.text.trim().isNotEmpty)
            'referenceNo': reference.text.trim(),
          if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
        });
      }
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
