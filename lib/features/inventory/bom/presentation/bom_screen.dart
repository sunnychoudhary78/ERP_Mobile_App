import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/bom/presentation/bom_provider.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BomScreen extends ConsumerStatefulWidget {
  const BomScreen({super.key});

  @override
  ConsumerState<BomScreen> createState() => _BomScreenState();
}

class _BomScreenState extends ConsumerState<BomScreen> {
  final _searchController = TextEditingController();

  bool get _canManage => ref.read(authProvider).canAny(const [
    AppPermissions.bomManage,
    AppPermissions.productManage,
  ]);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bomProvider);
    final canView = ref.watch(authProvider).canAny(AppPermissions.bomAccess);
    if (!canView) {
      return const Scaffold(
        body: Center(child: Text("You don't have permission to view BOMs")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Bill of Materials')),
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
              onChanged: (value) {
                ref.read(bomProvider.notifier).search(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search BOM by finished item',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bomProvider.notifier).search('');
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

  Widget _buildBody(BomState state) {
    if (state.isLoading && state.boms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.boms.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(bomProvider.notifier).load(),
      );
    }
    final boms = state.filteredBoms;
    if (boms.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(bomProvider.notifier).load(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No BOMs found')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(bomProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: boms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final bom = boms[index];
          return _BomCard(
            bom: bom,
            canManage: _canManage,
            onEdit: () => _openForm(context, bom: bom),
            onDelete: () => _deleteBom(bom),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {BillOfMaterials? bom}) async {
    final result = await showModalBottomSheet<_BomFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BomForm(bom: bom),
    );
    if (result == null || !mounted) return;
    try {
      final notifier = ref.read(bomProvider.notifier);
      final response = bom == null
          ? await notifier.create(result.body)
          : await notifier.update(bom.id, result.body);
      final approval = response['approvalId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approval != null
                ? 'BOM sent for approval'
                : bom == null
                ? 'BOM created'
                : 'BOM updated',
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteBom(BillOfMaterials bom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete BOM?'),
        content: Text('Delete the BOM for "${bom.item?.name ?? 'this item'}"?'),
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
      final response = await ref.read(bomProvider.notifier).delete(bom.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['approvalId'] != null
                ? 'BOM deletion sent for approval'
                : 'BOM deleted',
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

class _BomCard extends StatelessWidget {
  final BillOfMaterials bom;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BomCard({
    required this.bom,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        title: Text(
          bom.item?.name ?? 'Item #${bom.itemId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${bom.materials.length} material${bom.materials.length == 1 ? '' : 's'}'
          '${bom.description?.isNotEmpty == true ? '  |  ${bom.description}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: canManage
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _BomFormResult {
  final Map<String, dynamic> body;

  const _BomFormResult(this.body);
}

class _MaterialDraft {
  int? itemId;
  final quantity = TextEditingController();
  final uom = TextEditingController();
  final scrapPct = TextEditingController(text: '0');
  final consumptionFactor = TextEditingController(text: '1');
  final componentType = TextEditingController(text: 'RM');

  _MaterialDraft({BomMaterial? material}) {
    if (material != null) {
      itemId = material.itemId;
      quantity.text = '${material.quantity}';
      uom.text = material.uom ?? '';
      scrapPct.text = '${material.scrapPct}';
      consumptionFactor.text = '${material.consumptionFactor}';
      componentType.text = material.componentType ?? 'RM';
    }
  }

  void dispose() {
    quantity.dispose();
    uom.dispose();
    scrapPct.dispose();
    consumptionFactor.dispose();
    componentType.dispose();
  }
}

class _BomForm extends ConsumerStatefulWidget {
  final BillOfMaterials? bom;

  const _BomForm({this.bom});

  @override
  ConsumerState<_BomForm> createState() => _BomFormState();
}

class _BomFormState extends ConsumerState<_BomForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  int? _itemId;
  late final List<_MaterialDraft> _materials;

  @override
  void initState() {
    super.initState();
    _itemId = widget.bom?.itemId;
    _descriptionController = TextEditingController(
      text: widget.bom?.description ?? '',
    );
    _materials =
        widget.bom?.materials
            .map((material) => _MaterialDraft(material: material))
            .toList(growable: true) ??
        [_MaterialDraft()];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final material in _materials) {
      material.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(bomItemsProvider);
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
                widget.bom == null ? 'Add BOM' : 'Edit BOM',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              itemsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Could not load item lookup: $error',
                  style: TextStyle(color: AppColors.danger),
                ),
                data: (items) => _itemDropdown(
                  label: 'Finished item *',
                  value: _itemId,
                  items: items,
                  onChanged: (value) => setState(() => _itemId = value),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Materials',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addMaterial,
                    icon: const Icon(Icons.add),
                    label: const Text('Add material'),
                  ),
                ],
              ),
              ..._materials.asMap().entries.map(
                (entry) => _materialEditor(
                  entry.key,
                  entry.value,
                  itemsAsync.asData?.value ?? const [],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: itemsAsync.hasValue ? _submit : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.bom == null ? 'Create BOM' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemDropdown({
    required String label,
    required int? value,
    required List<ItemLookupResult> items,
    required ValueChanged<int?> onChanged,
  }) {
    final validValue = items.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<int>(
      value: validValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(
                '${item.name} (${item.sku})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selected) => selected == null ? 'Select an item' : null,
    );
  }

  Widget _materialEditor(
    int index,
    _MaterialDraft material,
    List<ItemLookupResult> items,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _itemDropdown(
                    label: 'Material item *',
                    value: material.itemId,
                    items: items,
                    onChanged: (value) =>
                        setState(() => material.itemId = value),
                  ),
                ),
                IconButton(
                  onPressed: _materials.length == 1
                      ? null
                      : () => _removeMaterial(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: material.quantity,
                    decoration: const InputDecoration(labelText: 'Quantity *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _positiveNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: material.uom,
                    decoration: const InputDecoration(labelText: 'UOM'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: material.scrapPct,
                    decoration: const InputDecoration(labelText: 'Scrap %'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: material.consumptionFactor,
                    decoration: const InputDecoration(
                      labelText: 'Consumption factor',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _positiveNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: material.componentType,
              decoration: const InputDecoration(labelText: 'Component type'),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveNumber(String? value) {
    final number = num.tryParse(value?.trim() ?? '');
    return number == null || number <= 0
        ? 'Enter a number greater than 0'
        : null;
  }

  String? _nonNegativeNumber(String? value) {
    final number = num.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? 'Enter 0 or a positive number' : null;
  }

  void _addMaterial() {
    setState(() => _materials.add(_MaterialDraft()));
  }

  void _removeMaterial(int index) {
    final material = _materials.removeAt(index);
    material.dispose();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _itemId == null) return;
    if (_materials.any((material) => material.itemId == null)) return;
    final body = {
      'itemId': _itemId,
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      'materials': _materials
          .map(
            (material) => {
              'itemId': material.itemId,
              'quantity': num.parse(material.quantity.text.trim()),
              if (material.uom.text.trim().isNotEmpty)
                'uom': material.uom.text.trim(),
              'scrapPct': num.parse(material.scrapPct.text.trim()),
              'consumptionFactor': num.parse(
                material.consumptionFactor.text.trim(),
              ),
              if (material.componentType.text.trim().isNotEmpty)
                'componentType': material.componentType.text.trim(),
            },
          )
          .toList(),
    };
    Navigator.pop(context, _BomFormResult(body));
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
