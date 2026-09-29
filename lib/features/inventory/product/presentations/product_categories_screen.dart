import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/product/data/model/product_category_model.dart';
import 'package:erp_app/features/inventory/product/data/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductCategoriesScreen extends ConsumerStatefulWidget {
  const ProductCategoriesScreen({super.key});

  @override
  ConsumerState<ProductCategoriesScreen> createState() =>
      _ProductCategoriesScreenState();
}

class _ProductCategoriesScreenState
    extends ConsumerState<ProductCategoriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canManage =>
      ref.read(authProvider).canAny(AppPermissions.productCategoriesManage);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productCategoriesManagementProvider);
    final canView = ref.watch(authProvider).canAny(AppPermissions.productCategories);

    if (!canView) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text(
            "You don't have permission to view categories",
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        centerTitle: true,
        title: const Text(
          'Product Categories',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('New Category'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref
                  .read(productCategoriesManagementProvider.notifier)
                  .search(value),
              decoration: InputDecoration(
                hintText: 'Search categories, type, or HSN/SAC',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(productCategoriesManagementProvider.notifier)
                              .search('');
                          setState(() {});
                        },
                        icon: Icon(Icons.clear, color: AppColors.muted),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProductCategoriesState state) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.categories.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref
            .read(productCategoriesManagementProvider.notifier)
            .load(),
      );
    }

    final categories = state.filteredCategories;
    if (categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(productCategoriesManagementProvider.notifier)
            .load(),
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Icon(Icons.category_outlined, size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No product categories found',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(productCategoriesManagementProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _CategoryCard(
          category: categories[index],
          canManage: _canManage,
          onEdit: () => _openForm(context, category: categories[index]),
          onDelete: () => _deleteCategory(categories[index]),
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    ProductCategory? category,
  }) async {
    final result = await showModalBottomSheet<_CategoryFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryForm(category: category),
    );
    if (result == null || !mounted) return;

    try {
      final notifier = ref.read(productCategoriesManagementProvider.notifier);
      final response = category == null
          ? await notifier.create(result.body)
          : await notifier.update(category.id, result.body);
      final approval = response['approvalId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approval != null
                ? 'Category sent for approval'
                : category == null
                    ? 'Category created'
                    : 'Category updated',
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteCategory(ProductCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final response = await ref
          .read(productCategoriesManagementProvider.notifier)
          .delete(category.id);
      final approval = response['approvalId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approval != null
                ? 'Category deletion sent for approval'
                : 'Category deleted',
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProductCategory category;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = category.status.toUpperCase();
    final active = status == 'ACTIVE';
    final statusColor = active ? const Color(0xFF2E7D32) : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: 'serif',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (category.type?.isNotEmpty == true) category.type!,
                    'HSN/SAC: ${category.hsnSac ?? '-'}',
                  ].join('   ·   '),
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.text),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFormResult {
  final Map<String, dynamic> body;

  const _CategoryFormResult(this.body);
}

class _CategoryForm extends StatefulWidget {
  final ProductCategory? category;

  const _CategoryForm({this.category});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  static const _categoryTypes = [
    'Raw Material',
    'Finished Product',
    'Semi Finished',
    'Consumable',
    'Service',
    'General',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hsnController;
  late String _type;
  late String _status;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _type = category?.type?.trim().isNotEmpty == true
        ? category!.type!.trim()
        : 'General';
    _hsnController = TextEditingController(text: category?.hsnSac ?? '');
    _status = category?.status.toUpperCase() ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.accent, width: 1.4),
      ),
    );
  }

  /// RAW_MATERIAL -> Raw Material (display only, the stored value is unchanged)
  String _pretty(String value) {
    if (!value.contains('_') && value != value.toUpperCase()) return value;
    return value
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // When the keyboard is closed keep clear of the gesture/nav bar.
    final bottomSafe = keyboard > 0 ? 0.0 : media.viewPadding.bottom;

    final typeOptions = <_PickerOption>[
      ..._categoryTypes.map((t) => _PickerOption(t, t)),
      if (!_categoryTypes.contains(_type))
        _PickerOption(_type, _pretty(_type)),
    ];

    // The keyboard lifts the whole sheet. The sheet itself scrolls if the
    // content is taller than the space that is left above the keyboard.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed header (does not scroll away)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      widget.category == null
                          ? 'Add Category'
                          : 'Edit Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: AppColors.accent.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              // Scrollable fields
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomSafe),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        decoration: _decoration('Name', required: true),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _PickerField(
                        title: 'Type',
                        decoration: _decoration('Type'),
                        value: _type,
                        displayText: _pretty(_type),
                        options: typeOptions,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hsnController,
                        keyboardType: TextInputType.number,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        decoration: _decoration('HSN/SAC', required: true),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'HSN/SAC is required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _PickerField(
                        title: 'Status',
                        decoration: _decoration('Status'),
                        value: _status,
                        displayText: _status == 'ACTIVE' ? 'Active' : 'Inactive',
                        options: const [
                          _PickerOption('ACTIVE', 'Active'),
                          _PickerOption('INACTIVE', 'Inactive'),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _submit,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.category == null
                              ? 'Create Category'
                              : 'Save Changes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CategoryFormResult({
        'name': _nameController.text.trim(),
        'type': _type,
        'status': _status,
        'hsnSac': _hsnController.text.trim(),
      }),
    );
  }
}

class _PickerOption {
  final String value;
  final String label;

  const _PickerOption(this.value, this.label);
}

/// Replacement for DropdownButtonFormField.
///
/// A normal dropdown anchors its popup to the field's position at the moment
/// it opens. If the keyboard is open, it closes right after and the sheet
/// slides down, so the popup ends up in the wrong place (jumps upward).
/// Here we close the keyboard first, wait for the layout to settle, and then
/// show a bottom-anchored picker that is never affected by the keyboard.
class _PickerField extends StatelessWidget {
  final String title;
  final InputDecoration decoration;
  final String value;
  final String displayText;
  final List<_PickerOption> options;
  final ValueChanged<String> onChanged;

  const _PickerField({
    required this.title,
    required this.decoration,
    required this.value,
    required this.displayText,
    required this.options,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final keyboardWasOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    FocusManager.instance.primaryFocus?.unfocus();
    if (keyboardWasOpen) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Select $title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(option.label),
                      trailing: option.value == value
                          ? Icon(Icons.check, color: AppColors.accent)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, option.value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: decoration.copyWith(
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
        ),
        child: Text(
          displayText,
          style: TextStyle(fontSize: 16, color: AppColors.text),
        ),
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
            Icon(Icons.error_outline, size: 36, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
