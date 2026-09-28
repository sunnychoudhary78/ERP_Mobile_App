import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryLotsScreen extends ConsumerStatefulWidget {
  const InventoryLotsScreen({super.key});

  @override
  ConsumerState<InventoryLotsScreen> createState() => _InventoryLotsScreenState();
}

class _InventoryLotsScreenState extends ConsumerState<InventoryLotsScreen>
    with InventoryUiHelpers<InventoryLotsScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() =>
      asList(ref.read(inventoryRepositoryProvider).getLots());

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canAdd =
        auth.can(AppPermissions.inventoryManage) ||
        auth.can(AppPermissions.lotProcessingProcess);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory lots')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _allocateDirectStock,
              icon: const Icon(Icons.add),
              label: const Text('Allocate stock'),
            )
          : null,
      body: loadBody<List<dynamic>>(
        future: _load,
        what: 'lots',
        builder: (lots) => refreshList([
          pageHeader(
            title: 'Inventory lots',
            subtitle: 'Track stock from receipt through processing and sale.',
            icon: Icons.inventory_2_outlined,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              countBadge('Lots', lots.length, icon: Icons.layers_outlined),
              countBadge(
                'In processing',
                lots.where((raw) {
                  final lot = mapOf(raw);
                  return (num.tryParse('${lot['processingQty'] ?? 0}') ?? 0) >
                      0;
                }).length,
                icon: Icons.precision_manufacturing_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lots.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 34,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No inventory lots yet',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Received and processed lots will appear here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final raw in lots) _lotCard(mapOf(raw)),
        ]),
      ),
    );
  }

  Widget _lotCard(Map<String, dynamic> lot) {
    final item = mapOf(lot['item']);
    final id = toInt(lot['id'] ?? lot['lotId']);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: scheme.primary),
        ),
        title: Text(
          pickText(item, [
            'name',
          ], fallback: pickText(lot, ['lotNumber'], fallback: 'Lot #$id')),
        ),
        subtitle: Text(
          '${pickText(lot, ['lotNumber'], fallback: 'Lot #$id')}  •  ${pickText(lot, ['status'], fallback: '—')}\nAvailable: ${pickText(lot, ['availableQty'], fallback: '0')} units',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (ref.read(authProvider).can(AppPermissions.lotProcessingProcess))
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _startProcessing(lot),
                    icon: const Icon(Icons.precision_manufacturing_outlined),
                    label: const Text('Start processing'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _sendForSelling(lot),
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('Send for sale'),
                  ),
                  TextButton(
                    onPressed: () => _showLotSummary(id),
                    child: const Text('Lot details'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _allocateDirectStock() async {
    try {
      final items =
          (await ref.read(inventoryRepositoryProvider).getItems(limit: 500))
              .items;
      final warehouses = await ref
          .read(inventoryRepositoryProvider)
          .getWarehouses();
      if (!mounted) return;
      int? itemId, warehouseId;
      String destination = 'processed';
      final qty = TextEditingController();
      final note = TextEditingController();
      final key = GlobalKey<FormState>();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Allocate direct stock'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: [
                        for (final item in items)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setModal(() => itemId = v),
                      validator: (v) => v == null ? 'Select a product' : null,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Warehouse'),
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w.id, child: Text(w.name)),
                      ],
                      onChanged: (v) => setModal(() => warehouseId = v),
                      validator: (v) => v == null ? 'Select a warehouse' : null,
                    ),
                    TextFormField(
                      controller: qty,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Enter a positive quantity'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: destination,
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
                      onChanged: (v) =>
                          setModal(() => destination = v ?? destination),
                    ),
                    TextFormField(
                      controller: note,
                      decoration: const InputDecoration(
                        labelText: 'Reason / note',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'A note is required'
                          : null,
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
                  if (key.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Allocate'),
              ),
            ],
          ),
        ),
      );
      if (save != true || itemId == null || warehouseId == null) return;
      await ref.read(inventoryRepositoryProvider).allocateDirectStock({
        'itemId': itemId,
        'warehouseId': warehouseId,
        'quantity': num.parse(qty.text),
        'destination': destination,
        'noteMessage': note.text.trim(),
      });
      showSuccess('Stock allocated');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _startProcessing(Map<String, dynamic> lot) async {
    final id = toInt(lot['id'] ?? lot['lotId']);
    final qty = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start processing'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available raw quantity: ${lot['rawQty'] ?? lot['availableQty'] ?? 0}',
              ),
              TextFormField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Input quantity'),
                validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive quantity'
                    : null,
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
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
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).startLotProcessing(id, {
        'inputQty': num.parse(qty.text),
        if (note.text.trim().isNotEmpty) 'noteMessage': note.text.trim(),
      });
      showSuccess('Processing started');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _sendForSelling(Map<String, dynamic> lot) async {
    final id = toInt(lot['id'] ?? lot['lotId']);
    final grades = (lot['grades'] is List ? lot['grades'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final quantity = TextEditingController(
      text: '${lot['rawQty'] ?? lot['availableQty'] ?? ''}',
    );
    String? grade = grades.isEmpty ? null : '${grades.first['grade'] ?? ''}';
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Send lot for sale'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select the quantity to make sellable.'),
                if (grades.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: const InputDecoration(labelText: 'Grade'),
                    items: [
                      for (final g in grades)
                        DropdownMenuItem(
                          value: '${g['grade']}',
                          child: Text(
                            '${g['grade']} (available: ${g['availableQty'] ?? g['quantity'] ?? 0})',
                          ),
                        ),
                    ],
                    onChanged: (v) => setModal(() => grade = v),
                  ),
                TextFormField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Enter a positive quantity'
                      : null,
                ),
              ],
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
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (submit != true) return;
    final qty = num.parse(quantity.text);
    final body = grades.isEmpty
        ? {'rawQty': qty}
        : {
            'grades': [
              {'grade': grade, 'quantity': qty},
            ],
          };
    try {
      await ref.read(inventoryRepositoryProvider).sendLotForSelling(id, body);
      showSuccess('Lot sent for sale');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _showLotSummary(int id) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.getLotSummary(id),
        repo.getLotProcessings(id),
      ]);
      if (!mounted) return;
      final summary = results[0] as Map<String, dynamic>;
      final batches = results[1] as List<dynamic>;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final key in ['rawQty', 'processingQty', 'processedQty'])
                  ListTile(
                    title: Text(key.replaceAll('Qty', ' quantity')),
                    trailing: Text('${summary[key] ?? 0}'),
                  ),
                const Divider(),
                const Text(
                  'Processing batches',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (batches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No batches yet'),
                  ),
                for (final batch in batches)
                  ListTile(
                    title: Text(
                      pickText(mapOf(batch), [
                        'batchNumber',
                      ], fallback: 'Batch #${mapOf(batch)['id']}'),
                    ),
                    subtitle: Text(
                      '${pickText(mapOf(batch), ['status'])}  •  Input ${pickText(mapOf(batch), ['inputQty'], fallback: '0')}',
                    ),
                    trailing: pickText(mapOf(batch), ['status']) == 'IN_PROGRESS'
                        ? TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _completeProcessing(mapOf(batch));
                            },
                            child: const Text('Complete'),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _completeProcessing(Map<String, dynamic> batch) async {
    final grade = TextEditingController(text: 'A');
    final qty = TextEditingController();
    final cost = TextEditingController(text: '0');
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete processing batch'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: grade,
                decoration: const InputDecoration(labelText: 'Grade'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a grade' : null,
              ),
              TextFormField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Output quantity'),
                validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive quantity'
                    : null,
              ),
              TextField(
                controller: cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Processing cost'),
              ),
            ],
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
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).completeLotProcessing(
        toInt(batch['id']),
        {
          'grades': [
            {'grade': grade.text.trim(), 'quantity': num.parse(qty.text)},
          ],
          'processingCost': num.tryParse(cost.text) ?? 0,
        },
      );
      showSuccess('Processing completed');
    } catch (e) {
      showError(e);
    }
  }
}
