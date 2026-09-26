import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/purchase/vendors/data/model/vendor_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final canManage = ref
        .watch(authProvider)
        .canAny(AppPermissions.vendorsManage);
    final result = ref.watch(vendorsProvider(VendorListQuery(search: _search)));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendors',
              style: TextStyle(
                color: Color(0xFF17202A),
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Manage your supplier directory',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE9ECEF)),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              elevation: 4,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 21),
              label: const Text(
                'Add vendor',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by vendor name, email or phone',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 13.5),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF697386),
                    size: 21,
                  ),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF697386),
                            size: 19,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: result.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              error: (error, _) => _ErrorView(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(
                  vendorsProvider(VendorListQuery(search: _search)),
                ),
              ),
              data: (page) => RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: Colors.white,
                onRefresh: () async => ref.invalidate(
                  vendorsProvider(VendorListQuery(search: _search)),
                ),
                child: page.vendors.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 90),
                          Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.symmetric(horizontal: 150),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.storefront_outlined,
                              size: 34,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              _search.isEmpty
                                  ? 'No vendors added yet'
                                  : 'No vendors found',
                              style: const TextStyle(
                                color: Color(0xFF17202A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              _search.isEmpty
                                  ? 'Add your first vendor to get started.'
                                  : 'Try a different search term.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                        itemCount: page.vendors.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        detail.name.trim().isEmpty
                            ? 'V'
                            : detail.name.trim()[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF17202A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Vendor details',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF697386),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 390),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            value: detail.email,
                          ),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: detail.phone,
                          ),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: detail.address,
                          ),
                          if (detail.gstNumber?.isNotEmpty == true)
                            _DetailRow(
                              icon: Icons.receipt_long_outlined,
                              label: 'GST number',
                              value: detail.gstNumber!,
                            ),
                          if (detail.panNumber?.isNotEmpty == true)
                            _DetailRow(
                              icon: Icons.badge_outlined,
                              label: 'PAN number',
                              value: detail.panNumber!,
                            ),
                          if (detail.tdsSectionCode?.isNotEmpty == true)
                            _DetailRow(
                              icon: Icons.description_outlined,
                              label: 'TDS section',
                              value: detail.tdsSectionCode!,
                            ),
                          if (detail.documents.isNotEmpty)
                            _DetailRow(
                              icon: Icons.folder_outlined,
                              label: 'Documents',
                              value: '${detail.documents.length}',
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4E5968),
                      side: const BorderSide(color: Color(0xFFE0E4E9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openForm([Vendor? vendor]) async {
    final result = await showModalBottomSheet<_VendorFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

      debugPrint('Vendor create/update response:-->>>> $response');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      debugPrint('Error creating/updating vendor:----->>>>>>> $error');
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEEF0F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8993A1),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF303945),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final initial = vendor.name.trim().isEmpty
        ? 'V'
        : vendor.name.trim()[0].toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E8EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17202A),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 15,
                          color: Color(0xFF7A8492),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vendor.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF697386),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: Color(0xFF7A8492),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vendor.phone,
                          style: const TextStyle(
                            color: Color(0xFF697386),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (canManage)
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit vendor',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F6F8),
                    foregroundColor: const Color(0xFF4E5968),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA3ABB5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF303945),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8993A1), fontSize: 11.5),
        ),
      ],
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
    for (final controller in [
      _name,
      _email,
      _phone,
      _address,
      _gst,
      _pan,
      _tds,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vendor != null;

    return _KeyboardInsetPadding(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DAE0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_outlined
                            : Icons.storefront_outlined,
                        color: AppColors.accent,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit vendor' : 'Add vendor',
                            style: const TextStyle(
                              color: Color(0xFF17202A),
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Update vendor information'
                                : 'Enter the vendor details below',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _FormSectionTitle(
                  title: 'Basic information',
                  subtitle: 'Contact details required for the vendor',
                ),
                const SizedBox(height: 13),
                _field(
                  _name,
                  'Name',
                  required: true,
                  icon: Icons.business_outlined,
                ),
                _field(
                  _email,
                  'Email',
                  required: true,
                  keyboard: TextInputType.emailAddress,
                  icon: Icons.mail_outline_rounded,
                ),
                _field(
                  _phone,
                  'Phone',
                  required: true,
                  keyboard: TextInputType.phone,
                  icon: Icons.phone_outlined,
                ),
                _field(
                  _address,
                  'Address',
                  required: true,
                  maxLines: 2,
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 5),
                const _FormSectionTitle(
                  title: 'Tax & compliance',
                  subtitle: 'Optional registration and tax information',
                ),
                const SizedBox(height: 13),
                _field(
                  _gst,
                  'GST number',
                  icon: Icons.receipt_long_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                _field(
                  _pan,
                  'PAN number',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                _field(
                  _tds,
                  'TDS section code',
                  icon: Icons.description_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        _VendorFormResult({
                          'name': _name.text.trim(),
                          'email': _email.text.trim(),
                          'phone': _phone.text.trim(),
                          'address': _address.text.trim(),
                          if (_gst.text.trim().isNotEmpty)
                            'gstNumber': _gst.text.trim(),
                          if (_pan.text.trim().isNotEmpty)
                            'panNumber': _pan.text.trim(),
                          if (_tds.text.trim().isNotEmpty)
                            'tdsSectionCode': _tds.text.trim(),
                        }),
                      );
                    },
                    icon: Icon(
                      isEditing ? Icons.check_rounded : Icons.add_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isEditing ? 'Save changes' : 'Create vendor',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    IconData? icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    String? Function(String?)? validator;

    if (label == 'Email') {
      validator = (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) {
          return required ? 'Email is required' : null;
        }
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        return emailRegex.hasMatch(email)
            ? null
            : 'Enter a valid email address';
      };
    } else if (label == 'Phone') {
      validator = (value) {
        final phone = value?.trim() ?? '';
        if (phone.isEmpty) {
          return required ? 'Phone number is required' : null;
        }
        return RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)
            ? null
            : 'Enter a valid 10-digit phone number';
      };
    } else {
      validator = required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
          : null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        inputFormatters: label == 'Phone'
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        style: const TextStyle(
          color: Color(0xFF17202A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Color(0xFF7A8492),
                    fontSize: 13.5,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 13, right: 9),
                  child: Icon(icon, size: 19, color: const Color(0xFF7A8492)),
                ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 45,
            minHeight: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE0E4E9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE0E4E9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.accent, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFD64545)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.3),
          ),
          errorStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

/// Isolates the keyboard-inset read so only this small wrapper rebuilds
/// on keyboard-animation frames, instead of the whole form.
// class _KeyboardInsetPadding extends StatelessWidget {
//   final Widget child;

//   const _KeyboardInsetPadding({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
//     return AnimatedPadding(
//       padding: EdgeInsets.only(bottom: bottomInset),
//       duration: const Duration(milliseconds: 120),
//       curve: Curves.easeOut,
//       child: child,
//     );
//   }
// }

class _KeyboardInsetPadding extends StatelessWidget {
  final Widget child;

  const _KeyboardInsetPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: child,
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
            Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
