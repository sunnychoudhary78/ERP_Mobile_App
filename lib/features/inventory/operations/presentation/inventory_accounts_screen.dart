import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryAccountsScreen extends ConsumerStatefulWidget {
  const InventoryAccountsScreen({super.key});

  @override
  ConsumerState<InventoryAccountsScreen> createState() => _InventoryAccountsScreenState();
}

class _InventoryAccountsScreenState extends ConsumerState<InventoryAccountsScreen>
    with InventoryUiHelpers<InventoryAccountsScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    final auth = ref.read(authProvider);
    if (!auth.canAny(const [
      AppPermissions.inventoryReportView,
      AppPermissions.inventoryManage,
    ])) {
      return Future.wait<dynamic>([
        Future.value(<String, dynamic>{}),
        Future.value(<dynamic>[]),
        Future.value(<String, dynamic>{}),
      ]);
    }
    return Future.wait<dynamic>([
      repo.getStockReconciliation(),
      repo.getStockJournals(),
      repo.getGodownStockValuation(),
    ]);
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final canCreate = ref.watch(authProvider).canAny(const [
      AppPermissions.inventoryManage,
      AppPermissions.billManage,
    ]);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reconciliation'),
              Tab(text: 'Valuation'),
              Tab(text: 'Journals'),
            ],
          ),
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: _journalCreate,
                icon: const Icon(Icons.add),
                label: const Text('New stock journal'),
              )
            : null,
        body: loadBody<List<dynamic>>(
          future: _load,
          what: 'accounts',
          builder: _content,
        ),
      ),
    );
  }

  Widget _content(List<dynamic> data) {
    final reconciliation = mapOf(data[0]);
    final journals = asRows(data[1]);
    final valuation = mapOf(data[2]);
    return TabBarView(
      children: [
        refreshList([
          sectionHeading(
            'Stock reconciliation',
            'Compare inventory quantities and accounting ledgers',
          ),
          _mapSummary(reconciliation),
        ], padding: const EdgeInsets.all(14)),
        refreshList([
          sectionHeading(
            'Godown stock valuation',
            'Inventory value grouped by godown',
          ),
          _mapSummary(valuation),
        ], padding: const EdgeInsets.all(14)),
        cardList<Map<String, dynamic>>(
          journals,
          emptyTitle: 'No stock journals',
          emptyMessage: 'Transfers, shortages, and surplus adjustments.',
          itemBuilder: (journal) => recordCard(journal, [
            'journalNo',
            'journalType',
            'type',
            'id',
          ], icon: Icons.menu_book_outlined),
        ),
      ],
    );
  }

  Widget _mapSummary(Map<String, dynamic> value) {
    final entries = value.entries
        .where((e) => e.value is num || e.value is String)
        .take(8)
        .toList();
    if (entries.isEmpty) return hintText('No summary values available');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries)
          SizedBox(
            width: 165,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldLabel(e.key),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _journalCreate() async {
    try {
      int? itemId, warehouseId, toWarehouseId;
      String type = 'TRANSFER';
      final items =
          (await ref.read(inventoryRepositoryProvider).getItems(limit: 500))
              .items;
      final warehouses = await ref
          .read(inventoryRepositoryProvider)
          .getWarehouses();
      if (!mounted) return;
      final quantity = TextEditingController();
      final notes = TextEditingController();
      final key = GlobalKey<FormState>();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Create stock journal'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: key,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Journal type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'TRANSFER',
                            child: Text('Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'SHORTAGE',
                            child: Text('Shortage'),
                          ),
                          DropdownMenuItem(
                            value: 'SURPLUS',
                            child: Text('Surplus'),
                          ),
                        ],
                        onChanged: (v) => setModal(() => type = v ?? type),
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Item'),
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
                        validator: (v) => v == null ? 'Select an item' : null,
                      ),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Warehouse',
                        ),
                        items: [
                          for (final w in warehouses)
                            DropdownMenuItem(value: w.id, child: Text(w.name)),
                        ],
                        onChanged: (v) => setModal(() => warehouseId = v),
                        validator: (v) =>
                            v == null ? 'Select a warehouse' : null,
                      ),
                      if (type == 'TRANSFER')
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Destination warehouse',
                          ),
                          items: [
                            for (final w in warehouses.where(
                              (w) => w.id != warehouseId,
                            ))
                              DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                          ],
                          onChanged: (v) => setModal(() => toWarehouseId = v),
                          validator: (v) =>
                              v == null ? 'Select destination' : null,
                        ),
                      TextFormField(
                        controller: quantity,
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
                        controller: notes,
                        decoration: const InputDecoration(
                          labelText: 'Reason / notes',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter the adjustment reason'
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
                child: const Text('Create journal'),
              ),
            ],
          ),
        ),
      );
      if (save != true || itemId == null || warehouseId == null) return;
      await mutate(
        () => ref.read(inventoryRepositoryProvider).createStockJournal({
          'journalType': type,
          'itemId': itemId,
          'warehouseId': warehouseId,
          if (toWarehouseId != null) 'toWarehouseId': toWarehouseId,
          'quantity': num.parse(quantity.text),
          'notes': notes.text.trim(),
        }),
        'Stock journal created',
      );
    } catch (e) {
      showError(e);
    }
  }
}
