import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryLotsScreen extends ConsumerStatefulWidget {
  const InventoryLotsScreen({super.key});

  @override
  ConsumerState<InventoryLotsScreen> createState() => _InventoryLotsScreenState();
}

class _InventoryLotsScreenState extends ConsumerState<InventoryLotsScreen>
    with InventoryUiHelpers<InventoryLotsScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() =>
      asList(ref.read(inventoryRepositoryProvider).getLots());

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canAdd =
        auth.can(AppPermissions.inventoryManage) ||
        auth.can(AppPermissions.lotProcessingProcess);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory lots')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _allocateDirectStock,
              icon: const Icon(Icons.add),
              label: const Text('Allocate stock'),
            )
          : null,
      body: loadBody<List<dynamic>>(
        future: _load,
        what: 'lots',
        builder: (lots) => refreshList([
          pageHeader(
            title: 'Inventory lots',
            subtitle: 'Track stock from receipt through processing and sale.',
            icon: Icons.inventory_2_outlined,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              countBadge('Lots', lots.length, icon: Icons.layers_outlined),
              countBadge(
                'In processing',
                lots.where((raw) {
                  final lot = mapOf(raw);
                  return (num.tryParse('${lot['processingQty'] ?? 0}') ?? 0) >
                      0;
                }).length,
                icon: Icons.precision_manufacturing_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lots.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 34,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No inventory lots yet',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Received and processed lots will appear here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final raw in lots) _lotCard(mapOf(raw)),
        ]),
      ),
    );
  }

  Widget _lotCard(Map<String, dynamic> lot) {
    final item = mapOf(lot['item']);
    final id = toInt(lot['id'] ?? lot['lotId']);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: scheme.primary),
        ),
        title: Text(
          pickText(item, [
            'name',
          ], fallback: pickText(lot, ['lotNumber'], fallback: 'Lot #$id')),
        ),
        subtitle: Text(
          '${pickText(lot, ['lotNumber'], fallback: 'Lot #$id')}  •  ${pickText(lot, ['status'], fallback: '—')}\nAvailable: ${pickText(lot, ['availableQty'], fallback: '0')} units',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (ref.read(authProvider).can(AppPermissions.lotProcessingProcess))
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _startProcessing(lot),
                    icon: const Icon(Icons.precision_manufacturing_outlined),
                    label: const Text('Start processing'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _sendForSelling(lot),
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('Send for sale'),
                  ),
                  TextButton(
                    onPressed: () => _showLotSummary(id),
                    child: const Text('Lot details'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _allocateDirectStock() async {
    try {
      final items =
          (await ref.read(inventoryRepositoryProvider).getItems(limit: 500))
              .items;
      final warehouses = await ref
          .read(inventoryRepositoryProvider)
          .getWarehouses();
      if (!mounted) return;
      int? itemId, warehouseId;
      String destination = 'processed';
      final qty = TextEditingController();
      final note = TextEditingController();
      final key = GlobalKey<FormState>();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Allocate direct stock'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: [
                        for (final item in items)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setModal(() => itemId = v),
                      validator: (v) => v == null ? 'Select a product' : null,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Warehouse'),
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w.id, child: Text(w.name)),
                      ],
                      onChanged: (v) => setModal(() => warehouseId = v),
                      validator: (v) => v == null ? 'Select a warehouse' : null,
                    ),
                    TextFormField(
                      controller: qty,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Enter a positive quantity'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: destination,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'processed',
                          child: Text('Processed stock'),
                        ),
                        DropdownMenuItem(
                          value: 'sellable',
                          child: Text('Sellable stock'),
                        ),
                      ],
                      onChanged: (v) =>
                          setModal(() => destination = v ?? destination),
                    ),
                    TextFormField(
                      controller: note,
                      decoration: const InputDecoration(
                        labelText: 'Reason / note',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'A note is required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (key.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Allocate'),
              ),
            ],
          ),
        ),
      );
      if (save != true || itemId == null || warehouseId == null) return;
      await ref.read(inventoryRepositoryProvider).allocateDirectStock({
        'itemId': itemId,
        'warehouseId': warehouseId,
        'quantity': num.parse(qty.text),
        'destination': destination,
        'noteMessage': note.text.trim(),
      });
      showSuccess('Stock allocated');
    } catch (e) {
      showError(e);
    }
  }

  num _toNum(dynamic v) => num.tryParse('${v ?? 0}') ?? 0;

  String _fmtQty(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Shared quantity validator: must be > 0 and not exceed [max].
  String? _validateQty(String? v, num max) {
    final value = num.tryParse((v ?? '').trim());
    if (value == null || value <= 0) return 'Enter a positive quantity';
    if (value > max) return 'Cannot exceed available quantity (${_fmtQty(max)})';
    return null;
  }

  // ───────────────────────── Dialog UI helpers ─────────────────────────

  /// Consistent, modern input style for the dialogs below.
  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? helper,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: .35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 1.8),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.8),
    );
  }

  /// Dialog title: coloured icon badge + title + subtitle.
  Widget _dialogHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Highlighted "Available: X" summary strip.
  Widget _availableBanner(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Small "MAX" chip used as the quantity field suffix.
  Widget _maxButton(VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(52, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('MAX', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
  );

  /// Wraps dialog content so every field has even spacing and the dialog
  /// scrolls instead of overflowing when the keyboard opens.
  Widget _dialogBody(List<Widget> children) => SizedBox(
    width: 420,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    ),
  );

  Widget _cancelButton(BuildContext context) => TextButton(
    onPressed: () => Navigator.pop(context, false),
    child: const Text('Cancel'),
  );

  // ───────────────────────── Start processing ─────────────────────────

  Future<void> _startProcessing(Map<String, dynamic> lot) async {
    final id = toInt(lot['id'] ?? lot['lotId']);
    final availableRaw = _toNum(lot['rawQty'] ?? lot['availableQty']);
    final qty = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        title: _dialogHeader(
          context,
          icon: Icons.precision_manufacturing_outlined,
          title: 'Start processing',
          subtitle: 'Move raw stock into a processing batch',
        ),
        content: Form(
          key: key,
          child: _dialogBody([
            _availableBanner(
              context,
              label: 'Available raw quantity',
              value: _fmtQty(availableRaw),
            ),
            TextFormField(
              controller: qty,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                context,
                label: 'Input quantity',
                icon: Icons.scale_outlined,
                suffix: _maxButton(() => qty.text = _fmtQty(availableRaw)),
              ),
              validator: (v) => _validateQty(v, availableRaw),
            ),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                context,
                label: 'Note (optional)',
                icon: Icons.notes_outlined,
              ),
            ),
          ]),
        ),
        actions: [
          _cancelButton(context),
          FilledButton.icon(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).startLotProcessing(id, {
        'inputQty': num.parse(qty.text),
        if (note.text.trim().isNotEmpty) 'noteMessage': note.text.trim(),
      });
      showSuccess('Processing started');
      reload();
    } catch (e) {
      showError(e);
    }
  }

  // ───────────────────────── Send for sale ─────────────────────────

  Future<void> _sendForSelling(Map<String, dynamic> lot) async {
    final id = toInt(lot['id'] ?? lot['lotId']);
    final grades = (lot['grades'] is List ? lot['grades'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    String? grade = grades.isEmpty ? null : '${grades.first['grade'] ?? ''}';

    // Max sellable quantity: per-grade when grades exist, else lot-level.
    num availableFor(String? g) {
      if (grades.isEmpty) {
        return _toNum(lot['rawQty'] ?? lot['availableQty']);
      }
      final match = grades.firstWhere(
        (e) => '${e['grade']}' == g,
        orElse: () => <String, dynamic>{},
      );
      return _toNum(match['availableQty'] ?? match['quantity']);
    }

    final quantity = TextEditingController(text: _fmtQty(availableFor(grade)));
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          title: _dialogHeader(
            context,
            icon: Icons.sell_outlined,
            title: 'Send lot for sale',
            subtitle: 'Choose how much stock becomes sellable',
          ),
          content: Form(
            key: key,
            child: _dialogBody([
              if (grades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: grade,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  decoration: _fieldDecoration(
                    context,
                    label: 'Grade',
                    icon: Icons.grade_outlined,
                  ),
                  items: [
                    for (final g in grades)
                      DropdownMenuItem(
                        value: '${g['grade']}',
                        child: Text(
                          '${g['grade']}  •  ${g['availableQty'] ?? g['quantity'] ?? 0} available',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setModal(() {
                    grade = v;
                    quantity.text = _fmtQty(availableFor(v));
                  }),
                ),
              _availableBanner(
                context,
                label: grades.isEmpty
                    ? 'Available quantity'
                    : 'Available in grade ${grade ?? '—'}',
                value: _fmtQty(availableFor(grade)),
              ),
              TextFormField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDecoration(
                  context,
                  label: 'Quantity to sell',
                  icon: Icons.scale_outlined,
                  suffix: _maxButton(
                    () => quantity.text = _fmtQty(availableFor(grade)),
                  ),
                ),
                validator: (v) => _validateQty(v, availableFor(grade)),
              ),
            ]),
          ),
          actions: [
            _cancelButton(context),
            FilledButton.icon(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (submit != true) return;
    final qty = num.parse(quantity.text);
    final body = grades.isEmpty
        ? {'rawQty': qty}
        : {
            'grades': [
              {'grade': grade, 'quantity': qty},
            ],
          };
    try {
      final result = await ref
          .read(inventoryRepositoryProvider)
          .sendLotForSelling(id, body);
      final approvalId = result['approvalId'];
      showSuccess(
        approvalId == null
            ? 'Lot sent for sale'
            : 'Send-for-sale request sent for approval',
      );
      reload();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _showLotSummary(int id) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.getLotSummary(id),
        repo.getLotProcessings(id),
      ]);
      if (!mounted) return;
      final summary = results[0] as Map<String, dynamic>;
      final batches = results[1] as List<dynamic>;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final key in ['rawQty', 'processingQty', 'processedQty'])
                  ListTile(
                    title: Text(key.replaceAll('Qty', ' quantity')),
                    trailing: Text('${summary[key] ?? 0}'),
                  ),
                const Divider(),
                const Text(
                  'Processing batches',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (batches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No batches yet'),
                  ),
                for (final batch in batches)
                  ListTile(
                    title: Text(
                      pickText(mapOf(batch), [
                        'batchNumber',
                      ], fallback: 'Batch #${mapOf(batch)['id']}'),
                    ),
                    subtitle: Text(
                      '${pickText(mapOf(batch), ['status'])}  •  Input ${pickText(mapOf(batch), ['inputQty'], fallback: '0')}',
                    ),
                    trailing: pickText(mapOf(batch), ['status']) == 'IN_PROGRESS'
                        ? TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _completeProcessing(mapOf(batch));
                            },
                            child: const Text('Complete'),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> _completeProcessing(Map<String, dynamic> batch) async {
    final grade = TextEditingController(text: 'A');
    final qty = TextEditingController();
    final cost = TextEditingController(text: '0');
    final key = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete processing batch'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: grade,
                decoration: const InputDecoration(labelText: 'Grade'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a grade' : null,
              ),
              TextFormField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Output quantity'),
                validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive quantity'
                    : null,
              ),
              TextField(
                controller: cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Processing cost'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).completeLotProcessing(
        toInt(batch['id']),
        {
          'grades': [
            {'grade': grade.text.trim(), 'quantity': num.parse(qty.text)},
          ],
          'processingCost': num.tryParse(cost.text) ?? 0,
        },
      );
      showSuccess('Processing completed');
    } catch (e) {
      showError(e);
    }
  }
}