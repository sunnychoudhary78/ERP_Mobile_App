import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_lots_screen.dart';
import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/repository/production_repository.dart';
import 'package:erp_app/features/production/presentation/screens/work_order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

/// A focused view of processed lot balances and work orders that produce FG.
class InventoryProcessedFgScreen extends ConsumerStatefulWidget {
  const InventoryProcessedFgScreen({super.key});

  @override
  ConsumerState<InventoryProcessedFgScreen> createState() =>
      _InventoryProcessedFgScreenState();
}

class _InventoryProcessedFgScreenState
    extends ConsumerState<InventoryProcessedFgScreen>
    with InventoryUiHelpers<InventoryProcessedFgScreen> {
  late Future<List<dynamic>> _lots;
  late Future<List<WorkOrder>> _workOrders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _lots = asList(ref.read(inventoryRepositoryProvider).getLots(limit: 500));
    _workOrders = ref
        .read(productionRepositoryProvider)
        .getWorkOrders(limit: 200)
        .then((page) => page.items);
  }

  @override
  void reload() => setState(_load);

  num _quantity(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Processed lots & FG'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Processed lots'),
            Tab(text: 'FG work orders'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processed quantities are tracked by lot. Finished goods work orders show production status; open a work order for QC and completion actions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const InventoryLotsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Manage lot processing'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                loadBody<List<dynamic>>(
                  future: _lots,
                  what: 'processed lots',
                  builder: (rawLots) {
                    final processedLots = rawLots.map(mapOf).where((lot) {
                      return _quantity(lot['processedQty']) > 0 ||
                          _quantity(lot['processingQty']) > 0;
                    }).toList();
                    return _processedLotList(processedLots);
                  },
                ),
                loadBody<List<WorkOrder>>(
                  future: _workOrders,
                  what: 'finished goods work orders',
                  builder: _workOrderList,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _processedLotList(List<Map<String, dynamic>> lots) {
    if (lots.isEmpty) {
      return messageList(
        'No processed lots yet',
        'Start processing a received lot from Inventory lots. Completed output will appear here.',
      );
    }
    return refreshList([
      for (final lot in lots)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: const CircleAvatar(
              child: Icon(Icons.precision_manufacturing_outlined),
            ),
            title: Text(
              pickText(
                mapOf(lot['item']),
                ['name'],
                fallback: pickText(lot, ['lotNumber'], fallback: 'Inventory lot'),
              ),
            ),
            subtitle: Text(
              '${pickText(lot, ['lotNumber'], fallback: 'Lot #${lot['id'] ?? lot['lotId'] ?? '—'}')} · ${pickText(lot, ['status'], fallback: 'Status unavailable')}',
            ),
            children: [
              _quantityRow('Raw quantity', lot['rawQty']),
              _quantityRow('In processing', lot['processingQty']),
              _quantityRow('Processed quantity', lot['processedQty']),
              _quantityRow('Available quantity', lot['availableQty']),
              if (lot['grades'] is List)
                for (final grade in (lot['grades'] as List).whereType<Map>())
                  _quantityRow(
                    '${grade['grade'] ?? 'Grade'} available',
                    grade['availableQty'] ?? grade['quantity'],
                  ),
            ],
          ),
        ),
    ]);
  }

  Widget _quantityRow(String label, dynamic value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text('${value ?? 0}'),
  );

  Widget _workOrderList(List<WorkOrder> orders) {
    if (orders.isEmpty) {
      return messageList(
        'No FG work orders found',
        'Production work orders that create finished goods will appear here.',
      );
    }
    return refreshList([
      for (final order in orders)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.inventory_2_outlined),
            ),
            title: Text(order.itemName ?? order.woNumber ?? 'Work order'),
            subtitle: Text(
              '${order.woNumber ?? 'Work order #${order.id}'} · Qty ${order.quantity ?? 0} · ${order.status ?? 'Status unavailable'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: order.id.isEmpty
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorkOrderDetailScreen(
                        workOrderId: order.id,
                      ),
                    ),
                  ),
          ),
        ),
    ]);
  }
}
