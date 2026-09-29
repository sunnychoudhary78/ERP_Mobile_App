import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

/// Lots become sellable after the send-for-selling request is approved.
class InventorySellableScreen extends ConsumerStatefulWidget {
  const InventorySellableScreen({super.key});

  @override
  ConsumerState<InventorySellableScreen> createState() =>
      _InventorySellableScreenState();
}

class _InventorySellableScreenState
    extends ConsumerState<InventorySellableScreen>
    with InventoryUiHelpers<InventorySellableScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() => asList(
    ref.read(inventoryRepositoryProvider).getLots(limit: 500),
  );

  @override
  void reload() => setState(() => _load = _fetch());

  String _status(Map<String, dynamic> lot) =>
      pickText(lot, ['status']).toUpperCase();

  bool _isSellable(Map<String, dynamic> lot) =>
      {'SELLING', 'SELLING_APPROVAL_PENDING'}.contains(_status(lot));

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Sellable Inventory'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'All lots'),
            Tab(text: 'Ready to sell'),
            Tab(text: 'Pending approval'),
          ],
        ),
      ),
      body: loadBody<List<dynamic>>(
        future: _load,
        what: 'sellable inventory',
        builder: (rawLots) {
          final lots = rawLots.map(mapOf).where(_isSellable).toList();
          final ready = lots.where((l) => _status(l) == 'SELLING').toList();
          final pending = lots
              .where((l) => _status(l) == 'SELLING_APPROVAL_PENDING')
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lots appear here after Send for sale is approved.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to sell lots can be dispatched through Stock OUT or Sales orders.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _lotList(lots, empty: 'No sellable lots yet.'),
                    _lotList(ready, empty: 'No lots are ready to sell.'),
                    _lotList(
                      pending,
                      empty: 'No sellable lots are waiting for approval.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _lotList(List<Map<String, dynamic>> lots, {required String empty}) {
    if (lots.isEmpty) return messageList('Nothing to show', empty);
    return refreshList([for (final lot in lots) _lotCard(lot)]);
  }

  Widget _lotCard(Map<String, dynamic> lot) {
    final item = mapOf(lot['item']);
    final status = _status(lot);
    final name = pickText(item, ['name'], fallback: 'Item');
    final lotNo = pickText(
      lot,
      ['lotNumber'],
      fallback: 'Lot #${lot['id'] ?? lot['lotId'] ?? '—'}',
    );
    final grades = lot['grades'] is List
        ? (lot['grades'] as List)
              .whereType<Map>()
              .map((g) => '${g['grade'] ?? 'Grade'}: ${g['availableQty'] ?? g['quantity'] ?? 0}')
              .join(' · ')
        : '';
    final pending = status == 'SELLING_APPROVAL_PENDING';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(pending ? Icons.hourglass_top : Icons.sell_outlined),
        ),
        title: Text(name),
        subtitle: Text(
          '$lotNo\nAvailable: ${lot['availableQty'] ?? lot['rawQty'] ?? 0}'
          '${grades.isEmpty ? '' : '\n$grades'}',
        ),
        isThreeLine: grades.isNotEmpty,
        trailing: Chip(
          label: Text(pending ? 'Pending approval' : 'Ready to sell'),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
