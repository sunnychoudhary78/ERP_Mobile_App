import 'package:erp_app/features/crm/shared/data/models/sales_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/theme/app_theme.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({super.key});

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteLineItem {
  String? product;
  final TextEditingController item = TextEditingController();
  final TextEditingController hsn = TextEditingController();
  final TextEditingController unit = TextEditingController();
  final TextEditingController articleNo = TextEditingController();
  final TextEditingController type = TextEditingController();
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController rate = TextEditingController(text: '0');

  double get amount {
    final q = double.tryParse(qty.text.trim()) ?? 0;
    final r = double.tryParse(rate.text.trim()) ?? 0;
    return q * r;
  }

  Map<String, dynamic> toJson() => {
        'product': product,
        'item': item.text.trim(),
        'hsn': hsn.text.trim(),
        'unit': unit.text.trim(),
        'articleNo': articleNo.text.trim(),
        'type': type.text.trim(),
        'qty': double.tryParse(qty.text.trim()) ?? 0,
        'rate': double.tryParse(rate.text.trim()) ?? 0,
        'amount': amount,
      };

  void dispose() {
    item.dispose();
    hsn.dispose();
    unit.dispose();
    articleNo.dispose();
    type.dispose();
    qty.dispose();
    rate.dispose();
  }
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _leadId = TextEditingController();

  bool _leadPrefilled = false;
  final _clientEmail = TextEditingController();
  final _address = TextEditingController();
  final _gstNumber = TextEditingController();
  final _gstRate = TextEditingController(text: '18');

  String? _paymentTerms = _paymentTermsOptions.first;
  String? _deliveryFreight = _deliveryFreightOptions.first;
  String? _dispatchMode = _dispatchModeOptions.first;

  final _transportDetails = TextEditingController();
  final List<_QuoteLineItem> _lineItems = [_QuoteLineItem()];

  final _validForDays = TextEditingController(text: '30');
  final _notes = TextEditingController();

  bool _submitting = false;
  String? _message;

  static const List<String> _paymentTermsOptions = [
    'Net 15 days from invoice date',
    'Net 30 days from invoice date',
    'Net 45 days from invoice date',
    'Net 60 days from invoice date',
    '50% advance, balance on delivery',
    'Payment against delivery (COD)',
    '100% advance',
  ];

  static const List<String> _deliveryFreightOptions = [
    'Freight paid by customer (buyer)',
    'Freight paid by seller (included)',
    'Freight to pay (collect)',
    'Ex-works (customer arranges pickup)',
  ];

  static const List<String> _dispatchModeOptions = [
    'Delivery to customer site',
    'Customer pickup from warehouse',
    'Courier / parcel service',
    'Third-party transporter',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _leadId.text.isEmpty) {
      _leadId.text = arg;
    }
  }

  @override
  void dispose() {
    _leadId.dispose();
    _clientEmail.dispose();
    _address.dispose();
    _gstNumber.dispose();
    _gstRate.dispose();
    _transportDetails.dispose();
    _validForDays.dispose();
    _notes.dispose();
    for (final line in _lineItems) {
      line.dispose();
    }
    super.dispose();
  }

  void _maybePrefillFromLead(dynamic lead) {
    if (lead == null || _leadPrefilled) return;
    _leadPrefilled = true;
    _clientEmail.text = (lead.email ?? '').toString();
    _address.text = (lead.address ?? '').toString();
    final gst = (lead.gstNumber ?? '').toString();
    if (gst.isNotEmpty && gst != 'null') {
      _gstNumber.text = gst;
    }
  }

  double get _subtotal =>
      _lineItems.fold<double>(0, (sum, line) => sum + line.amount);

  double get _gstAmount =>
      _subtotal * ((double.tryParse(_gstRate.text.trim()) ?? 0) / 100);

  double get _grandTotal => _subtotal + _gstAmount;

  void _addLineItem() {
    setState(() => _lineItems.add(_QuoteLineItem()));
  }

  void _removeLineItem(int index) {
    if (_lineItems.length == 1) return;
    setState(() {
      _lineItems.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    final leadId = _leadId.text.trim();
    if (leadId.isEmpty) {
      setState(() => _message = 'leadId is required');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _message = 'Please fill all required fields');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      await ref.read(salesWorkspaceProvider.notifier).createQuote(leadId, {
        'clientEmail': _clientEmail.text.trim(),
        'account': _clientEmail.text.trim(),
        'address': _address.text.trim(),
        'gstNumber': _gstNumber.text.trim(),
        'gstRate': double.tryParse(_gstRate.text.trim()) ?? 0,
        'paymentTerms': _paymentTerms,
        'deliveryFreight': _deliveryFreight,
        'dispatchMode': _dispatchMode,
        'transportDetails': _transportDetails.text.trim(),
        'validForDays': int.tryParse(_validForDays.text.trim()) ?? 30,
        'notes': _notes.text.trim(),
        'subtotal': _subtotal,
        'gstAmount': _gstAmount,
        'amount': _grandTotal,
        'lines': _lineItems.map((l) => l.toJson()).toList(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(crmProductsProvider);
    final leadId = _leadId.text.trim();
    final lead = leadId.isEmpty ? null : ref.watch(crmLeadByIdProvider(leadId));
    _maybePrefillFromLead(lead);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Create Quotation'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _sectionCard(
              title: 'Customer Details',
              children: [
                _leadCustomerHeader(lead),
                _label('Client email'),
                _textField(
                  controller: _clientEmail,
                  hint: 'name@company.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                _label('Address'),
                _textField(
                  controller: _address,
                  hint: 'Delivery / billing address',
                  maxLines: 2,
                  enabled: false,
                ),
                _label('Customer GSTIN'),
                _textField(
                  controller: _gstNumber,
                  hint: '29AAAAA0000A1Z5',
                  textCapitalization: TextCapitalization.characters,
                  enabled: false,
                ),
                _label('GST rate (%)'),
                _textField(
                  controller: _gstRate,
                  hint: '18',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Commercial Terms',
              children: [
                _label('Payment terms'),
                _dropdown(
                  value: _paymentTerms,
                  items: _paymentTermsOptions,
                  onChanged: (v) => setState(() => _paymentTerms = v),
                ),
                _label('Delivery / freight'),
                _dropdown(
                  value: _deliveryFreight,
                  items: _deliveryFreightOptions,
                  onChanged: (v) => setState(() => _deliveryFreight = v),
                ),
                _label('Dispatch mode'),
                _dropdown(
                  value: _dispatchMode,
                  items: _dispatchModeOptions,
                  onChanged: (v) => setState(() => _dispatchMode = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              titleIcon: Icons.local_shipping_outlined,
              title: 'Transport Details',
              children: [
                _label('Transport details (optional)'),
                _textField(
                  controller: _transportDetails,
                  hint: 'Transporter name, vehicle, pickup point...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PRODUCT SECTION WITH WORKING ADD BUTTON & WEB-MATCHED UI
            _sectionCard(
              title: 'Products',
              titleRequired: true,
              trailing: _addButton(),
              children: [
                for (var i = 0; i < _lineItems.length; i++) ...[
                  _productCard(i, productsAsync),
                  if (i != _lineItems.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),

            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _label('Valid for (days)'),
                _textField(
                  controller: _validForDays,
                  hint: '30',
                  keyboardType: TextInputType.number,
                ),
                _label('Notes (internal)'),
                _textField(
                  controller: _notes,
                  hint: 'Enter private notes here...',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _summaryCard(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _submitting ? null : () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _submitting ? 'Creating…' : 'Create quote',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI Components ──────────────────────────────────────────────

  Widget _sectionCard({
    String? title,
    IconData? titleIcon,
    bool titleRequired = false,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, size: 18, color: AppColors.text),
                      const SizedBox(width: 8),
                    ],
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(text: title),
                          if (titleRequired)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.danger),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }

  // Add Product Button
  Widget _addButton() {
    return ElevatedButton.icon(
      onPressed: _addLineItem,
      icon: const Icon(Icons.add, size: 16, color: AppColors.primaryDark),
      label: const Text(
        'Add product',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark.withOpacity(0.08),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13.5),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String hint = 'Select',
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _leadCustomerHeader(dynamic lead) {
    String name = 'No lead linked';
    if (lead != null) {
      final company = (lead.companyName ?? '').toString();
      final contact = (lead.contactName ?? '').toString();
      name = company.isNotEmpty ? company : (contact.isNotEmpty ? contact : 'N/A');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_outlined,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create quotation',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Web exact-matching Product Line Card
  Widget _productCard(
    int index,
    AsyncValue<List<InventoryProductItem>> productsAsync,
  ) {
    final line = _lineItems[index];
    final products = productsAsync.asData?.value ?? const [];
    final productNames = products.map((p) => p.name).toList();
    final isLoading = productsAsync.isLoading && products.isEmpty;
    final hasError = productsAsync.hasError && products.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product Dropdown & Item Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Product'),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Could not load products',
                                style: TextStyle(color: AppColors.danger, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.read(crmProductsProvider.notifier).refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else
                      _dropdown(
                        value: line.product,
                        items: productNames,
                        hint: 'Pick product',
                        onChanged: (v) {
                          setState(() {
                            line.product = v;
                            if (v == null) return;

                            InventoryProductItem? selected;
                            for (final p in products) {
                              if (p.name == v) {
                                selected = p;
                                break;
                              }
                            }
                            if (selected == null) return;

                            line.item.text = selected.name;
                            line.hsn.text = selected.hsn;
                            line.unit.text = selected.unit;
                            line.articleNo.text = selected.articleNo;
                            line.type.text = selected.type;
                            if (selected.rate > 0) {
                              line.rate.text = selected.rate % 1 == 0
                                  ? selected.rate.toStringAsFixed(0)
                                  : selected.rate.toString();
                            }
                            if (line.qty.text.trim().isEmpty) {
                              line.qty.text = '1';
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                        children: [
                          TextSpan(text: 'Item'),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _textField(
                      controller: line.item,
                      hint: 'Description',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Row 2: HSN / SAC & Unit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('HSN / SAC'),
                    _textField(controller: line.hsn, hint: '8471'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unit'),
                    _textField(controller: line.unit, hint: 'Nos, Kg, Roll...'),
                  ],
                ),
              ),
            ],
          ),

          // Row 3: Article No. & Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Article No.'),
                    _textField(controller: line.articleNo, hint: 'SKU / code'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Type'),
                    _textField(controller: line.type, hint: 'Variant / grade'),
                  ],
                ),
              ),
            ],
          ),

          // Row 4: Qty, Rate, Amt & Delete Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                        children: [
                          TextSpan(text: 'Qty'),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _textField(
                      controller: line.qty,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                        children: [
                          TextSpan(text: 'Rate (₹)'),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _textField(
                      controller: line.rate,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Amt'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '₹${line.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Delete Button matching Web UI Trash icon
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: IconButton(
                  onPressed: _lineItems.length > 1
                      ? () => _removeLineItem(index)
                      : null,
                  icon: Icon(
                    Icons.delete_outline,
                    color: _lineItems.length > 1
                        ? AppColors.danger
                        : AppColors.muted.withOpacity(0.5),
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    side: BorderSide(
                      color: _lineItems.length > 1
                          ? AppColors.danger.withOpacity(0.3)
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _subtotal),
          const SizedBox(height: 8),
          _summaryRow(
            'GST (${_gstRate.text.trim().isEmpty ? '0' : _gstRate.text.trim()}%)',
            _gstAmount,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _summaryRow('Grand total', _grandTotal, emphasize: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool emphasize = false}) {
    final style = emphasize
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          )
        : const TextStyle(fontSize: 13.5, color: AppColors.muted);
    final valueStyle = emphasize
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          )
        : const TextStyle(fontSize: 13.5, color: AppColors.text);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₹${value.toStringAsFixed(0)}', style: valueStyle),
      ],
    );
  }
}