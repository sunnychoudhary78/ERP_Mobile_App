import 'dart:io';

import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'inventory_ui_helpers.dart';

/// Web: /inventory/reports  →  Overview | Cost & P/L | Stock on Hand | Movements | Lot Exports
/// API doc section 17 (+ 4 dashboard, 13 lots, 16 movement ledger).
const _periods = <String, String>{
  '1': 'Last 1 Month',
  '3': 'Last 3 Months',
  '6': 'Last 6 Months',
  '12': 'Last 12 Months',
  'all': 'All Time',
};

class InventoryReportsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const InventoryReportsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends ConsumerState<InventoryReportsScreen>
    with InventoryUiHelpers<InventoryReportsScreen> {
  String _months = '12';
  String _direction = 'all'; // all | in | out

  // Each tab loads on its own, so one failing/forbidden API doesn't kill the whole screen.
  late Future<List<dynamic>> _overview;
  late Future<Map<String, dynamic>> _financial;
  late Future<List<dynamic>> _stock;
  late Future<List<dynamic>> _moves;
  late Future<List<dynamic>> _lots;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _overview = _fetchOverview();
    _financial = _fetchFinancial();
    _stock = _fetchStock();
    _moves = _fetchMoves();
    _lots = _fetchLots();
  }

  Future<List<dynamic>> _fetchOverview() {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /dashboard/stats + GET /inventory/low-stock
    return Future.wait<dynamic>([repo.getDashboardStats(), repo.getLowStockItems()]);
  }

  Future<Map<String, dynamic>> _fetchFinancial() async {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /inventory/reports/financial?months=1|3|6|12|all
    final res = await repo.getFinancialReport(months: _months);
    return Map<String, dynamic>.from(res.raw as Map);
  }

  Future<List<dynamic>> _fetchStock() async {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /inventory/report
    return List<dynamic>.from(await repo.getStockReport());
  }

  Future<List<dynamic>> _fetchMoves() async {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /inventory/transactions (doc: limit max 500). Direction filtered client-side.
    return List<dynamic>.from(await repo.getTransactions(limit: 200));
  }

  Future<List<dynamic>> _fetchLots() async {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /lot?page=1&limit=500  (doc section 13.1)
    // TODO: rename to whatever your Lots screen already calls in the repository.
    return List<dynamic>.from(await repo.getLots());
  }

  @override
  void reload() => setState(_loadAll);

  // ───────────────────────── helpers ─────────────────────────

  num _num(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);

  dynamic _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null) return m[k];
    }
    return null;
  }

  dynamic _safe(dynamic Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  String _money(dynamic v) => '₹${fmtMoney(v)}';

  String _csvCell(dynamic v) {
    final s = '${v ?? ''}';
    return s.contains(',') || s.contains('"') || s.contains('\n')
        ? '"${s.replaceAll('"', '""')}"'
        : s;
  }

  Future<void> _exportCsv(String fileName, List<List<dynamic>> rows) async {
    try {
      final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\n');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab.clamp(0, 4).toInt(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory reports'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Cost & P/L'),
              Tab(text: 'Stock on Hand'),
              Tab(text: 'Movements'),
              Tab(text: 'Lot Exports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            loadBody<List<dynamic>>(future: _overview, what: 'overview', builder: _overviewTab),
            loadBody<Map<String, dynamic>>(future: _financial, what: 'cost & P/L', builder: _plTab),
            loadBody<List<dynamic>>(future: _stock, what: 'stock report', builder: _stockTab),
            loadBody<List<dynamic>>(future: _moves, what: 'movements', builder: _movementsTab),
            loadBody<List<dynamic>>(future: _lots, what: 'lots', builder: _lotsTab),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 1. Overview ─────────────────────────

  Widget _overviewTab(List<dynamic> data) {
    final dashboard = data[0];
    final low = data[1] as List<dynamic>;

    // Optional dashboard fields from doc 4.1 — shown only if your DashboardStats model has them.
    final productsWithStock = _safe(() => (dashboard as dynamic).productsWithStock);
    final in30 = _safe(() => (dashboard as dynamic).movementIn30d);
    final out30 = _safe(() => (dashboard as dynamic).movementOut30d);

    Widget pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]),
    );

    return refreshList([
      sectionHeading('Inventory overview', 'Current stock, lots and recent activity'),
      pair(
        metricCard('Units in stock', '${dashboard.stockCount}', Icons.inventory_outlined),
        metricCard('Lots', '${dashboard.lotsCount}', Icons.layers_outlined),
      ),
      pair(
        metricCard(
          'Products with stock',
          productsWithStock == null ? '—' : '$productsWithStock',
          Icons.inventory_2_outlined,
        ),
        metricCard('Low stock', '${low.length}', Icons.warning_amber_outlined),
      ),
      if (in30 != null || out30 != null)
        pair(
          metricCard('Stock in (30d)', '${in30 ?? 0}', Icons.south_west),
          metricCard('Stock out (30d)', '${out30 ?? 0}', Icons.north_east),
        ),
      const SizedBox(height: 6),
      sectionHeading('Low stock', 'Items at or below their reorder level'),
      if (low.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No low stock items'),
        )
      else
        ...low.take(8).map(
          (item) => dataCard(
            title: '${item.name} (${item.sku})',
            subtitle: 'Reorder level: ${item.reorderLevel ?? '—'}',
            amount: '${item.currentStock} units',
            icon: Icons.warning_amber_outlined,
          ),
        ),
    ], padding: const EdgeInsets.all(16));
  }

  // ───────────────────────── 2. Cost & P/L ─────────────────────────

  Widget _kpi(String title, String value, String sub, Color tint) {
    return Card(
      color: tint,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .4),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _plTab(Map<String, dynamic> f) {
    final label = _periods[_months] ?? _months;
    final net = _num(f['netProfitEstimate']);
    final products = ((f['byProduct'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    Widget pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]),
    );

    return refreshList([
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _months,
                  items: _periods.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null || v == _months) return;
                    setState(() {
                      _months = v;
                      _financial = _fetchFinancial();
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _exportPl(f, products),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export P/L CSV'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      pair(
        _kpi('Purchase cost', _money(f['purchaseCost']), '${f['purchaseCount'] ?? 0} received POs',
            const Color(0xFFFFF8EE)),
        _kpi('Stock out sales', _money(f['stockOutSubtotal']),
            'GST ${_money(f['stockOutGst'])} · ${f['stockOutQty'] ?? 0} units', const Color(0xFFF1F4FF)),
      ),
      pair(
        _kpi('COGS (stock out)', _money(f['stockOutCogs']),
            'Gross profit ${_money(f['stockOutGrossProfit'])}', const Color(0xFFFFF8EE)),
        _kpi('Total revenue (ex GST)', _money(f['totalRevenueExGst']),
            'With GST ${_money(f['totalRevenueWithGst'])}', const Color(0xFFF1F4FF)),
      ),
      pair(
        _kpi('Estimated net P/L', _money(f['netProfitEstimate']),
            '${net >= 0 ? 'Earned more than spent' : 'Spent more than earned'} · $label',
            net >= 0 ? const Color(0xFFEBFAF3) : const Color(0xFFFFEFEF)),
        _kpi('Inventory on hand', _money(f['inventoryValueAtCost']),
            '${f['inventoryUnits'] ?? 0} units · B2B ${_money(f['inventoryValueAtB2b'])}',
            const Color(0xFFF1F4FF)),
      ),
      const SizedBox(height: 6),
      sectionHeading('Product-wise cost, revenue & profit', '${products.length} products · $label'),
      if (products.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('No product P/L rows for this period'))
      else
        ...products.map(_productPlCard),
    ], padding: const EdgeInsets.all(16));
  }

  // byProduct[] keys are not spelled out in the API doc, so several likely names are tried.
  // Print one row (debugPrint(products.first.toString())) and trim these lists to the real keys.
  Map<String, dynamic> _plRow(Map<String, dynamic> p) {
    final revenue = _num(_pick(p, ['outRevenue', 'stockOutRevenue', 'stockOutSubtotal', 'revenue']));
    final profit = _num(_pick(p, ['profit', 'grossProfit', 'stockOutGrossProfit']));
    final marginRaw = _pick(p, ['marginPct', 'marginPercent', 'margin']);
    return {
      'name': _pick(p, ['productName', 'name', 'itemName']) ?? '—',
      'sku': _pick(p, ['sku', 'productSku', 'itemSku']) ?? '',
      'onHand': _num(_pick(p, ['onHand', 'currentStock', 'stock', 'quantity'])),
      'cost': _num(_pick(p, ['costPrice', 'unitCost', 'cost'])),
      'b2bPrice': _num(_pick(p, ['b2bPrice', 'b2b_price', 'sellingPrice'])),
      'stockValue': _num(_pick(p, [
        'stockValueAtCost',
        'stockValue',
        'inventoryValue',
        'inventoryValueAtCost',
      ])),
      'stockValueB2b': _num(_pick(p, [
        'stockValueAtB2b',
        'stockValueAtB2B',
        'stockValueB2b',
        'inventoryValueAtB2b',
        'b2bStockValue',
      ])),
      'outQty': _num(_pick(p, [
        'outQty',
        'stockOutQty',
        'stockOutQuantity',
        'outQuantity',
        'soldQty',
      ])),
      'outRevenue': revenue,
      'cogs': _num(_pick(p, ['cogs', 'stockOutCogs'])),
      'profit': profit,
      'margin': marginRaw != null ? _num(marginRaw) : (revenue > 0 ? profit / revenue * 100 : 0),
    };
  }

  Widget _stat(String label, String value, {Color? color}) {
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _productPlCard(Map<String, dynamic> raw) {
    final r = _plRow(raw);
    final profit = r['profit'] as num;
    final profitColor = profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r['name']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _stat('On hand', '${r['onHand']}'),
                _stat('Cost', _money(r['cost'])),
                _stat('Stock value', _money(r['stockValue'])),
                _stat('Out qty', '${r['outQty']}'),
                _stat('Out revenue', _money(r['outRevenue'])),
                _stat('COGS', _money(r['cogs'])),
                _stat('Profit', _money(profit), color: profitColor),
                _stat('Margin', '${(r['margin'] as num).round()}%', color: profitColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPl(Map<String, dynamic> f, List<Map<String, dynamic>> products) {
    final rows = <List<dynamic>>[
      ['Period', _periods[_months] ?? _months],
      ['Purchase cost', f['purchaseCost']],
      ['Stock out sales', f['stockOutSubtotal']],
      ['Stock out GST', f['stockOutGst']],
      ['Stock out quantity', f['stockOutQty']],
      ['COGS (stock out)', f['stockOutCogs']],
      ['Gross profit', f['stockOutGrossProfit']],
      ['Total revenue (ex GST)', f['totalRevenueExGst']],
      ['Total revenue (with GST)', f['totalRevenueWithGst']],
      ['Estimated net P/L', f['netProfitEstimate']],
      ['Inventory on hand (at cost)', f['inventoryValueAtCost']],
      ['Inventory units', f['inventoryUnits']],
      ['Inventory on hand (B2B)', f['inventoryValueAtB2b']],
      [],
      [
        'Product',
        'SKU',
        'On hand',
        'Cost price',
        'B2B price',
        'Stock value at cost',
        'Stock value at B2B',
        'Stock out quantity',
        'Stock out revenue',
        'Stock out COGS',
        'Stock out gross profit',
        'Margin %',
      ],
      ...products.map((p) {
        final r = _plRow(p);
        return [
          r['name'],
          r['sku'],
          r['onHand'],
          r['cost'],
          r['b2bPrice'],
          r['stockValue'],
          r['stockValueB2b'],
          r['outQty'],
          r['outRevenue'],
          r['cogs'],
          r['profit'],
          (r['margin'] as num).round(),
        ];
      }),
    ];
    return _exportCsv('inventory_pl_$_months.csv', rows);
  }

  // ───────────────────────── 3. Stock on Hand ─────────────────────────

  Widget _stockTab(List<dynamic> stock) {
    return cardList<dynamic>(
      stock,
      emptyTitle: 'No stock report rows',
      emptyMessage: 'On-hand stock compared with reorder level.',
      itemBuilder: _stockReportCard,
    );
  }

  Widget _stockReportCard(dynamic row) {
    final current = (row.currentStock as num).toInt();
    final reorder = (row.reorderLevel as num?)?.toInt();
    final isLow = reorder != null && current <= reorder;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLow ? Colors.orange.shade50 : Colors.green.shade50,
          child: Icon(
            isLow ? Icons.warning_amber : Icons.inventory_2_outlined,
            color: isLow ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(row.name as String),
        subtitle: Text('${row.sku}  •  Reorder at ${reorder ?? '—'}'),
        trailing: Text('$current units', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ───────────────────────── 4. Movements ─────────────────────────

  Widget _movementsTab(List<dynamic> all) {
    final rows = all.where((m) {
      if (_direction == 'all') return true;
      final d = pickText(mapOf(m), ['direction']).toUpperCase();
      return d == _direction.toUpperCase();
    }).toList();

    return refreshList([
      Wrap(
        spacing: 8,
        children: [
          for (final e in const {'all': 'All', 'in': 'Stock in', 'out': 'Stock out'}.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _direction == e.key,
              onSelected: (_) => setState(() => _direction = e.key),
            ),
        ],
      ),
      const SizedBox(height: 10),
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No movements. Stock in and stock out activity appears here.'),
        )
      else
        ...rows.map((movement) {
          final m = mapOf(movement);
          final isOut = pickText(m, ['direction']).toUpperCase() == 'OUT';
          final qty = pickText(m, ['quantity'], fallback: '0');
          final ref = pickText(m, ['referenceNo']);
          return dataCard(
            title: pickText(m, ['itemName'], fallback: 'Stock movement'),
            subtitle: [
              pickText(m, ['type']).replaceAll('_', ' '),
              pickText(m, ['warehouseName']),
              if (ref.isNotEmpty) ref,
              fmtDate(m['createdAt']),
            ].where((s) {
              final value = s.toString().trim();
              return value.isNotEmpty && value != '—' && value != '-';
            }).join('  •  '),
            amount: '$qty units',
            icon: isOut ? Icons.north_east : Icons.south_west,
          );
        }),
    ], padding: const EdgeInsets.all(16));
  }

  // ───────────────────────── 5. Lot Exports ─────────────────────────

  String _nested(Map<String, dynamic> m, String obj, String key) {
    final o = m[obj];
    return o is Map ? '${o[key] ?? ''}' : '';
  }

  Widget _lotsTab(List<dynamic> lots) {
    final maps = lots.map(mapOf).toList();

    return refreshList([
      Row(
        children: [
          Expanded(
            child: sectionHeading('Lot exports', '${maps.length} lots with purchase, processing & profit'),
          ),
          OutlinedButton.icon(
            onPressed: maps.isEmpty ? null : () => _exportLots(maps),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export CSV'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (maps.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('No lots found'))
      else
        ...maps.map((m) {
          final item = _nested(m, 'item', 'name');
          final status = pickText(m, ['status']);
          return dataCard(
            title: pickText(m, ['lotNumber'], fallback: 'Lot'),
            subtitle: '$item  •  $status\n'
                'Purchase ${_money(m['purchaseAmount'])}  •  '
                'Selling ${_money(m['sellingAmount'])}  •  '
                'Profit ${_money(m['profitAmount'])}',
            amount: '${pickText(m, ['availableQty'], fallback: '0')} avail.',
            icon: Icons.layers_outlined,
          );
        }),
    ], padding: const EdgeInsets.all(16));
  }

  Future<void> _exportLots(List<Map<String, dynamic>> lots) {
    final rows = <List<dynamic>>[
      [
        'Lot', 'Item', 'Vendor', 'Warehouse', 'Status', 'Received', 'Raw', 'Processing',
        'Processed', 'Available', 'Purchase amount', 'Processing amount', 'Selling amount', 'Profit',
      ],
      ...lots.map((m) => [
        m['lotNumber'],
        _nested(m, 'item', 'name'),
        _nested(m, 'vendor', 'name'),
        _nested(m, 'warehouse', 'name'),
        m['status'],
        m['receivedQty'],
        m['rawQty'],
        m['processingQty'],
        m['processedQty'],
        m['availableQty'],
        m['purchaseAmount'],
        m['processingAmount'],
        m['sellingAmount'],
        m['profitAmount'],
      ]),
    ];
    return _exportCsv('inventory_lots.csv', rows);
  }
}
