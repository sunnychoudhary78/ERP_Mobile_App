import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/sales_lead_model.dart';
import '../../../shared/data/models/sales_product_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class LeadFormScreen extends ConsumerStatefulWidget {
  const LeadFormScreen({super.key});

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _RequirementLine {
  InventoryProductItem? product;
  String type;
  String articleNo;
  String sku;
  String itemId;

  final _description = TextEditingController();
  final _qty = TextEditingController();
  final _rate = TextEditingController();
  final _hsn = TextEditingController();
  final _unit = TextEditingController();

  _RequirementLine({
    this.product,
    String? description,
    String? qty,
    String? rate,
    String? hsn,
    String? unit,
    this.type = 'PHYSICAL',
    this.articleNo = '',
    this.sku = '',
    this.itemId = '',
  }) {
    _description.text = description ?? '';
    _qty.text = qty ?? '1';
    _rate.text = rate ?? '';
    _hsn.text = hsn ?? '';
    _unit.text = unit ?? '';
  }

  double get amount =>
      (double.tryParse(_qty.text) ?? 0) * (double.tryParse(_rate.text) ?? 0);

  /// Auto-fills the line when a product is picked from the dropdown —
  /// mirrors the web "Pick product" behaviour.
  void applyProduct(InventoryProductItem p) {
    product = p;
    itemId = p.id.toString();
    articleNo = p.articleNo;
    sku = p.sku;
    type = p.type.isNotEmpty ? p.type : 'PHYSICAL';
    _description.text = p.name;
    _hsn.text = p.hsn;
    _unit.text = p.unit;
    if (p.rate > 0) _rate.text = p.rate.toStringAsFixed(0);
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'articleNo': articleNo,
    'sku': sku,
    'description': _description.text.trim(),
    'hsn': _hsn.text.trim(),
    'unit': _unit.text.trim(),
    'type': type,
    'qty': double.tryParse(_qty.text) ?? 0,
    'rate': double.tryParse(_rate.text) ?? 0,
    'amount': amount,
  };

  void dispose() {
    _description.dispose();
    _qty.dispose();
    _rate.dispose();
    _hsn.dispose();
    _unit.dispose();
  }
}

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _gst = TextEditingController();
  final _requirement = TextEditingController();
  final _value = TextEditingController();

  String _source = 'Phone';
  String _clientType = 'New';
  String _temperature = 'Later';
  String _repeatFreq = 'Once';

  bool _addProducts = false;
  final List<_RequirementLine> _lines = [];

  bool _submitting = false;
  String? _error;
  String? _leadId;
  bool _prefilled = false;

  static const _sourceOptions = [
    'Phone',
    'Email',
    'Referral',
    'Website',
    'Walk-in',
    'Social Media',
    'Other',
  ];
  static const _clientTypeOptions = ['New', 'Returning'];
  static const _temperatureOptions = ['Hot', 'Warm', 'Cold', 'Later'];
  static const _repeatFreqOptions = [
    'Once',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  bool get _isEdit => _leadId != null && _leadId!.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _leadId = args;
    } else if (args is Map && args['leadId'] != null) {
      _leadId = args['leadId'].toString();
    }
    if (_isEdit && !_prefilled) {
      final lead = ref.read(crmLeadByIdProvider(_leadId!));
      if (lead != null) {
        _prefill(lead);
        _prefilled = true;
      }
    }
  }

  void _prefill(SalesLead lead) {
    _company.text = lead.companyName;
    _contact.text = lead.contactName;
    _phone.text = lead.phone;
    _email.text = lead.email;
    _address.text = lead.address;
    _gst.text = lead.gstNumber;
    _requirement.text = lead.requirements;
    _value.text = lead.value > 0 ? lead.value.toStringAsFixed(0) : '';
    _source = _sourceOptions.contains(lead.source) ? lead.source : 'Phone';
    final type = lead.clientType == 'Existing' ? 'Returning' : lead.clientType;
    _clientType =
        _clientTypeOptions.contains(type) ? type : 'New';
    final temp = lead.temperature ?? 'Later';
    _temperature =
        _temperatureOptions.contains(temp) ? temp : 'Later';
    _repeatFreq = _repeatFreqOptions.contains(lead.repeatFrequency)
        ? lead.repeatFrequency
        : 'Once';
    if (lead.requirementLines.isNotEmpty) {
      _addProducts = true;
      for (final raw in lead.requirementLines) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        _lines.add(
          _RequirementLine(
            description: m['description']?.toString() ?? '',
            qty: m['qty']?.toString() ?? '',
            rate: m['rate']?.toString() ?? '',
            hsn: m['hsn']?.toString() ?? '',
            unit: m['unit']?.toString() ?? '',
            type: m['type']?.toString() ?? 'PHYSICAL',
            articleNo: m['articleNo']?.toString() ?? '',
            sku: m['sku']?.toString() ?? '',
            itemId: m['itemId']?.toString() ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _gst.dispose();
    _requirement.dispose();
    _value.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  InventoryProductItem? _matchedProduct(
    List<InventoryProductItem> products,
    _RequirementLine line,
  ) {
    if (line.product != null) return line.product;
    if (line.itemId.isEmpty) return null;
    for (final p in products) {
      if (p.id.toString() == line.itemId) return p;
    }
    return null;
  }

  Widget _buildProductLines(
    BuildContext context,
    List<InventoryProductItem> products, {
    bool loadError = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (loadError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Could not load product list — you can still enter items manually.',
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        for (var i = 0; i < _lines.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _responsiveRow([
                  DropdownButtonFormField<InventoryProductItem>(
                    value: _matchedProduct(products, _lines[i]),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Pick product'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p == null) return;
                      setState(() => _lines[i].applyProduct(p));
                    },
                  ),
                  TextFormField(
                    controller: _lines[i]._description,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ]),
                const SizedBox(height: 12),
                _responsiveRow([
                  TextFormField(
                    controller: _lines[i]._hsn,
                    decoration: const InputDecoration(
                      labelText: 'HSN / SAC',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    controller: _lines[i]._unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'Nos, Kg, Roll...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lines[i]._qty,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lines[i]._rate,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Rate',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '₹${_lines[i].amount.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: scheme.error,
                      onPressed: () => _removeLine(i),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _addLine() => setState(() => _lines.add(_RequirementLine()));

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Map<String, dynamic> _payload() => {
        'companyName': _company.text.trim(),
        'contactName': _contact.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'gstNumber': _gst.text.trim(),
        'source': _source,
        'clientType': _clientType,
        'temperature': _temperature,
        'requirements': _requirement.text.trim(),
        'requirementLines':
            _addProducts ? _lines.map((l) => l.toJson()).toList() : [],
        'repeatFrequency': _repeatFreq,
        'value': double.tryParse(_value.text) ?? 0,
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_addProducts) {
      for (final line in _lines) {
        if (line._description.text.trim().isEmpty) {
          setState(() => _error = 'Enter a description for every product line');
          return;
        }
        final rate = double.tryParse(line._rate.text) ?? 0;
        if (rate <= 0) {
          setState(
            () => _error = 'Rate must be greater than 0 for every product line',
          );
          return;
        }
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final notifier = ref.read(salesWorkspaceProvider.notifier);
      if (_isEdit) {
        await notifier.updateLead(_leadId!, _payload());
      } else {
        await notifier.createLead(_payload());
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Retry prefill once workspace data arrives for edit mode.
    if (_isEdit && !_prefilled) {
      final lead = ref.watch(crmLeadByIdProvider(_leadId!));
      if (lead != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_prefilled && mounted) {
            setState(() {
              _prefill(lead);
              _prefilled = true;
            });
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Lead' : 'Add Lead')),
      // KEY FIX: no bottomNavigationBar. Button ab Column ke andar fixed
      // footer hai, jo keyboard ke hisaab se khud adjust hota hai.
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Text(
                      'Contact & requirements',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _sectionCard(
                      context,
                      'Company details',
                      Icons.apartment_outlined,
                      [
                        _responsiveRow([
                          _textField(
                            controller: _company,
                            label: 'Company',
                            required: true,
                            hint: 'Company name',
                          ),
                          _phoneField(),
                        ]),
                        _responsiveRow([
                          _dropdown(
                            label: 'Source',
                            value: _source,
                            items: _sourceOptions,
                            onChanged: (v) => setState(() => _source = v!),
                          ),
                          _textField(
                            controller: _contact,
                            label: 'Contact',
                            required: true,
                            hint: 'Person name',
                          ),
                        ]),
                        _textField(
                          controller: _email,
                          label: 'Email',
                          required: true,
                          hint: 'email@company.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            final ok = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(v.trim());
                            return ok ? null : 'Enter a valid email';
                          },
                        ),
                        _responsiveRow([
                          _textField(
                            controller: _address,
                            label: 'Address',
                            required: true,
                            hint: 'Billing / site address',
                            maxLines: 3,
                          ),
                          _textField(
                            controller: _gst,
                            label: 'Customer GSTIN',
                            required: false,
                            hint: '22AAAAA0000A1Z5 (optional)',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final ok = RegExp(
                                r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                              ).hasMatch(v.trim().toUpperCase());
                              return ok ? null : 'Enter a valid GSTIN';
                            },
                          ),
                        ]),
                        _responsiveRow([
                          _dropdown(
                            label: 'Type',
                            value: _clientType,
                            items: _clientTypeOptions,
                            onChanged: (v) => setState(() => _clientType = v!),
                          ),
                          _dropdown(
                            label: 'Temp',
                            value: _temperature,
                            items: _temperatureOptions,
                            onChanged: (v) => setState(() => _temperature = v!),
                          ),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      context,
                      'Requirement',
                      Icons.assignment_outlined,
                      [
                        SwitchListTile(
                          value: _addProducts,
                          onChanged: (v) => setState(() {
                            _addProducts = v;
                            if (_addProducts && _lines.isEmpty) _addLine();
                          }),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Add products'),
                          subtitle: const Text(
                            'Break requirement into line items',
                          ),
                        ),
                        if (_addProducts) ...[
                          Builder(
                            builder: (context) {
                              final productsAsync =
                                  ref.watch(crmProductsProvider);
                              return productsAsync.when(
                                data: (products) =>
                                    _buildProductLines(context, products),
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                error: (e, _) => _buildProductLines(
                                  context,
                                  const [],
                                  loadError: true,
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addLine,
                              icon: const Icon(Icons.add),
                              label: const Text('Add another product'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: ₹${_lines.fold<double>(0, (s, l) => s + l.amount).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        _textField(
                          controller: _requirement,
                          label: 'Requirement',
                          required: true,
                          hint: 'Demand, qty, delivery…',
                          maxLines: 4,
                        ),
                        _responsiveRow([
                          _dropdown(
                            label: 'Repeat freq.',
                            value: _repeatFreq,
                            items: _repeatFreqOptions,
                            onChanged: (v) => setState(() => _repeatFreq = v!),
                          ),
                          _textField(
                            controller: _value,
                            label: 'Value (₹)',
                            required: false,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ]),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: scheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Fixed footer button — animates with keyboard, never gets cut.
              // KEYBOARD HYDE / SHOW FIX:
              // Agar keyboard khula hai (bottomInset > 0) toh button dikhane ki zaroorat nahi hai.
              if (bottomInset == 0)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Update lead' : 'Save lead',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children.map(
            (c) =>
                Padding(padding: const EdgeInsets.only(bottom: 14), child: c),
          ),
        ],
      ),
    );
  }

  Widget _responsiveRow(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: f,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: fields[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required bool required,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      validator:
          validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        labelText: 'Phone *',
        hintText: '10-digit mobile',
        prefixText: '+91  ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        counterText: '',
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        return RegExp(r'^[0-9]{10}$').hasMatch(v.trim())
            ? null
            : 'Enter 10 digit number';
      },
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: '$label *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}