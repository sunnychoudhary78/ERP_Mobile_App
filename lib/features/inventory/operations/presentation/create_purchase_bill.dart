import 'package:erp_app/features/inventory/operations/data/utlis/payable_utlis.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



/// Some backends reject unknown keys on `from-purchase`. If creating a bill
/// from a PO fails with a validation error, set this to false.
const bool kSendHeaderWithPo = true;

const _billablePoStatuses = {'RECEIVED', 'PARTIALLY_RECEIVED'};

/// Mobile version of the web "Create purchase bill" dialog.
/// Pops with `true` when a bill was created.
class CreatePurchaseBillScreen extends ConsumerStatefulWidget {
  const CreatePurchaseBillScreen({super.key});

  @override
  ConsumerState<CreatePurchaseBillScreen> createState() =>
      _CreatePurchaseBillScreenState();
}

class _CreatePurchaseBillScreenState
    extends ConsumerState<CreatePurchaseBillScreen> {
  final _form = GlobalKey<FormState>();
  final _invoiceNo = TextEditingController();
  final _notes = TextEditingController();

  List<MapEntry<int, String>> _vendors = [];
  bool _loadingVendors = true;
  String? _loadError;

  int? _vendorId;
  Map<String, dynamic> _vendor = {};
  bool _loadingVendor = false;
  List<Map<String, dynamic>> _pos = [];
  int? _purchaseId; // null => manual bill
  final List<Map<String, dynamic>> _manualLines = [];

  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _itc = 'ELIGIBLE';
  bool _reverseCharge = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _invoiceNo.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    try {
      final res = await ref.read(inventoryRepositoryProvider).getVendors(limit: 200);
      if (!mounted) return;
      setState(() {
        _vendors = [for (final v in res.vendors) MapEntry<int, String>(v.id, v.name)];
        _loadingVendors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loadingVendors = false;
      });
    }
  }

  /// Selecting a vendor pulls the vendor's details and the POs that can be billed.
  Future<void> _onVendor(int? id) async {
    setState(() {
      _vendorId = id;
      _vendor = {};
      _pos = [];
      _purchaseId = null;
      _manualLines.clear();
      _loadingVendor = id != null;
    });
    if (id == null) return;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final vendor = await repo.getVendorRaw(id);
      final purchases = await repo.getPurchasesRaw(limit: 200);
      final billed = <int>{
        for (final b in (await repo.getPurchaseBills(limit: 200)).bills)
          if (BillView(asMap(b.raw)).purchaseId != null) BillView(asMap(b.raw)).purchaseId!,
      };
      final pos = <Map<String, dynamic>>[];
      for (final p in purchases) {
        final m = asMap(p);
        final vId = numOf(m['vendorId'] ?? asMap(m['vendor'])['id']).toInt();
        final pId = numOf(m['id']).toInt();
        final st = txt(m['status']).toUpperCase();
        if (vId == id && _billablePoStatuses.contains(st) && !billed.contains(pId)) {
          pos.add(m);
        }
      }
      if (!mounted || _vendorId != id) return;
      setState(() {
        _vendor = vendor;
        _pos = pos;
        _loadingVendor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVendor = false);
      _snack(e);
    }
  }

  Map<String, dynamic>? get _selectedPo {
    if (_purchaseId == null) return null;
    for (final p in _pos) {
      if (numOf(p['id']).toInt() == _purchaseId) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> get _lines {
    final po = _selectedPo;
    if (po == null) return _manualLines;
    final items = po['items'];
    if (items is! List) return const [];
    return [for (final i in items) normLine(i, preferReceived: true)];
  }

  num get _total => _lines.fold<num>(0, (s, l) => s + numOf(l['amount']));

  void _snack(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _pickDate(bool due) async {
    final d = await showDatePicker(
      context: context,
      initialDate: due ? _dueDate : _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d == null) return;
    setState(() => due ? _dueDate = d : _invoiceDate = d);
  }

  Future<void> _addLine() async {
    final desc = TextEditingController();
    final hsn = TextEditingController();
    final qty = TextEditingController(text: '1');
    final rate = TextEditingController();
    final unit = TextEditingController(text: 'Nos');
    final key = GlobalKey<FormState>();
    final line = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add bill line'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Description of goods *'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: hsn,
                  decoration: const InputDecoration(labelText: 'HSN/SAC *'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qty,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Per'),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate', prefixText: '₹ '),
                  validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a rate' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              final q = num.parse(qty.text);
              final r = num.parse(rate.text);
              Navigator.pop(c, <String, dynamic>{
                'description': desc.text.trim(),
                'hsnSac': hsn.text.trim(),
                'quantity': q,
                'rate': r,
                'unit': unit.text.trim(),
                'amount': q * r,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (line != null) setState(() => _manualLines.add(line));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_lines.isEmpty) {
      _snack('Add at least one bill line (or pick a received PO).');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final header = <String, dynamic>{
        'vendorInvoiceNo': _invoiceNo.text.trim(),
        'invoiceDate': isoDay(_invoiceDate),
        'dueDate': isoDay(_dueDate),
        'notes': _notes.text.trim(),
        'reverseCharge': _reverseCharge,
        'itcEligibility': _itc,
      };
      final po = _selectedPo;
      if (po != null) {
        await repo.createBillFromPurchase(
          numOf(po['id']).toInt(),
          extra: kSendHeaderWithPo ? header : null,
        );
      } else {
        await repo.createManualBill({
          'vendorId': _vendorId,
          'vendor': _vendors.firstWhere((v) => v.key == _vendorId).value,
          'poNo': '',
          ...header,
          'lines': [
            for (final l in _manualLines)
              {
                'description': l['description'],
                'hsnSac': l['hsnSac'],
                'quantity': l['quantity'],
                'rate': l['rate'],
                'unit': l['unit'],
                'amount': l['amount'],
                // The bill API validates taxableValue separately from amount.
                // Manual lines have no tax breakdown, so their line amount is
                // the taxable amount.
                'taxableValue': l['amount'],
              },
          ],
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase bill created')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final po = _selectedPo;
    final lines = _lines;

    return Scaffold(
      appBar: AppBar(title: const Text('Create purchase bill')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: t.bodySmall),
                    Text(inr(_total), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: (_saving || _vendorId == null) ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create bill'),
              ),
            ],
          ),
        ),
      ),
      body: _loadingVendors
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!)))
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Record vendor bill from PO or goods received.', style: t.bodySmall),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _vendorId,
                    decoration: const InputDecoration(labelText: 'Vendor *', border: OutlineInputBorder()),
                    items: [
                      for (final v in _vendors)
                        DropdownMenuItem(value: v.key, child: Text(v.value, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: _saving ? null : _onVendor,
                    validator: (v) => v == null ? 'Select a vendor' : null,
                  ),
                  if (_loadingVendor)
                    const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                  if (_vendorId != null && !_loadingVendor) ...[
                    const SizedBox(height: 12),
                    _vendorCard(t),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _purchaseId,
                      decoration: InputDecoration(
                        labelText: 'PO / GRN reference',
                        border: const OutlineInputBorder(),
                        helperText: _pos.isEmpty
                            ? 'No received, un-billed POs for this vendor — add lines manually.'
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Manual bill (no PO)')),
                        for (final p in _pos)
                          DropdownMenuItem<int?>(
                            value: numOf(p['id']).toInt(),
                            child: Text(
                              '${firstText(p, ['poNumber'], fallback: 'PO #${p['id']}')} • ${inr(p['totalAmount'])}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving ? null : (v) => setState(() => _purchaseId = v),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Description of goods',
                                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                ),
                                if (po == null)
                                  TextButton.icon(
                                    onPressed: _addLine,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add line'),
                                  ),
                              ],
                            ),
                            if (lines.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  po == null ? 'No lines yet — tap “Add line”.' : 'This PO has no items.',
                                  style: t.bodySmall,
                                ),
                              )
                            else
                              for (var i = 0; i < lines.length; i++)
                                LineTile(
                                  lines[i],
                                  onDelete: po == null ? () => setState(() => _manualLines.removeAt(i)) : null,
                                ),
                            const Divider(),
                            KeyValueRow('Total', inr(_total), bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _invoiceNo,
                      decoration: const InputDecoration(
                        labelText: 'Vendor invoice number ',
                        border: OutlineInputBorder(),
                      ),
                    //  validator: (v) => (v ?? '').trim().isEmpty ? 'Invoice number is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _dateField('Invoice date', _invoiceDate, () => _pickDate(false))),
                        const SizedBox(width: 12),
                        Expanded(child: _dateField('Due date', _dueDate, () => _pickDate(true))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _itc,
                      decoration: const InputDecoration(labelText: 'Input tax credit', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ELIGIBLE', child: Text('Eligible')),
                        DropdownMenuItem(value: 'INELIGIBLE', child: Text('Ineligible')),
                      ],
                      onChanged: (v) => setState(() => _itc = v ?? _itc),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reverse charge'),
                      value: _reverseCharge,
                      onChanged: (v) => setState(() => _reverseCharge = v),
                    ),
                    TextFormField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _dateField(String label, DateTime d, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(dateText(d)),
    ),
  );

  Widget _vendorCard(TextTheme t) {
    final name = firstText(_vendor, ['name'], fallback: _vendors.firstWhere((v) => v.key == _vendorId).value);
    final rows = <MapEntry<String, String>>[
      MapEntry('Address', firstText(_vendor, ['address'])),
      MapEntry('Contact', firstText(_vendor, ['phone'])),
      MapEntry('E-Mail', firstText(_vendor, ['email'])),
      MapEntry('GSTIN', firstText(_vendor, ['gstNumber', 'gstin'])),
      MapEntry('PAN', firstText(_vendor, ['panNumber'])),
    ].where((e) => e.value.isNotEmpty).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VENDOR (BILL FROM)',
                style: t.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            for (final r in rows) KeyValueRow(r.key, r.value),
          ],
        ),
      ),
    );
  }
}
