import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    return Future.wait<dynamic>([
      repo.getPurchaseBills(),
      repo.getVendorPayments(),
      repo.getVendorCredits(),
    ]);
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

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
            tabs: [
              Tab(text: 'Bills'),
              Tab(text: 'Payments'),
              Tab(text: 'Credits'),
            ],
          ),
        ),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: _payableActions,
                icon: const Icon(Icons.add),
                label: const Text('Add payable'),
              )
            : null,
        body: loadBody<List<dynamic>>(
          future: _load,
          what: 'payables',
          builder: _content,
        ),
      ),
    );
  }

  Widget _content(List<dynamic> data) {
    final bills = (data[0] as dynamic).bills;
    final payments = data[1] as List<dynamic>;
    final credits = data[2] as List<dynamic>;
    return TabBarView(
      children: [
        _payableList(
          title: 'Purchase bills',
          subtitle: 'Review bills and outstanding vendor balances.',
          icon: Icons.receipt_long_outlined,
          rows: List<dynamic>.from(bills),
          emptyTitle: 'No purchase bills',
          emptyMessage: 'Outstanding vendor bills and balances appear here.',
          itemBuilder: (b) => dataCard(
            title: pickText(b.raw, [
              'billNo',
              'billNumber',
            ], fallback: 'Bill #${b.id}'),
            subtitle:
                '${pickText(b.raw, ['vendorName', 'vendor'])}  •  ${b.status}',
            amount: '₹${b.totalAmount.toStringAsFixed(2)}',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        _payableList(
          title: 'Vendor payments',
          subtitle: 'Follow payments recorded against vendor bills.',
          icon: Icons.payments_outlined,
          rows: payments,
          emptyTitle: 'No vendor payments',
          emptyMessage: 'Payments recorded against bills appear here.',
          itemBuilder: (p) => dataCard(
            title: pickText(mapOf(p), [
              'vendorName',
              'vendor',
              'billNo',
            ], fallback: 'Vendor payment'),
            subtitle:
                '${pickText(mapOf(p), ['method', 'reference'])}  •  ${fmtDate(mapOf(p)['paidAt'] ?? mapOf(p)['createdAt'])}',
            amount: '₹${fmtMoney(mapOf(p)['amount'])}',
            icon: Icons.payments_outlined,
          ),
        ),
        _payableList(
          title: 'Vendor credits',
          subtitle: 'Review credits applied to vendor balances.',
          icon: Icons.credit_score_outlined,
          rows: credits,
          emptyTitle: 'No vendor credits',
          emptyMessage: 'Credits applied to vendor balances appear here.',
          itemBuilder: (c) => dataCard(
            title: pickText(mapOf(c), [
              'vendorName',
              'vendor',
              'billNo',
            ], fallback: 'Vendor credit'),
            subtitle: pickText(mapOf(c), ['reason', 'creditedAt', 'createdAt']),
            amount: '₹${fmtMoney(mapOf(c)['amount'])}',
            icon: Icons.credit_score_outlined,
          ),
        ),
      ],
    );
  }

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
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      )
    else
      for (final row in rows) itemBuilder(row),
  ]);

  Future<void> _payableActions() async {
    final auth = ref.read(authProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            if (auth.canAny(const [
              AppPermissions.billManage,
              AppPermissions.purchaseOrderManage,
            ]))
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Create manual bill'),
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
    if (choice == 'Bill') await _createManualBill();
    if (choice == 'Payment') await _vendorSettlement(credit: false);
    if (choice == 'Credit') await _vendorSettlement(credit: true);
  }

  Future<void> _vendorSettlement({required bool credit}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    try {
      final vendors = (await repo.getVendors(limit: 200)).vendors;
      final bills = (await repo.getPurchaseBills()).bills;
      if (!mounted) return;
      int? vendorId;
      int? billId;
      String method = 'Bank Transfer';
      final amount = TextEditingController();
      final reference = TextEditingController();
      final reason = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final done = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(
              credit ? 'Record vendor credit' : 'Record vendor payment',
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Vendor'),
                        items: [
                          for (final v in vendors)
                            DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                v.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setModal(() => vendorId = v),
                        validator: (v) => v == null ? 'Select a vendor' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Bill'),
                        items: [
                          for (final b in bills)
                            DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                b.billNumber,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setModal(() => billId = v),
                        validator: (v) => v == null ? 'Select a bill' : null,
                      ),
                      TextFormField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                        ),
                        validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter an amount greater than zero'
                            : null,
                      ),
                      if (!credit)
                        DropdownButtonFormField<String>(
                          value: method,
                          decoration: const InputDecoration(
                            labelText: 'Payment method',
                          ),
                          items: [
                            for (final m in [
                              'Bank Transfer',
                              'UPI',
                              'Cheque',
                              'Cash',
                            ])
                              DropdownMenuItem(value: m, child: Text(m)),
                          ],
                          onChanged: (v) =>
                              setModal(() => method = v ?? method),
                        ),
                      if (!credit)
                        TextFormField(
                          controller: reference,
                          decoration: const InputDecoration(
                            labelText: 'Reference (optional)',
                          ),
                        ),
                      if (credit)
                        TextFormField(
                          controller: reason,
                          decoration: const InputDecoration(
                            labelText: 'Reason (optional)',
                          ),
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
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (done != true || vendorId == null) return;
      final body = <String, dynamic>{
        'vendorId': vendorId,
        'amount': num.parse(amount.text),
        if (billId != null) 'billId': billId,
        if (credit) 'reason': reason.text.trim(),
        if (credit)
          'creditedAt': DateTime.now().toIso8601String().substring(0, 10),
        if (!credit) 'method': method,
        if (!credit && reference.text.trim().isNotEmpty)
          'reference': reference.text.trim(),
        if (!credit)
          'paidAt': DateTime.now().toIso8601String().substring(0, 10),
      };
      await (credit
          ? repo.createVendorCredit(body)
          : repo.createVendorPayment(body));
      showSuccess(credit ? 'Vendor credit recorded' : 'Payment recorded');
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _createManualBill() async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final vendors = (await repo.getVendors(limit: 200)).vendors;
      if (!mounted) return;
      int? vendorId;
      bool reverseCharge = false;
      String itcEligibility = 'ELIGIBLE';
      final invoiceNo = TextEditingController();
      final poNo = TextEditingController();
      final notes = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final today = DateTime.now();
      final invoiceDate = today.toIso8601String().substring(0, 10);
      final dueDate = today
          .add(const Duration(days: 30))
          .toIso8601String()
          .substring(0, 10);
      final submit = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Create manual bill'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Vendor'),
                      items: [
                        for (final v in vendors)
                          DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              v.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setModal(() => vendorId = v),
                      validator: (v) => v == null ? 'Select a vendor' : null,
                    ),
                    TextFormField(
                      controller: invoiceNo,
                      decoration: const InputDecoration(
                        labelText: 'Vendor invoice number',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Invoice number is required'
                          : null,
                    ),
                    TextField(
                      controller: poNo,
                      decoration: const InputDecoration(
                        labelText: 'PO number (optional)',
                      ),
                    ),
                    TextField(
                      controller: notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                    ),
                    DropdownButtonFormField<String>(
                      value: itcEligibility,
                      decoration: const InputDecoration(
                        labelText: 'Input tax credit',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ELIGIBLE',
                          child: Text('Eligible'),
                        ),
                        DropdownMenuItem(
                          value: 'INELIGIBLE',
                          child: Text('Ineligible'),
                        ),
                      ],
                      onChanged: (v) =>
                          setModal(() => itcEligibility = v ?? itcEligibility),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reverse charge'),
                      value: reverseCharge,
                      onChanged: (v) => setModal(() => reverseCharge = v),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Invoice date: $invoiceDate  •  Due date: $dueDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This records the bill header. Bill lines can be added from Accounts.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );
      if (submit != true || vendorId == null) return;
      final vendor = vendors.firstWhere((v) => v.id == vendorId);
      await repo.createManualBill({
        'vendorId': vendor.id,
        'vendor': vendor.name,
        'poNo': poNo.text.trim(),
        'vendorInvoiceNo': invoiceNo.text.trim(),
        'invoiceDate': invoiceDate,
        'dueDate': dueDate,
        'notes': notes.text.trim(),
        'reverseCharge': reverseCharge,
        'itcEligibility': itcEligibility,
        'lines': <dynamic>[],
      });
      showSuccess('Manual bill created');
    } catch (e) {
      showError(e);
    }
  }
}
