import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/operations/data/utlis/payable_utlis.dart';
import 'package:erp_app/features/inventory/operations/presentation/create_purchase_bill.dart';
import 'package:erp_app/features/inventory/operations/presentation/payable_settlement_dailogbox.dart';
import 'package:erp_app/features/inventory/operations/presentation/purchase_bill_details_screen.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';


class InventoryPayablesScreen extends ConsumerStatefulWidget {
  const InventoryPayablesScreen({super.key});

  @override
  ConsumerState<InventoryPayablesScreen> createState() => _InventoryPayablesScreenState();
}

class _InventoryPayablesScreenState extends ConsumerState<InventoryPayablesScreen>
    with InventoryUiHelpers<InventoryPayablesScreen> {
  late Future<List<dynamic>> _load;
  final _search = TextEditingController();
  String _filter = 'ALL'; // ALL | OPEN | PAID

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    return Future.wait<dynamic>([
      repo.getPurchaseBills(limit: 200),
      repo.getVendorPayments(limit: 200),
      repo.getVendorCredits(),
    ]);
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  List<BillView> _billViews(dynamic purchaseBills) => [
    for (final b in (purchaseBills as dynamic).bills as List) BillView(asMap(b.raw)),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canAdd = auth.canAny(const [
      AppPermissions.billManage,
      AppPermissions.purchaseOrderManage,
      AppPermissions.vendorPaymentManage,
      AppPermissions.vendorCreditManage,
    ]);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payables'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Bills'), Tab(text: 'Payments'), Tab(text: 'Credits')],
          ),
        ),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: _payableActions,
                icon: const Icon(Icons.add),
                label: const Text('Add payable'),
              )
            : null,
        body: loadBody<List<dynamic>>(future: _load, what: 'payables', builder: _content),
      ),
    );
  }

  Widget _content(List<dynamic> data) {
    final bills = _billViews(data[0]);
    final payments = data[1] as List<dynamic>;
    final credits = data[2] as List<dynamic>;
    return TabBarView(
      children: [
        _billsTab(bills),
        _payableList(
          title: 'Vendor payments',
          subtitle: 'Follow payments recorded against vendor bills.',
          icon: Icons.payments_outlined,
          rows: payments,
          emptyTitle: 'No vendor payments',
          emptyMessage: 'Payments recorded against bills appear here.',
          itemBuilder: (p) {
            final m = asMap(p);
            final method = firstText(m, ['method']);
            final ref = firstText(m, ['reference']);
            final bill = firstText(m, ['billNo']);
            return dataCard(
              title: firstText(m, ['vendorName', 'vendor'], fallback: 'Vendor payment'),
              subtitle: [
                if (bill.isNotEmpty) bill,
                if (method.isNotEmpty) method,
                if (ref.isNotEmpty) ref,
                dateText(m['paidAt'] ?? m['createdAt']),
              ].join('  •  '),
              amount: inr(m['amount']),
              icon: Icons.payments_outlined,
            );
          },
        ),
        _payableList(
          title: 'Vendor credits',
          subtitle: 'Review credits applied to vendor balances.',
          icon: Icons.credit_score_outlined,
          rows: credits,
          emptyTitle: 'No vendor credits',
          emptyMessage: 'Credits applied to vendor balances appear here.',
          itemBuilder: (c) {
            final m = asMap(c);
            final bill = firstText(m, ['billNo']);
            final reason = firstText(m, ['reason']);
            return dataCard(
              title: firstText(m, ['vendorName', 'vendor'], fallback: 'Vendor credit'),
              subtitle: [
                if (bill.isNotEmpty) bill,
                if (reason.isNotEmpty) reason,
                dateText(m['creditedAt'] ?? m['createdAt']),
              ].join('  •  '),
              amount: inr(m['amount']),
              icon: Icons.credit_score_outlined,
            );
          },
        ),
      ],
    );
  }

  // ───────── Bills tab ─────────

  Widget _billsTab(List<BillView> all) {
    final q = _search.text.trim().toLowerCase();
    final shown = all.where((b) {
      if (_filter == 'OPEN' && b.balance <= 0) return false;
      if (_filter == 'PAID' && !b.isPaid) return false;
      if (q.isEmpty) return true;
      return b.billNo.toLowerCase().contains(q) ||
          b.vendorName.toLowerCase().contains(q) ||
          b.invoiceNo.toLowerCase().contains(q) ||
          b.poNo.toLowerCase().contains(q);
    }).toList();

    final totalBilled = all.fold<num>(0, (s, b) => s + b.amount);
    final totalDue = all.fold<num>(0, (s, b) => s + b.balance);
    final t = Theme.of(context).textTheme;

    return refreshList([
      pageHeader(
        title: 'Purchase bills',
        subtitle: 'Review bills and outstanding vendor balances.',
        icon: Icons.receipt_long_outlined,
      ),
      Row(
        children: [
          Expanded(child: _summaryTile('Total billed', inr(totalBilled), t)),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryTile('Outstanding', inr(totalDue), t, color: const Color(0xFFB45309)),
          ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search bill, vendor, invoice or PO',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final f in const ['ALL', 'OPEN', 'PAID'])
            ChoiceChip(
              label: Text(f == 'ALL' ? 'All' : f == 'OPEN' ? 'Unpaid' : 'Paid'),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
        ],
      ),
      const SizedBox(height: 8),
      countBadge('Records', shown.length, icon: Icons.receipt_long_outlined),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 32, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 9),
                Text('No purchase bills', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Outstanding vendor bills and balances appear here.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        )
      else
        for (final b in shown) _billCard(b, all),
    ]);
  }

  Widget _summaryTile(String label, String value, TextTheme t, {Color? color}) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    ),
  );

  Widget _billCard(BillView b, List<BillView> all) {
    final t = Theme.of(context).textTheme;
    final status = b.isOverdue ? 'OVERDUE' : b.status;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openBill(b, all),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(b.billNo, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  StatusChip(status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  b.vendorName,
                  if (b.invoiceNo.isNotEmpty) 'Inv ${b.invoiceNo}',
                  if (b.poNo.isNotEmpty) b.poNo,
                ].join('  •  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _kv('Amount', inr(b.amount), t)),
                  Expanded(child: _kv('Paid', inr(b.paid + b.credited), t)),
                  Expanded(
                    child: _kv(
                      'Balance',
                      inr(b.balance),
                      t,
                      color: b.balance > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: b.settledFraction, minHeight: 4),
              ),
              const SizedBox(height: 6),
              Text(
                'Invoice ${dateText(b.invoiceDate)}   •   Due ${dateText(b.dueDate)}',
                style: t.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, TextTheme t, {Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: t.labelSmall),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(v, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ),
    ],
  );

  Future<List<MapEntry<int, String>>> _vendorList() async {
    final res = await ref.read(inventoryRepositoryProvider).getVendors(limit: 200);
    return [for (final v in res.vendors) MapEntry<int, String>(v.id, v.name)];
  }

  Future<void> _openBill(BillView b, List<BillView> all) async {
    try {
      final vendors = await _vendorList();
      if (!mounted) return;
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseBillDetailScreen(bill: b, vendors: vendors, allBills: all),
        ),
      );
      if (changed == true) reload();
    } catch (e) {
      showError(e);
    }
  }

  // ───────── generic list for payments / credits ─────────

  Widget _payableList({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<dynamic> rows,
    required String emptyTitle,
    required String emptyMessage,
    required Widget Function(dynamic row) itemBuilder,
  }) => refreshList([
    pageHeader(title: title, subtitle: subtitle, icon: icon),
    countBadge('Records', rows.length, icon: icon),
    const SizedBox(height: 12),
    if (rows.isEmpty)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 9),
              Text(emptyTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(emptyMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      )
    else
      for (final row in rows) itemBuilder(row),
  ]);

  // ───────── actions ─────────

  Future<void> _payableActions() async {
    final auth = ref.read(authProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            if (auth.canAny(const [AppPermissions.billManage, AppPermissions.purchaseOrderManage]))
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Create purchase bill'),
                onTap: () => Navigator.pop(c, 'Bill'),
              ),
            if (auth.can(AppPermissions.vendorPaymentManage))
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Record vendor payment'),
                onTap: () => Navigator.pop(c, 'Payment'),
              ),
            if (auth.can(AppPermissions.vendorCreditManage))
              ListTile(
                leading: const Icon(Icons.credit_score_outlined),
                title: const Text('Record vendor credit'),
                onTap: () => Navigator.pop(c, 'Credit'),
              ),
          ],
        ),
      ),
    );
    if (choice == 'Bill') {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CreatePurchaseBillScreen()),
      );
      if (created == true) reload();
    }
    if (choice == 'Payment') await _settle(credit: false);
    if (choice == 'Credit') await _settle(credit: true);
  }

  Future<void> _settle({required bool credit}) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final vendors = await _vendorList();
      final bills = _billViews(await repo.getPurchaseBills(limit: 200));
      if (!mounted) return;
      final body = await showVendorSettlementDialog(
        context,
        credit: credit,
        vendors: vendors,
        bills: bills,
      );
      if (body == null) return;
      await (credit ? repo.createVendorCredit(body) : repo.createVendorPayment(body));
      showSuccess(credit ? 'Vendor credit recorded' : 'Payment recorded');
      reload(); // the old screen never refreshed after saving
    } catch (e) {
      showError(e);
    }
  }
}