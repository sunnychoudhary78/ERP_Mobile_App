import 'package:flutter/material.dart';

/// Self-contained "Allocate direct stock" dialog.
///
/// Owns its own controllers (so nothing is disposed while the dialog is still
/// animating out), handles loading / error+retry, and scrolls with the keyboard.
///
/// Pops with a ready-to-send payload map, or null if cancelled.
class AllocateStockDialog extends StatefulWidget {
  const AllocateStockDialog({
    super.key,
    required this.future,
    required this.loader,
  });

  /// Prefetched [items, warehouses] future.
  final Future<List<dynamic>> future;

  /// Called on "Retry" to fetch [items, warehouses] again.
  final Future<List<dynamic>> Function() loader;

  @override
  State<AllocateStockDialog> createState() => _AllocateStockDialogState();
}

class _AllocateStockDialogState extends State<AllocateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();

  late Future<List<dynamic>> _future = widget.future;
  int? _itemId;
  int? _warehouseId;
  String _destination = 'processed';

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _retry() => setState(() => _future = widget.loader());

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop<Map<String, dynamic>>(context, {
      'itemId': _itemId,
      'warehouseId': _warehouseId,
      'quantity': num.parse(_qty.text.trim()),
      'destination': _destination,
      'noteMessage': _note.text.trim(),
    });
  }

  InputDecoration _decoration(String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: .35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 1.8),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            final ready = snap.connectionState == ConnectionState.done &&
                snap.hasData &&
                !snap.hasError;
            final items =
                ready ? snap.data![0] as List<dynamic> : const <dynamic>[];
            final warehouses =
                ready ? snap.data![1] as List<dynamic> : const <dynamic>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_box_outlined,
                            color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allocate direct stock',
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add stock straight into a warehouse',
                              style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Body ──
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: snap.hasError
                        ? _errorView(scheme)
                        : !ready
                            ? const SizedBox(
                                height: 160,
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            : _form(items, warehouses, scheme, text),
                  ),
                ),

                // ── Actions ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: ready ? _submit : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Allocate'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _errorView(ColorScheme scheme) => SizedBox(
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Could not load products and warehouses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _form(List<dynamic> items, List<dynamic> warehouses,
      ColorScheme scheme, TextTheme text) {
    const gap = SizedBox(height: 14);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            value: _itemId,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            decoration: _decoration('Product', Icons.inventory_2_outlined),
            items: [
              for (final item in items)
                DropdownMenuItem<int>(
                  value: item.id as int,
                  child: Text('${item.name}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _itemId = v),
            validator: (v) => v == null ? 'Select a product' : null,
          ),
          gap,
          DropdownButtonFormField<int>(
            value: _warehouseId,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            decoration: _decoration('Warehouse', Icons.warehouse_outlined),
            items: [
              for (final w in warehouses)
                DropdownMenuItem<int>(
                  value: w.id as int,
                  child: Text('${w.name}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _warehouseId = v),
            validator: (v) => v == null ? 'Select a warehouse' : null,
          ),
          gap,
          TextFormField(
            controller: _qty,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: _decoration('Quantity', Icons.scale_outlined),
            validator: (v) => (num.tryParse((v ?? '').trim()) ?? 0) <= 0
                ? 'Enter a positive quantity'
                : null,
          ),
          gap,
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Destination',
              style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 'processed',
                icon: Icon(Icons.precision_manufacturing_outlined, size: 18),
                label: Text('Processed'),
              ),
              ButtonSegment(
                value: 'sellable',
                icon: Icon(Icons.sell_outlined, size: 18),
                label: Text('Sellable'),
              ),
            ],
            selected: {_destination},
            onSelectionChanged: (s) =>
                setState(() => _destination = s.first),
          ),
          gap,
          TextFormField(
            controller: _note,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration('Reason / note *', Icons.notes_outlined),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'A note is required' : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}