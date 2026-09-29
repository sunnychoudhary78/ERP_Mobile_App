import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/operations/data/utlis/payable_utlis.dart';
import 'package:erp_app/features/inventory/operations/presentation/payable_settlement_dailogbox.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Full bill detail (what the web shows when a bill row is opened).
/// Pops with `true` when a payment/credit was recorded so the list reloads.
class PurchaseBillDetailScreen extends ConsumerStatefulWidget {
  const PurchaseBillDetailScreen({
    super.key,
    required this.bill,
    required this.vendors,
    required this.allBills,
  });

  final BillView bill;
  final List<MapEntry<int, String>> vendors;
  final List<BillView> allBills;

  @override
  ConsumerState<PurchaseBillDetailScreen> createState() =>
      _PurchaseBillDetailScreenState();
}

class _PurchaseBillDetailScreenState
    extends ConsumerState<PurchaseBillDetailScreen> {
  late Future<List<dynamic>> _payments;
  bool _changed = false;

  BillView get bill => widget.bill;

  @override
  void initState() {
    super.initState();
    _payments = _loadPayments();
  }

  Future<List<dynamic>> _loadPayments() => ref
      .read(inventoryRepositoryProvider)
      .getVendorPayments(billId: bill.id, limit: 100);

  Future<void> _record({required bool credit}) async {
    final body = await showVendorSettlementDialog(
      context,
      credit: credit,
      vendors: widget.vendors,
      bills: widget.allBills,
      bill: bill,
    );
    if (body == null) return;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await (credit ? repo.createVendorCredit(body) : repo.createVendorPayment(body));
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(credit ? 'Vendor credit recorded' : 'Payment recorded')),
      );
      // Balance changed → go back so the list reloads with fresh numbers.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = Theme.of(context).textTheme;
    final canPay = auth.can(AppPermissions.vendorPaymentManage) && bill.balance > 0;
    final canCredit = auth.can(AppPermissions.vendorCreditManage) && bill.balance > 0;
    final lines = bill.lines;
    final tax = bill.taxFields;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(bill.billNo)),
        bottomNavigationBar: (canPay || canCredit)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      if (canCredit)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _record(credit: true),
                            child: const Text('Add credit'),
                          ),
                        ),
                      if (canCredit && canPay) const SizedBox(width: 12),
                      if (canPay)
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _record(credit: false),
                            child: const Text('Record payment'),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(bill.vendorName,
                              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        StatusChip(bill.isOverdue ? 'OVERDUE' : bill.status),
                      ],
                    ),
                    const Divider(height: 24),
                    KeyValueRow('Bill no.', bill.billNo),
                    KeyValueRow('PO / GRN reference', bill.poNo),
                    KeyValueRow('Vendor invoice no.', bill.invoiceNo),
                    KeyValueRow('Invoice date', dateText(bill.invoiceDate)),
                    KeyValueRow('Due date', dateText(bill.dueDate)),
                    if (txt(bill.raw['itcEligibility']).isNotEmpty)
                      KeyValueRow('Input tax credit', txt(bill.raw['itcEligibility'])),
                    if (bill.raw['reverseCharge'] != null)
                      KeyValueRow(
                        'Reverse charge',
                        (bill.raw['reverseCharge'] == true ||
                                '${bill.raw['reverseCharge']}' == '1')
                            ? 'Yes'
                            : 'No',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final e in tax) KeyValueRow(e.key, inr(e.value)),
                    KeyValueRow('Bill amount', inr(bill.amount), bold: true),
                    KeyValueRow('Paid', inr(bill.paid), color: const Color(0xFF15803D)),
                    KeyValueRow('Credited', inr(bill.credited)),
                    const Divider(height: 20),
                    KeyValueRow(
                      'Balance due',
                      inr(bill.balance),
                      bold: true,
                      color: bill.balance > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: bill.settledFraction, minHeight: 6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No line items on this bill.', style: t.bodySmall),
                      )
                    else
                      for (final l in lines) LineTile(l),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payments', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    FutureBuilder<List<dynamic>>(
                      future: _payments,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: LinearProgressIndicator(),
                          );
                        }
                        final rows = snap.data ?? const [];
                        if (rows.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('No payments recorded yet.', style: t.bodySmall),
                          );
                        }
                        return Column(
                          children: [
                            for (final p in rows)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.payments_outlined),
                                title: Text(inr(asMap(p)['amount'])),
                                subtitle: Text(
                                  '${firstText(asMap(p), ['method'], fallback: 'Payment')}'
                                  '${firstText(asMap(p), ['reference']).isEmpty ? '' : ' • ${firstText(asMap(p), ['reference'])}'}'
                                  '  •  ${dateText(asMap(p)['paidAt'] ?? asMap(p)['createdAt'])}',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (txt(bill.raw['notes']).isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(txt(bill.raw['notes'])),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}