import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/bom/data/models/bom_model.dart';
import 'package:erp_app/features/inventory/bom/data/provider/bom_provider.dart';
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
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text(
            "You don't have permission to view BOMs",
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return Scaffold(
      // The bottom sheet already pads itself for the keyboard (viewInsets),
      // so the page behind it doesn't need to resize/relayout too — that
      // double-resize on every keyboard frame is what was causing the lag
      // whenever you typed in the "New BOM" sheet.
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Bill of Materials',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('New BOM'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(bomProvider.notifier).search(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search BOM by finished item',
                hintStyle: TextStyle(color: AppColors.muted),
                prefixIcon: Icon(Icons.search, color: AppColors.accent),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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

  Widget _buildBody(BomState state) {
    if (state.isLoading && state.boms.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
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
        color: AppColors.accent,
        onRefresh: () => ref.read(bomProvider.notifier).load(),
        child: ListView(
          children: [
            const SizedBox(height: 90),
            Icon(Icons.inventory_2_outlined, size: 46, color: AppColors.muted),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No BOMs found',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(bomProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
        itemCount: boms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
      backgroundColor: Colors.transparent,
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete BOM?',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600),
        ),
        content: Text('Delete the BOM for "${bom.item?.name ?? 'this item'}"?'),
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
      final response = await ref.read(bomProvider.notifier).delete(bom.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
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
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ),
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

  // Built once instead of allocating a new BoxShadow list on every
  // rebuild — with many cards in the list this was adding up.
  static final _cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates each card's own paint layer so scrolling /
    // keyboard-driven relayout elsewhere on screen doesn't force every
    // card to repaint.
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: _cardShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bom.item?.name ?? 'Item #${bom.itemId}',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${bom.materials.length} material${bom.materials.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              if (bom.description?.isNotEmpty == true) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bom.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canManage)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoundIconButton(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            onTap: onEdit,
                          ),
                          const SizedBox(width: 6),
                          _RoundIconButton(
                            icon: Icons.delete_outline,
                            color: AppColors.danger,
                            onTap: onDelete,
                          ),
                        ],
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
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
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

/// Reads the keyboard's inset in its own small build() so that opening or
/// closing the keyboard only re-runs this tiny widget — not the (large)
/// form passed in as [child]. Flutter treats [child] as the same widget
/// instance across those rebuilds and skips rebuilding it entirely, only
/// relaying it out as the padding animates.
class _KeyboardInsetPadding extends StatelessWidget {
  final Widget child;

  const _KeyboardInsetPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottom),
      duration: const Duration(milliseconds: 120),
      curve: Curves.decelerate,
      child: child,
    );
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
    // NOTE: deliberately not reading MediaQuery.viewInsetsOf(context) here.
    // Doing so in this build() meant the whole form (every dropdown, every
    // material card) rebuilt on every single frame of the keyboard's
    // open/close animation — that's what made tapping into a field feel
    // slow. _KeyboardInsetPadding below isolates that dependency to a tiny
    // widget so only it re-runs during the animation.
    return Container(
      constraints: BoxConstraints(
        // sizeOf (not MediaQuery.of) so this doesn't also re-subscribe to
        // viewInsets changes.
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(
            child: _KeyboardInsetPadding(
              child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.bom == null ? 'Add BOM' : 'Edit BOM',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 48,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Finished Item'),
                    const SizedBox(height: 8),
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
                      decoration: _fieldDecoration('Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Materials'),
                        TextButton.icon(
                          onPressed: _addMaterial,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add material'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._materials.asMap().entries.map(
                      (entry) => _materialEditor(
                        entry.key,
                        entry.value,
                        itemsAsync.asData?.value ?? const [],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: itemsAsync.hasValue ? _submit : null,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.bom == null ? 'Create BOM' : 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.muted,
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _itemDropdown({
    required String label,
    required int? value,
    required List<ItemLookupResult> items,
    required ValueChanged<int?> onChanged,
  }) {
    final validValue = items.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<int>(
      value: validValue,
      decoration: _fieldDecoration(label),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                if (_materials.length > 1)
                  _RoundIconButton(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    onTap: () => _removeMaterial(index),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: material.quantity,
                    decoration: _fieldDecoration('Quantity *'),
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
                    decoration: _fieldDecoration('UOM'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: material.scrapPct,
                    decoration: _fieldDecoration('Scrap %'),
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
                    decoration: _fieldDecoration('Consumption factor'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _positiveNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: material.componentType,
              decoration: _fieldDecoration('Component type'),
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
            Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}