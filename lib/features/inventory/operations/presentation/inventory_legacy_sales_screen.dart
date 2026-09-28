import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryLegacySalesScreen extends ConsumerStatefulWidget {
  const InventoryLegacySalesScreen({super.key});

  @override
  ConsumerState<InventoryLegacySalesScreen> createState() => _InventoryLegacySalesScreenState();
}

class _InventoryLegacySalesScreenState extends ConsumerState<InventoryLegacySalesScreen>
    with InventoryUiHelpers<InventoryLegacySalesScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    final auth = ref.read(authProvider);
    final canCustomers = auth.canAny(const [
      AppPermissions.customerView,
      AppPermissions.customerManage,
    ]);
    final canInvoices = auth.can(AppPermissions.invoiceView);
    return Future.wait<dynamic>([
      canCustomers ? repo.getLegacyCustomers() : Future.value(<dynamic>[]),
      auth.canAny(const [
            AppPermissions.salesOrderView,
            AppPermissions.salesOrderManage,
          ])
          ? repo.getLegacySales()
          : Future.value(<dynamic>[]),
      canInvoices ? repo.getLegacyInvoices() : Future.value(<dynamic>[]),
      canInvoices ? repo.getCreditNotes() : Future.value(<dynamic>[]),
      canInvoices ? repo.getSalesReturns() : Future.value(<dynamic>[]),
      canCustomers ? repo.getGstSlabs() : Future.value(<dynamic>[]),
    ]);
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canCreate = auth.canAny(const [
      AppPermissions.customerManage,
      AppPermissions.salesOrderManage,
    ]);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales & customers'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Customers'),
              Tab(text: 'Orders'),
              Tab(text: 'Invoices'),
              Tab(text: 'Credit notes'),
              Tab(text: 'Returns'),
            ],
          ),
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('New sale / customer'),
              )
            : null,
        body: loadBody<List<dynamic>>(
          future: _load,
          what: 'sales',
          builder: _content,
        ),
      ),
    );
  }

  Widget _content(List<dynamic> data) {
    final customers = asRows(data[0]);
    final sales = asRows(data[1]);
    final invoices = asRows(data[2]);
    final credits = asRows(data[3]);
    final returns = asRows(data[4]);
    final gstSlabs = asRows(data[5]);
    return TabBarView(
      children: [
        cardList<Map<String, dynamic>>(
          customers,
          emptyTitle: 'No customers',
          emptyMessage: 'Customer records used by the legacy sales flow.',
          itemBuilder: (c) => _customerCard(c, gstSlabs),
        ),
        cardList<Map<String, dynamic>>(
          sales,
          emptyTitle: 'No sales orders',
          emptyMessage: 'Lot-based and auto-allocated orders appear here.',
          itemBuilder: _saleCard,
        ),
        cardList<Map<String, dynamic>>(
          invoices,
          emptyTitle: 'No invoices',
          emptyMessage: 'Sales invoices appear here.',
          itemBuilder: (invoice) => recordCard(invoice, [
            'invoiceNo',
            'invoiceNumber',
            'billNo',
          ], icon: Icons.receipt_long_outlined),
        ),
        cardList<Map<String, dynamic>>(
          credits,
          emptyTitle: 'No credit notes',
          emptyMessage: 'Accounts credit note records appear here.',
          itemBuilder: (credit) => recordCard(credit, [
            'creditNoteNo',
            'number',
            'id',
          ], icon: Icons.credit_score_outlined),
        ),
        cardList<Map<String, dynamic>>(
          returns,
          emptyTitle: 'No sales returns',
          emptyMessage: 'Update return review status from here.',
          itemBuilder: _returnCard,
        ),
      ],
    );
  }

  Future<void> _create() async {
    final auth = ref.read(authProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            if (auth.can(AppPermissions.customerManage))
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Add customer'),
                onTap: () => Navigator.pop(c, 'customer'),
              ),
            if (auth.can(AppPermissions.salesOrderManage))
              ListTile(
                leading: const Icon(Icons.point_of_sale_outlined),
                title: const Text('Create sale'),
                onTap: () => Navigator.pop(c, 'sale'),
              ),
          ],
        ),
      ),
    );
    if (choice == 'customer') {
      final slabs = asRows(
        await ref.read(inventoryRepositoryProvider).getGstSlabs(),
      );
      if (mounted) await _customerForm(gstSlabs: slabs);
    }
    if (choice == 'sale') await _saleForm();
  }

  Widget _customerCard(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> gstSlabs,
  ) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(pickText(row, ['name'], fallback: 'Customer')),
      subtitle: Text(
        [
          pickText(row, ['phone'], fallback: ''),
          pickText(row, ['email'], fallback: ''),
        ].where((s) => s.isNotEmpty).join('  •  '),
      ),
      trailing: ref.watch(authProvider).can(AppPermissions.customerManage)
          ? PopupMenuButton<String>(
              onSelected: (choice) {
                if (choice == 'edit')
                  _customerForm(existing: row, gstSlabs: gstSlabs);
                if (choice == 'delete') _deleteCustomer(row);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          : null,
    ),
  );

  Widget _saleCard(Map<String, dynamic> row) {
    final id = toInt(row['id']);
    final status = pickText(row, ['status'], fallback: '');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
        title: Text(
          pickText(row, [
            'invoiceNo',
            'invoiceNumber',
            'orderNo',
          ], fallback: 'Sales order #$id'),
        ),
        subtitle: Text(
          '${pickText(row, ['customerName', 'customer'])}  •  $status',
        ),
        trailing: status.toUpperCase() != 'COMPLETED'
            ? TextButton(
                onPressed: () => mutate(
                  () => ref
                      .read(inventoryRepositoryProvider)
                      .fulfillLegacySale(id),
                  'Order fulfilled',
                ),
                child: const Text('Fulfill'),
              )
            : null,
      ),
    );
  }

  Widget _returnCard(Map<String, dynamic> row) {
    final status = pickText(row, ['status'], fallback: 'PENDING');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.assignment_return_outlined),
        ),
        title: Text(
          pickText(row, ['returnNo', 'billNo', 'id'], fallback: 'Sales return'),
        ),
        subtitle: Text('Status: $status'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => mutate(
            () => ref
                .read(inventoryRepositoryProvider)
                .updateSalesReturnStatus(toInt(row['id']), v),
            'Return status updated',
          ),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'APPROVED', child: Text('Approve')),
            PopupMenuItem(value: 'REJECTED', child: Text('Reject')),
          ],
        ),
      ),
    );
  }

  Future<void> _customerForm({
    Map<String, dynamic>? existing,
    List<Map<String, dynamic>> gstSlabs = const [],
  }) async {
    final fields = {
      for (final key in [
        'name',
        'email',
        'phone',
        'address',
        'gstNumber',
        'panNumber',
        'bankAccountHolder',
        'bankName',
        'bankAccountNo',
        'bankIfsc',
        'bankBranch',
      ])
        key: TextEditingController(text: '${existing?[key] ?? ''}'),
    };
    final key = GlobalKey<FormState>();
    int? gstSlabId = int.tryParse('${existing?['gstSlabId'] ?? ''}');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add customer' : 'Edit customer'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gstSlabs.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: gstSlabId,
                      decoration: const InputDecoration(
                        labelText: 'GST slab (optional)',
                      ),
                      items: [
                        for (final slab in gstSlabs)
                          DropdownMenuItem(
                            value: toInt(slab['id']),
                            child: Text(
                              pickText(slab, [
                                'name',
                                'slabName',
                                'rate',
                              ], fallback: 'GST slab'),
                            ),
                          ),
                      ],
                      onChanged: (value) => gstSlabId = value,
                    ),
                  for (final field in fields.entries)
                    TextFormField(
                      controller: field.value,
                      decoration: InputDecoration(labelText: fieldLabel(field.key)),
                      validator: field.key == 'name'
                          ? (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null
                          : null,
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
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true) return;
    final Map<String, dynamic> body = {
      for (final entry in fields.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };
    if (gstSlabId != null) body['gstSlabId'] = gstSlabId;
    await mutate(
      () => existing == null
          ? ref.read(inventoryRepositoryProvider).createLegacyCustomer(body)
          : ref
                .read(inventoryRepositoryProvider)
                .updateLegacyCustomer(toInt(existing['id']), body),
      existing == null ? 'Customer created' : 'Customer updated',
    );
  }

  Future<void> _deleteCustomer(Map<String, dynamic> row) async {
    final ok = await confirmDialog(
      'Delete customer?',
      'This permanently deletes ${pickText(row, ['name'], fallback: 'this customer')}.',
    );
    if (ok)
      await mutate(
        () => ref
            .read(inventoryRepositoryProvider)
            .deleteLegacyCustomer(toInt(row['id'])),
        'Customer deleted',
      );
  }

  Future<void> _saleForm() async {
    final repo = ref.read(inventoryRepositoryProvider);
    try {
      final customers = asRows(await repo.getLegacyCustomers(limit: 200));
      final items = (await repo.getItems(limit: 500)).items;
      final lots = asRows(await repo.getLots(limit: 500));
      if (!mounted) return;
      int? customerId, itemId, lotId;
      bool automatic = false;
      final qty = TextEditingController(text: '1');
      final price = TextEditingController();
      final key = GlobalKey<FormState>();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Create sales order'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                        ),
                        items: [
                          for (final c in customers)
                            DropdownMenuItem(
                              value: toInt(c['id']),
                              child: Text(
                                pickText(c, ['name'], fallback: 'Customer'),
                              ),
                            ),
                        ],
                        onChanged: (v) => setModal(() => customerId = v),
                        validator: (v) =>
                            v == null ? 'Select a customer' : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto allocate from product stock'),
                        value: automatic,
                        onChanged: (v) => setModal(() {
                          automatic = v;
                          itemId = null;
                          lotId = null;
                        }),
                      ),
                      if (automatic)
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Product',
                          ),
                          items: [
                            for (final i in items)
                              DropdownMenuItem(
                                value: i.id,
                                child: Text(
                                  i.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setModal(() => itemId = v),
                          validator: (v) =>
                              v == null ? 'Select a product' : null,
                        )
                      else
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Sellable lot',
                          ),
                          items: [
                            for (final l in lots.where(
                              (l) => [
                                'SELLING',
                                'SELLING_APPROVAL_PENDING',
                              ].contains('${l['status']}'.toUpperCase()),
                            ))
                              DropdownMenuItem(
                                value: toInt(l['id'] ?? l['lotId']),
                                child: Text(
                                  '${l['lotNumber'] ?? 'Lot'}  •  ${pickText(mapOf(l['item']), ['name'])}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setModal(() => lotId = v),
                          validator: (v) =>
                              v == null ? 'Select a sellable lot' : null,
                        ),
                      TextFormField(
                        controller: qty,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter a positive quantity'
                            : null,
                      ),
                      TextFormField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Unit price',
                          prefixText: '₹ ',
                        ),
                        validator: (v) => (num.tryParse(v ?? '') ?? 0) < 0
                            ? 'Enter a valid price'
                            : null,
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
                  if (key.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );
      if (save != true || customerId == null) return;
      final line = automatic
          ? {
              'itemId': itemId,
              'quantity': num.parse(qty.text),
              'price': num.tryParse(price.text) ?? 0,
            }
          : {
              'lotId': lotId,
              'gradeId': null,
              'quantity': num.parse(qty.text),
              'price': num.tryParse(price.text) ?? 0,
            };
      await mutate(
        () => repo.createLegacySale({
          'customerId': customerId,
          'items': [line],
        }, automatic: automatic),
        'Sales order created',
      );
    } catch (e) {
      showError(e);
    }
  }
}
