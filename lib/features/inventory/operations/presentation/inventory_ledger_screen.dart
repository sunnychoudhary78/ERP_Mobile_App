import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryLedgerScreen extends ConsumerStatefulWidget {
  const InventoryLedgerScreen({super.key});

  @override
  ConsumerState<InventoryLedgerScreen> createState() =>
      _InventoryLedgerScreenState();
}

class _InventoryLedgerScreenState extends ConsumerState<InventoryLedgerScreen>
    with InventoryUiHelpers<InventoryLedgerScreen> {
  String _direction = '';
  String _type = '';
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() => asList(
    ref
        .read(inventoryRepositoryProvider)
        .getTransactions(direction: _direction, type: _type),
  );

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock ledger')),
      body: Column(
        children: [
          pageHeader(
            title: 'Movement ledger',
            subtitle: 'Review stock changes by direction and movement type.',
            icon: Icons.menu_book_outlined,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .65),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: scheme.primary, size: 19),
                        const SizedBox(width: 8),
                        Text(
                          'Filter movements',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_direction.isNotEmpty || _type.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _direction = '';
                              _type = '';
                              _load = _fetch();
                            }),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _direction,
                            decoration: const InputDecoration(
                              labelText: 'Direction',
                              prefixIcon: Icon(Icons.compare_arrows),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('All directions'),
                              ),
                              DropdownMenuItem(
                                value: 'in',
                                child: Text('Stock in'),
                              ),
                              DropdownMenuItem(
                                value: 'out',
                                child: Text('Stock out'),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              _direction = v ?? '';
                              _load = _fetch();
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Movement type',
                              prefixIcon: Icon(Icons.swap_horiz),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('All types'),
                              ),
                              DropdownMenuItem(
                                value: 'STOCK_IN',
                                child: Text('Stock in'),
                              ),
                              DropdownMenuItem(
                                value: 'STOCK_OUT',
                                child: Text('Stock out'),
                              ),
                              DropdownMenuItem(
                                value: 'STOCK_TRANSFER',
                                child: Text('Transfer'),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              _type = v ?? '';
                              _load = _fetch();
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: loadBody<List<dynamic>>(
              future: _load,
              what: 'ledger',
              builder: (entries) => entries.isEmpty
                  ? messageList(
                      'No movements found',
                      'Try changing the ledger filters.',
                    )
                  : refreshList(
                      [for (final entry in entries) _movementCard(entry)],
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementCard(dynamic raw) {
    final row = mapOf(raw);
    final scheme = Theme.of(context).colorScheme;
    final outgoing = pickText(row, ['direction']).toUpperCase() == 'OUT';
    final quantity = pickText(row, ['quantity'], fallback: '0');
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: outgoing
                    ? scheme.errorContainer
                    : scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                outgoing ? Icons.south_east : Icons.north_east,
                color: outgoing
                    ? scheme.onErrorContainer
                    : scheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickText(row, ['itemName'], fallback: 'Inventory movement'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pickText(row, ['type'])}  ·  ${pickText(row, ['warehouseName'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fmtDate(row['createdAt']),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${outgoing ? '−' : '+'}$quantity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: outgoing ? scheme.error : scheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
