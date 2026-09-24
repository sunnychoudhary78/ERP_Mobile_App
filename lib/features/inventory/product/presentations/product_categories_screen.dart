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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _hsnController;
  late String _status;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _typeController = TextEditingController(text: category?.type ?? '');
    _hsnController = TextEditingController(text: category?.hsnSac ?? '');
    _status = category?.status.toUpperCase() ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  widget.category == null ? 'Add Category' : 'Edit Category',
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
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: _decoration('Name', required: true),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeController,
                  decoration: _decoration('Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hsnController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('HSN/SAC', required: true),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'HSN/SAC is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _decoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
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
                    widget.category == null ? 'Create Category' : 'Save Changes',
                  ),
                ),
              ],
            ),
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
        if (_typeController.text.trim().isNotEmpty)
          'type': _typeController.text.trim(),
        'status': _status,
        'hsnSac': _hsnController.text.trim(),
      }),
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