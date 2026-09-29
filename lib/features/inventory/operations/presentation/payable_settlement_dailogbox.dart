import 'package:erp_app/features/inventory/operations/data/utlis/payable_utlis.dart';
import 'package:flutter/material.dart';



/// Returns the request body for POST /vendor-payments or /vendor-credits,
/// or null if cancelled.
///
/// [vendors] = id → name, [bills] = every bill (filtered by vendor inside),
/// [bill] = pre-selected bill (opened from a bill's detail screen).
Future<Map<String, dynamic>?> showVendorSettlementDialog(
  BuildContext context, {
  required bool credit,
  required List<MapEntry<int, String>> vendors,
  required List<BillView> bills,
  BillView? bill,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _SettlementDialog(
      credit: credit,
      vendors: vendors,
      bills: bills,
      initialBill: bill,
    ),
  );
}

class _SettlementDialog extends StatefulWidget {
  const _SettlementDialog({
    required this.credit,
    required this.vendors,
    required this.bills,
    this.initialBill,
  });

  final bool credit;
  final List<MapEntry<int, String>> vendors;
  final List<BillView> bills;
  final BillView? initialBill;

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<_SettlementDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _reason = TextEditingController();
  int? _vendorId;
  BillView? _bill;
  String _method = 'Bank Transfer';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final b = widget.initialBill;
    if (b != null) {
      _bill = b;
      _vendorId = b.vendorId;
      _amount.text = b.balance > 0 ? b.balance.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _reason.dispose();
    super.dispose();
  }

  List<BillView> get _vendorBills => widget.bills
      .where((b) => b.vendorId == _vendorId && b.balance > 0)
      .toList();

  @override
  Widget build(BuildContext context) {
    final locked = widget.initialBill != null;
    final selected = _bill;
    return AlertDialog(
      title: Text(widget.credit ? 'Record vendor credit' : 'Record vendor payment'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _vendorId,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                  items: [
                    for (final v in widget.vendors)
                      DropdownMenuItem(
                        value: v.key,
                        child: Text(v.value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: locked
                      ? null
                      : (v) => setState(() {
                          _vendorId = v;
                          _bill = null;
                          _amount.clear();
                        }),
                  validator: (v) => v == null ? 'Select a vendor' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: selected?.id,
                  decoration: InputDecoration(
                    labelText: 'Bill',
                    helperText: _vendorId != null && _vendorBills.isEmpty
                        ? 'No open bills for this vendor'
                        : null,
                  ),
                  items: [
                    for (final b in (locked ? [widget.initialBill!] : _vendorBills))
                      DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '${b.billNo} • Due ${inr(b.balance)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: locked
                      ? null
                      : (id) => setState(() {
                          _bill = _vendorBills.firstWhere((b) => b.id == id);
                          _amount.text = _bill!.balance.toStringAsFixed(2);
                        }),
                  validator: (v) => v == null ? 'Select a bill' : null,
                ),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    helperText: selected == null
                        ? null
                        : 'Outstanding ${inr(selected.balance)}',
                  ),
                  validator: (v) {
                    final n = num.tryParse(v ?? '') ?? 0;
                    if (n <= 0) return 'Enter an amount greater than zero';
                    if (selected != null && n > selected.balance + 0.005) {
                      return 'Cannot exceed outstanding ${inr(selected.balance)}';
                    }
                    return null;
                  },
                ),
                if (!widget.credit) ...[
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'Payment method'),
                    items: [
                      for (final m in const ['Bank Transfer', 'UPI', 'Cheque', 'Cash'])
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) => setState(() => _method = v ?? _method),
                  ),
                  TextFormField(
                    controller: _reference,
                    decoration: const InputDecoration(labelText: 'Reference / UTR (optional)'),
                  ),
                ] else
                  TextFormField(
                    controller: _reason,
                    decoration: const InputDecoration(labelText: 'Reason (optional)'),
                  ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(widget.credit ? 'Credit date' : 'Payment date'),
                  trailing: Text(dateText(_date)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final ref = _reference.text.trim();
            Navigator.pop(context, <String, dynamic>{
              'vendorId': _vendorId,
              'billId': _bill!.id,
              'amount': num.parse(_amount.text),
              if (widget.credit) ...{
                if (_reason.text.trim().isNotEmpty) 'reason': _reason.text.trim(),
                'creditedAt': isoDay(_date),
              } else ...{
                'method': _method,
                if (ref.isNotEmpty) 'reference': ref,
                'paidAt': isoDay(_date),
              },
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}