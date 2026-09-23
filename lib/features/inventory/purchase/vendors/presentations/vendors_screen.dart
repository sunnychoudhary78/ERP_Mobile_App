import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/purchase/vendors/data/model/vendor_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(authProvider).canAny(AppPermissions.vendorsManage);
    final result = ref.watch(vendorsProvider(VendorListQuery(search: _search)));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Vendors')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search vendors',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(
                  vendorsProvider(VendorListQuery(search: _search)),
                ),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  vendorsProvider(VendorListQuery(search: _search)),
                ),
                child: page.vendors.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No vendors found')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                        itemCount: page.vendors.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _VendorCard(
                          vendor: page.vendors[index],
                          canManage: canManage,
                          onTap: () => _showDetails(page.vendors[index]),
                          onEdit: () => _openForm(page.vendors[index]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(Vendor vendor) async {
    final detail = await ref.read(vendorProvider(vendor.id).future);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(detail.name),
        content: SingleChildScrollView(
          child: SelectableText([
            'Email: ${detail.email}',
            'Phone: ${detail.phone}',
            'Address: ${detail.address}',
            if (detail.gstNumber?.isNotEmpty == true) 'GST: ${detail.gstNumber}',
            if (detail.panNumber?.isNotEmpty == true) 'PAN: ${detail.panNumber}',
            if (detail.tdsSectionCode?.isNotEmpty == true)
              'TDS section: ${detail.tdsSectionCode}',
            if (detail.documents.isNotEmpty)
              'Documents: ${detail.documents.length}',
          ].join('\n\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm([Vendor? vendor]) async {
    final result = await showModalBottomSheet<_VendorFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VendorForm(vendor: vendor),
    );
    if (result == null || !mounted) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final response = vendor == null
          ? await repo.createVendor(result.body)
          : await repo.updateVendor(vendor.id, result.body);
        if (!mounted) return;
      ref.invalidate(vendorsProvider(VendorListQuery(search: _search)));
      final approval = response['approvalId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approval != null
                ? 'Vendor sent for approval'
                : vendor == null
                    ? 'Vendor created'
                    : 'Vendor updated',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _VendorCard({
    required this.vendor,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
        title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${vendor.email}\n${vendor.phone}'),
        isThreeLine: true,
        trailing: canManage
            ? IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit vendor',
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _VendorFormResult {
  final Map<String, dynamic> body;

  const _VendorFormResult(this.body);
}

class _VendorForm extends StatefulWidget {
  final Vendor? vendor;

  const _VendorForm({this.vendor});

  @override
  State<_VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<_VendorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _gst;
  late final TextEditingController _pan;
  late final TextEditingController _tds;

  @override
  void initState() {
    super.initState();
    final vendor = widget.vendor;
    _name = TextEditingController(text: vendor?.name);
    _email = TextEditingController(text: vendor?.email);
    _phone = TextEditingController(text: vendor?.phone);
    _address = TextEditingController(text: vendor?.address);
    _gst = TextEditingController(text: vendor?.gstNumber);
    _pan = TextEditingController(text: vendor?.panNumber);
    _tds = TextEditingController(text: vendor?.tdsSectionCode);
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _address, _gst, _pan, _tds]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.vendor == null ? 'Add vendor' : 'Edit vendor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _field(_name, 'Name', required: true),
              _field(_email, 'Email', required: true, keyboard: TextInputType.emailAddress),
              _field(_phone, 'Phone', required: true, keyboard: TextInputType.phone),
              _field(_address, 'Address', required: true, maxLines: 2),
              _field(_gst, 'GST number'),
              _field(_pan, 'PAN number'),
              _field(_tds, 'TDS section code'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    _VendorFormResult({
                      'name': _name.text.trim(),
                      'email': _email.text.trim(),
                      'phone': _phone.text.trim(),
                      'address': _address.text.trim(),
                      if (_gst.text.trim().isNotEmpty) 'gstNumber': _gst.text.trim(),
                      if (_pan.text.trim().isNotEmpty) 'panNumber': _pan.text.trim(),
                      if (_tds.text.trim().isNotEmpty) 'tdsSectionCode': _tds.text.trim(),
                    }),
                  );
                },
                child: Text(widget.vendor == null ? 'Create vendor' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
