import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryLegacyProductionScreen extends ConsumerStatefulWidget {
  const InventoryLegacyProductionScreen({super.key});

  @override
  ConsumerState<InventoryLegacyProductionScreen> createState() => _InventoryLegacyProductionScreenState();
}

class _InventoryLegacyProductionScreenState extends ConsumerState<InventoryLegacyProductionScreen>
    with InventoryUiHelpers<InventoryLegacyProductionScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    final auth = ref.read(authProvider);
    return asList(
      auth.canAny(const [
            AppPermissions.productionView,
            AppPermissions.productionOrderView,
            AppPermissions.productionPlanningManage,
          ])
          ? repo.getLegacyProductionOrders()
          : Future.value(<dynamic>[]),
    );
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final canCreate = ref
        .watch(authProvider)
        .can(AppPermissions.productionPlanningManage);
    return Scaffold(
      appBar: AppBar(title: const Text('Production orders')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _productionCreate,
              icon: const Icon(Icons.add),
              label: const Text('New production order'),
            )
          : null,
      body: loadBody<List<dynamic>>(
        future: _load,
        what: 'production orders',
        builder: (rows) => cardList<dynamic>(
          rows,
          emptyTitle: 'No production orders',
          emptyMessage: 'Legacy inventory production orders appear here.',
          itemBuilder: _orderCard,
        ),
      ),
    );
  }

  Widget _orderCard(dynamic raw) {
    final row = mapOf(raw);
    final status = pickText(row, ['status']);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.precision_manufacturing_outlined),
        ),
        title: Text(
          pickText(row, [
            'orderNo',
            'productionOrderNo',
          ], fallback: 'Production order #${row['id']}'),
        ),
        subtitle: Text(
          '${pickText(mapOf(row['item']), ['name'], fallback: pickText(row, ['itemName']))}  •  Qty ${pickText(row, ['quantity'], fallback: '0')}  •  $status',
        ),
        trailing: status.toUpperCase() != 'COMPLETED'
            ? TextButton(
                onPressed: () => _productionComplete(row),
                child: const Text('Complete'),
              )
            : null,
      ),
    );
  }

  Future<void> _productionCreate() async {
    try {
      final items =
          (await ref.read(inventoryRepositoryProvider).getItems(limit: 500))
              .items;
      if (!mounted) return;
      int? itemId;
      final quantity = TextEditingController();
      final key = GlobalKey<FormState>();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('New production order'),
            content: Form(
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
                  if (key.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );
      if (save != true || itemId == null) return;
      await mutate(
        () => ref
            .read(inventoryRepositoryProvider)
            .createLegacyProductionOrder(
              itemId: itemId!,
              quantity: num.parse(quantity.text),
            ),
        'Production order created',
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _productionComplete(Map<String, dynamic> row) async {
    try {
      final warehouses = await ref
          .read(inventoryRepositoryProvider)
          .getWarehouses();
      if (!mounted) return;
      int? rm, fg;
      final workOrder = TextEditingController();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Complete production order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Raw material warehouse (optional)',
                  ),
                  items: [
                    for (final w in warehouses)
                      DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ],
                  onChanged: (v) => rm = v,
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Finished goods warehouse (optional)',
                  ),
                  items: [
                    for (final w in warehouses)
                      DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ],
                  onChanged: (v) => fg = v,
                ),
                TextField(
                  controller: workOrder,
                  decoration: const InputDecoration(
                    labelText: 'Work order ID (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Complete'),
              ),
            ],
          ),
        ),
      );
      if (save != true) return;
      await mutate(
        () => ref
            .read(inventoryRepositoryProvider)
            .completeLegacyProductionOrder(
              toInt(row['id']),
              rmWarehouse: rm,
              fgWarehouse: fg,
              workOrderId: workOrder.text.trim().isEmpty
                  ? null
                  : workOrder.text.trim(),
            ),
        'Production order completed',
      );
    } catch (e) {
      showError(e);
    }
  }
}
