import 'dart:io';
import 'package:erp_app/features/inventory/approval/data/inventory_ledger_screen.dart';
import 'package:erp_app/features/inventory/stocklookup/presentation/screens/inventory_stock_movements_screen.dart';
import 'package:erp_app/features/inventory/purchase/recives/presentation/purchase_received_screen.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../lots/widget/inventory_ui_helpers.dart';

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
  ConsumerState<InventoryReportsScreen> createState() =>
      _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends ConsumerState<InventoryReportsScreen>
    with InventoryUiHelpers<InventoryReportsScreen> {
  String _months = '12';
  String _direction = 'all'; // all | in | out

  // Each tab loads on its own, so one failing/forbidden API doesn't kill the whole screen.
  late Future<(InventoryDashboardStats, List<InventoryItem>)> _overview;
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

  Future<(InventoryDashboardStats, List<InventoryItem>)>
  _fetchOverview() async {
    final repo = ref.read(inventoryRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repo.getDashboardStats(),
      repo.getLowStockItems(),
    ]);
    return (
      results[0] as InventoryDashboardStats,
      results[1] as List<InventoryItem>,
    );
  }

  Future<Map<String, dynamic>> _fetchFinancial() async {
    final repo = ref.read(inventoryRepositoryProvider);
    // GET /inventory/reports/financial?months=1|3|6|12|all
    final res = await repo.getFinancialReport(months: _months);
    return _normalizeFinancial(Map<String, dynamic>.from(res.raw as Map));
  }

  /// The financial API keys are matched loosely (case / underscore insensitive,
  /// unwrapped from `data` / `result` / `report` / `summary`), so Stock value,
  /// Profit and Profit margin no longer show blank/₹0 when the backend uses a
  /// slightly different key name. Missing profit values are derived.
  Map<String, dynamic> _normalizeFinancial(Map<String, dynamic> raw) {
    var src = Map<String, dynamic>.from(raw);
    for (final wrapper in const ['data', 'result', 'report', 'summary']) {
      final w = src[wrapper];
      if (w is Map) src = {...src, ...Map<String, dynamic>.from(w)};
    }

    dynamic pick(List<String> k) => _pickLoose(src, k);
    num n(List<String> k) => _num(pick(k));

    final purchaseCost = n([
      'purchaseCost',
      'totalPurchaseCost',
      'purchaseAmount',
      'totalPurchase',
    ]);
    final sales = n([
      'stockOutSubtotal',
      'stockOutSales',
      'salesSubtotal',
      'totalSales',
      'stockOutRevenue',
      'stockOutAmount',
    ]);
    final cogs = n(['stockOutCogs', 'cogs', 'costOfGoodsSold']);

    final grossRaw = pick(['stockOutGrossProfit', 'grossProfit']);
    final gross = grossRaw != null ? _num(grossRaw) : sales - cogs;

    final revenueRaw = pick([
      'totalRevenueExGst',
      'revenueExGst',
      'totalRevenue',
    ]);
    final revenue = revenueRaw != null ? _num(revenueRaw) : sales;

    final netRaw = pick([
      'netProfitEstimate',
      'netProfit',
      'profitEstimate',
      'netProfitLoss',
      'profit',
    ]);
    final net = netRaw != null ? _num(netRaw) : revenue - purchaseCost;

    // Profit margin % = gross profit / sales (ex GST). API value wins if present.
    final marginRaw = pick([
      'profitMargin',
      'grossMargin',
      'marginPercent',
      'profitMarginPercent',
    ]);
    final marginParsed = marginRaw == null
        ? null
        : num.tryParse('$marginRaw'.replaceAll(RegExp(r'[₹,%\s]'), ''));
    final num? margin =
        marginParsed ?? (sales > 0 ? gross / sales * 100 : null);

    final out = <String, dynamic>{
      ...src,
      'purchaseCost': purchaseCost,
      'purchaseCount': pick(['purchaseCount', 'receivedCount', 'grnCount']) ?? 0,
      'stockOutSubtotal': sales,
      'stockOutBillCount':
          pick(['stockOutBillCount', 'stockOutCount', 'billCount']) ?? 0,
      'stockOutGst': n(['stockOutGst', 'gst', 'gstAmount']),
      'stockOutQty': n(['stockOutQty', 'stockOutQuantity', 'soldQty']),
      'stockOutCogs': cogs,
      'stockOutGrossProfit': gross,
      'totalRevenueExGst': revenue,
      'totalRevenueWithGst': n([
        'totalRevenueWithGst',
        'revenueWithGst',
      ]),
      'netProfitEstimate': net,
      'profitMargin': margin,
      'inventoryValueAtCost': n([
        'inventoryValueAtCost',
        'stockValue',
        'inventoryValue',
        'totalStockValue',
        'stockValueAtCost',
      ]),
      'inventoryValueAtB2b': n([
        'inventoryValueAtB2b',
        'stockValueAtB2b',
        'inventoryValueB2b',
      ]),
      'inventoryUnits': n(['inventoryUnits', 'stockUnits', 'totalUnits']),
    };

    if (kDebugMode) {
      debugPrint('Financial raw keys: ${raw.keys.toList()}');
      debugPrint('Financial normalized: $out');
    }
    return out;
  }

  /// Shows "-" when there is no margin (no sales), like the web.
  String _pct(dynamic v) {
    if (v == null) return '-';
    final n = v is num ? v : num.tryParse('$v'.replaceAll(RegExp(r'[%\s]'), ''));
    return n == null ? '-' : '${n.toStringAsFixed(1)}%';
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

  /// Parses numbers and numeric strings like "1,234.50", "₹1,200" or "12.5%".
  num _num(dynamic v) {
    if (v is num) return v;
    final cleaned = '${v ?? ''}'
        .replaceAll(RegExp(r'[₹,%\s]'), '')
        .replaceAll(',', '');
    return num.tryParse(cleaned) ?? 0;
  }

  String _normKey(String k) =>
      k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Like [_pick], but ignores case / underscores / dashes (so `stock_value`,
  /// `StockValue` and `stockValue` all match) and also looks one level deep
  /// into nested maps (e.g. `{ "item": { "sku": ... } }`).
  /// Top-level keys always win over nested ones.
  dynamic _pickLoose(Map<String, dynamic> m, List<String> keys) {
    final wanted = keys.map(_normKey).toList();

    dynamic scan(Map src) {
      final lookup = <String, dynamic>{};
      src.forEach((k, v) => lookup[_normKey('$k')] = v);
      for (final w in wanted) {
        final v = lookup[w];
        if (v != null && '$v'.trim().isNotEmpty) return v;
      }
      return null;
    }

    final direct = scan(m);
    if (direct != null) return direct;
    for (final v in m.values) {
      if (v is Map) {
        final nested = scan(v);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  num _r2(num v) => num.parse(v.toStringAsFixed(2));

  String _money(dynamic v) => '₹${fmtMoney(_num(v))}';

  // Red is reserved for LOW STOCK.
  static const Color _lowRed = Color(0xFFD32F2F);
  static const Color _lowRedBg = Color(0xFFFFEBEE);

  static const Color _inGreen = Color(0xFF2E7D32);

  static const Color _outOrange = Color(0xFFEF6C00);

  // ───────────────────── CRM-style stat cards ─────────────────────

  /// Decorative upward curve (values 0–1). Inventory APIs only return totals,
  /// so there is no real history to plot. Pass `trend:` if you get real data.
  static const _trendUp = <double>[0.15, 0.22, 0.2, 0.38, 0.35, 0.6, 0.68, 0.9];

  /// CRM-style stat card: grey title, big value, subtitle, sparkline.
  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
    List<double> trend = _trendUp,
  }) {
    return Container(
      height: 134,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const Spacer(),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(painter: _SparklinePainter(trend, accent)),
          ),
        ],
      ),
    );
  }

  /// 2 cards per row (4 on wide screens), correct width regardless of list padding.
  Widget _statGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 12.0;
        final w = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: w, child: c)).toList(),
        );
      },
    );
  }

  Widget _accentCard({
    required String title,
    String? subtitle,
    required String trailing,
    required IconData icon,
    required Color accent,
    required Color tint,
    Color? titleColor,
    String? badge,
    bool emphasize = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,

      // White background for every card.
      color: Colors.white,

      // Neutral border for every card.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black.withOpacity(.05),
              child: Icon(icon, color: emphasize ? _lowRed : accent, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: emphasize ? _lowRed : accent,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: emphasize ? _lowRed : accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _csvCell(dynamic v) {
    final s = '${v ?? ''}';
    return s.contains(',') || s.contains('"') || s.contains('\n')
        ? '"${s.replaceAll('"', '""')}"'
        : s;
  }

  Future<void> _exportCsv(String fileName, List<List<dynamic>> rows) async {
    try {
      final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      // UTF-8 BOM so Excel shows ₹ and non-English product names correctly.
      await file.writeAsString('﻿$csv');
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
            loadBody<(InventoryDashboardStats, List<InventoryItem>)>(
              future: _overview,
              what: 'overview',
              builder: (data) => Builder(
                builder: (tabContext) =>
                    _overviewTab(data.$1, data.$2, tabContext),
              ),
            ),
            loadBody<Map<String, dynamic>>(
              future: _financial,
              what: 'cost & P/L',
              builder: _plTab,
            ),
            loadBody<List<dynamic>>(
              future: _stock,
              what: 'stock report',
              builder: _stockTab,
            ),
            loadBody<List<dynamic>>(
              future: _moves,
              what: 'movements',
              builder: _movementsTab,
            ),
            loadBody<List<dynamic>>(
              future: _lots,
              what: 'lots',
              builder: _lotsTab,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 1. Overview ─────────────────────────

  Widget _overviewTab(
    InventoryDashboardStats dashboard,
    List<InventoryItem> lowStockItems,
    BuildContext tabContext,
  ) {
    final movementTotal = dashboard.movementIn30d + dashboard.movementOut30d;
    final stockInRatio = movementTotal == 0
        ? 0.0
        : dashboard.movementIn30d / movementTotal;

    Widget metricsGrid() {
      return _statGrid([
        _statCard(
          title: 'Units on hand',
          value: '${dashboard.stockCount}',
          subtitle: 'Total pieces in stock',
          accent: const Color(0xFF188A63),
        ),
        _statCard(
          title: 'Products with stock',
          value: '${dashboard.productsWithStock}',
          subtitle: 'SKUs that still have qty',
          accent: const Color(0xFF3974A5),
        ),
        _statCard(
          title: 'Running low',
          value: '${dashboard.lowStockCount}',
          subtitle: 'Below reorder level',
          accent: const Color(0xFFF59E0B),
        ),
        _statCard(
          title: 'GRN batches',
          value: '${dashboard.purchasesCount}',
          subtitle: 'Purchase receive records',
          accent: const Color(0xFF7C3AED),
        ),
      ]);
    }

    Widget financialCards() {
      return FutureBuilder<Map<String, dynamic>>(
        future: _financial,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Could not load financial report: ${snapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          final report = snapshot.data!;
          final period = _periods[_months] ?? 'Last $_months months';
          final expenseCount = report['purchaseCount'] ?? 0;
          final salesCount = report['stockOutBillCount'] ?? 0;
          final netProfit = _num(report['netProfitEstimate']);

          return _statGrid([
            _statCard(
              title: 'Spent on purchases',
              value: _money(report['purchaseCost']),
              subtitle: '$expenseCount received orders · $period',
              accent: const Color(0xFFF59E0B),
            ),
            _statCard(
              title: 'Sales (stock out)',
              value: _money(report['stockOutSubtotal']),
              subtitle: '$salesCount bills · before GST',
              accent: const Color(0xFF2563EB),
            ),
            _statCard(
              title: 'Profit estimate',
              value: _money(report['netProfitEstimate']),
              subtitle:
                  '${netProfit >= 0 ? 'Earned more than spent' : 'Spent more than earned'} · $period',
              accent: netProfit >= 0
                  ? const Color(0xFF188A63)
                  : const Color(0xFFD32F2F),
            ),
            _statCard(
              title: 'Stock value',
              value: _money(report['inventoryValueAtCost']),
              subtitle:
                  'At cost · wholesale ${_money(report['inventoryValueAtB2b'])}',
              accent: const Color(0xFF3974A5),
            ),
            _statCard(
              title: 'Profit margin',
              value: _pct(report['profitMargin']),
              subtitle: 'Gross profit ÷ sales · $period',
              accent: _num(report['profitMargin']) >= 0
                  ? const Color(0xFF188A63)
                  : const Color(0xFFD32F2F),
            ),
            _statCard(
              title: 'Gross profit',
              value: _money(report['stockOutGrossProfit']),
              subtitle: 'Sales minus COGS · $period',
              accent: const Color(0xFF7C3AED),
            ),
          ]);
        },
      );
    }

    Widget stockMovementPanel() {
      return _overviewPanel(
        title: 'Last 30 days — stock in vs out',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stockInRatio,
                minHeight: 10,
                backgroundColor: const Color(0xFFFFE6D7),
                color: const Color(0xFF00B884),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _movementSummary(
                    title: 'Stock in',
                    value: '${dashboard.movementIn30d} units',
                    detail: 'Purchase Received (GRN)',
                    color: const Color(0xFF087A5A),
                    background: const Color(0xFFF0FBF7),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _movementSummary(
                    title: 'Stock out',
                    value: '${dashboard.movementOut30d} units',
                    detail: dashboard.movementOut30d == 0
                        ? 'No Stock OUT bills in the last 30 days'
                        : 'Stock OUT in the last 30 days',
                    color: const Color(0xFFB63D08),
                    background: const Color(0xFFFFF8F2),
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget quickLinksPanel() {
      return _overviewPanel(
        title: 'Quick links',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickLink(
              'Cost & P/L',
              onTap: () => DefaultTabController.of(tabContext).animateTo(1),
            ),
            _quickLink(
              'Movement Ledger',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InventoryLedgerScreen(),
                ),
              ),
            ),
            _quickLink(
              'Purchase Received',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PurchaseReceivedScreen(),
                ),
              ),
            ),
            _quickLink(
              'Stock OUT Bills',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InventoryStockMovementsScreen(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              metricsGrid(),
              const SizedBox(height: 12),
              financialCards(),
              const SizedBox(height: 12),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: stockMovementPanel()),
                    const SizedBox(width: 12),
                    Expanded(child: quickLinksPanel()),
                  ],
                )
              else ...[
                stockMovementPanel(),
                const SizedBox(height: 10),
                quickLinksPanel(),
              ],
              const SizedBox(height: 10),
              _overviewPanel(
                title: 'Low stock',
                child: lowStockItems.isEmpty
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No low stock items'),
                        ),
                      )
                    : Column(
                        children: lowStockItems
                            .map(
                              (item) => _accentCard(
                                title: item.name,
                                subtitle:
                                    'Reorder level: ${item.reorderLevel ?? '—'}',
                                trailing:
                                    '${item.currentStock} ${item.unit ?? 'units'}',
                                icon: Icons.warning_amber_rounded,
                                accent: _lowRed,
                                tint: _lowRedBg,
                                titleColor: _lowRed,
                                badge: 'LOW',
                                emphasize: true,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _overviewPanel({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _movementSummary({
    required String title,
    required String value,
    required String detail,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _quickLink(String title, {required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFD5DCE7)),
      ),
      child: Text(title),
    );
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plTab(Map<String, dynamic> f) {
    final label = _periods[_months] ?? _months;
    final net = _num(f['netProfitEstimate']);
    final productsRaw = _pickLoose(f, ['byProduct', 'products', 'productWise']);
    final products = (productsRaw is List ? productsRaw : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (kDebugMode && products.isNotEmpty) {
      debugPrint('P/L byProduct keys: ${products.first.keys.toList()}');
      debugPrint('P/L byProduct[0]: ${products.first}');
    }

    Widget pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
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
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
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
        _kpi(
          'Purchase cost',
          _money(f['purchaseCost']),
          '${f['purchaseCount'] ?? 0} received POs',
          const Color(0xFFFFF8EE),
        ),
        _kpi(
          'Stock out sales',
          _money(f['stockOutSubtotal']),
          'GST ${_money(f['stockOutGst'])} · ${f['stockOutQty'] ?? 0} units',
          const Color(0xFFF1F4FF),
        ),
      ),
      pair(
        _kpi(
          'COGS (stock out)',
          _money(f['stockOutCogs']),
          'Gross profit ${_money(f['stockOutGrossProfit'])}',
          const Color(0xFFFFF8EE),
        ),
        _kpi(
          'Total revenue (ex GST)',
          _money(f['totalRevenueExGst']),
          'With GST ${_money(f['totalRevenueWithGst'])}',
          const Color(0xFFF1F4FF),
        ),
      ),
      pair(
        _kpi(
          'Estimated net P/L',
          _money(f['netProfitEstimate']),
          '${net >= 0 ? 'Earned more than spent' : 'Spent more than earned'} · $label',
          net >= 0 ? const Color(0xFFEBFAF3) : const Color(0xFFFFEFEF),
        ),
        _kpi(
          'Stock value',
          _money(f['inventoryValueAtCost']),
          '${f['inventoryUnits'] ?? 0} units · B2B ${_money(f['inventoryValueAtB2b'])}',
          const Color(0xFFF1F4FF),
        ),
      ),
      pair(
        _kpi(
          'Gross profit',
          _money(f['stockOutGrossProfit']),
          'Sales − COGS · $label',
          const Color(0xFFEBFAF3),
        ),
        _kpi(
          'Profit margin',
          _pct(f['profitMargin']),
          'Gross profit ÷ sales (ex GST)',
          _num(f['profitMargin']) >= 0
              ? const Color(0xFFEBFAF3)
              : const Color(0xFFFFEFEF),
        ),
      ),
      const SizedBox(height: 6),
      sectionHeading(
        'Product-wise cost & revenue',
        '${products.length} products · $label',
      ),
      if (products.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No product P/L rows for this period'),
        )
      else
        ...products.map(_productPlCard),
    ], padding: const EdgeInsets.all(16));
  }

  // byProduct[] keys are not spelled out in the API doc, so this matches many likely names.
  // In debug builds the real keys of the first row are printed — trim the lists to those.
  Map<String, dynamic> _plRow(Map<String, dynamic> p) {
    dynamic raw(List<String> keys) => _pickLoose(p, keys);
    num n(List<String> keys) => _num(raw(keys));

    final onHand = n([
      'onHand',
      'onHandQty',
      'currentStock',
      'stock',
      'stockQty',
      'quantityOnHand',
      'availableQty',
      'quantity',
      'qty',
    ]);
    final cost = n([
      'costPrice',
      'unitCost',
      'cost',
      'avgCost',
      'averageCost',
      'costPerUnit',
      'purchasePrice',
    ]);
    final b2bPrice = n([
      'b2bPrice',
      'b2b',
      'b2bRate',
      'sellingPrice',
      'salePrice',
    ]);

    final outQty = n([
      'outQty',
      'stockOutQty',
      'stockOutQuantity',
      'outQuantity',
      'soldQty',
      'soldQuantity',
      'qtySold',
    ]);
    final revenue = n([
      'outRevenue',
      'stockOutRevenue',
      'stockOutSubtotal',
      'stockOutSales',
      'stockOutAmount',
      'salesRevenue',
      'revenue',
      'totalRevenue',
      'revenueExGst',
    ]);

    // COGS: use the API value when available, otherwise derive from quantity and cost.
    final cogsRaw = raw(['cogs', 'stockOutCogs', 'costOfGoodsSold', 'outCogs']);
    final cogs = cogsRaw != null ? _num(cogsRaw) : outQty * cost;

    return {
      'name': raw(['productName', 'itemName', 'name']) ?? '—',
      'sku': raw(['sku', 'productSku', 'itemSku']) ?? '',
      'onHand': onHand,
      'cost': cost,
      'b2bPrice': b2bPrice,
      'outQty': outQty,
      'outRevenue': revenue,
      'cogs': cogs,
      'stockValue': raw([
                'stockValue',
                'inventoryValue',
                'valueAtCost',
                'stockValueAtCost',
              ]) !=
              null
          ? _num(raw([
              'stockValue',
              'inventoryValue',
              'valueAtCost',
              'stockValueAtCost',
            ]))
          : onHand * cost,
      'profit': revenue - cogs,
      'margin': revenue > 0 ? (revenue - cogs) / revenue * 100 : null,
    };
  }

  Widget _stat(String label, String value, {Color? color}) {
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlCard(Map<String, dynamic> raw) {
    final r = _plRow(raw);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r['name']}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
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
                _stat(
                  'Profit',
                  _money(r['profit']),
                  color: (r['profit'] as num) >= 0 ? _inGreen : _lowRed,
                ),
                _stat('Margin', _pct(r['margin'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPl(
    Map<String, dynamic> f,
    List<Map<String, dynamic>> products,
  ) {
    final rows = <List<dynamic>>[
      [
        'Product',
        'SKU',
        'On hand',
        'Cost price',
        'B2B price',
        'Stock out quantity',
        'Stock out revenue',
        'Stock out COGS',
        'Stock value',
        'Profit',
        'Margin %',
      ],
      ...products.map((p) {
        final r = _plRow(p);
        return [
          r['name'],
          r['sku'],
          _r2(r['onHand'] as num),
          _r2(r['cost'] as num),
          _r2(r['b2bPrice'] as num),
          _r2(r['outQty'] as num),
          _r2(r['outRevenue'] as num),
          _r2(r['cogs'] as num),
          _r2(r['stockValue'] as num),
          _r2(r['profit'] as num),
          r['margin'] == null ? '-' : _r2(r['margin'] as num),
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
    return _accentCard(
      title: row.name as String,
      subtitle: 'Reorder at ${reorder ?? '—'}',
      trailing: '$current units',
      icon: isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
      accent: isLow ? _lowRed : Colors.black54,
      tint: _lowRedBg,
      titleColor: isLow ? _lowRed : null,
      badge: isLow ? 'LOW' : null,
      emphasize: isLow,
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
          for (final e in const {
            'all': 'All',
            'in': 'Stock in',
            'out': 'Stock out',
          }.entries)
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
          child: Text(
            'No movements. Stock in and stock out activity appears here.',
          ),
        )
      else
        ...rows.map((movement) {
          final m = mapOf(movement);
          final isOut = pickText(m, ['direction']).toUpperCase() == 'OUT';
          final qty = pickText(m, ['quantity'], fallback: '0');
          final ref = pickText(m, ['referenceNo']);
          return _accentCard(
            title: pickText(m, ['itemName'], fallback: 'Stock movement'),
            subtitle:
                [
                      pickText(m, ['type']).replaceAll('_', ' '),
                      pickText(m, ['warehouseName']),
                      if (ref.isNotEmpty) ref,
                      fmtDate(m['createdAt']),
                    ]
                    .where((s) {
                      final value = s.toString().trim();
                      return value.isNotEmpty && value != '—' && value != '-';
                    })
                    .join('  •  '),
            trailing: '${isOut ? '' : '+'}$qty units',
            icon: isOut ? Icons.north_east : Icons.south_west,
            accent: isOut ? _outOrange : _inGreen,
            tint: Colors.white,
            badge: isOut ? 'OUT' : 'IN',
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
            child: sectionHeading(
              'Lot exports',
              '${maps.length} lots with purchase, processing & profit',
            ),
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
            subtitle:
                '$item  •  $status\n'
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
        'Lot',
        'Item',
        'Vendor',
        'Warehouse',
        'Status',
        'Received',
        'Raw',
        'Processing',
        'Processed',
        'Available',
        'Purchase amount',
        'Processing amount',
        'Selling amount',
        'Profit',
      ],
      ...lots.map(
        (m) => [
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
        ],
      ),
    ];
    return _exportCsv('inventory_lots.csv', rows);
  }
}

/// Smooth mini line chart with a soft gradient fill, like the CRM "Key stats" cards.
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final dx = size.width / (points.length - 1);
    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(i * dx, size.height - points[i].clamp(0.0, 1.0) * size.height),
    ];

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final p0 = offsets[i - 1];
      final p1 = offsets[i];
      final midX = (p0.dx + p1.dx) / 2;
      line.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(.18), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color;
}
