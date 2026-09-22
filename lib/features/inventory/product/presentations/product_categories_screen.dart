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
      return const Scaffold(
        body: Center(child: Text("You don't have permission to view categories")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Product Categories')),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref
                  .read(productCategoriesManagementProvider.notifier)
                  .search(value),
              decoration: InputDecoration(
                hintText: 'Search categories, type, or HSN/SAC',
                prefixIcon: const Icon(Icons.search),
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
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No product categories found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(productCategoriesManagementProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text([
            if (category.type?.isNotEmpty == true) category.type!,
            'HSN/SAC: ${category.hsnSac ?? '-'}',
          ].join('  |  ')),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (active ? Colors.green : Colors.grey).withOpacity(.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: active ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canManage) ...[
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.category == null ? 'Add Category' : 'Edit Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hsnController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'HSN/SAC *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'HSN/SAC is required'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.category == null ? 'Create Category' : 'Save Changes'),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
