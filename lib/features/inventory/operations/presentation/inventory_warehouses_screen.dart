import 'package:erp_app/features/inventory/shared/data/models/warehouse_model.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryWarehousesScreen extends ConsumerStatefulWidget {
  const InventoryWarehousesScreen({super.key});

  @override
  ConsumerState<InventoryWarehousesScreen> createState() =>
      _InventoryWarehousesScreenState();
}

class _InventoryWarehousesScreenState
    extends ConsumerState<InventoryWarehousesScreen>
    with InventoryUiHelpers<InventoryWarehousesScreen> {
  late Future<List<Warehouse>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<Warehouse>> _fetch() async => List<Warehouse>.from(
    await ref.read(inventoryRepositoryProvider).getWarehouses(),
  );

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = ref.watch(authProvider).can(AppPermissions.warehouseManage);
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouses')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _editWarehouse(),
              icon: const Icon(Icons.add),
              label: const Text('Add warehouse'),
            )
          : null,
      body: loadBody<List<Warehouse>>(
        future: _load,
        what: 'warehouses',
        builder: (warehouses) => refreshList([
          pageHeader(
            title: 'Warehouses',
            subtitle: 'Manage the locations that hold your inventory.',
            icon: Icons.warehouse_outlined,
          ),
          countBadge(
            'Locations',
            warehouses.length,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          if (warehouses.isEmpty)
            _emptyState(canAdd)
          else
            for (final warehouse in warehouses) _warehouseCard(warehouse),
          // Space so the FAB never covers the last card.
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _emptyState(bool canAdd) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warehouse_outlined,
                size: 34,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No warehouses yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a warehouse to organize stock by location.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (canAdd) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _editWarehouse(),
                icon: const Icon(Icons.add),
                label: const Text('Add warehouse'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _warehouseCard(Warehouse warehouse) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = (warehouse.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';
    final address = (warehouse.address ?? '').trim();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: () => _editWarehouse(existing: warehouse),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.warehouse_outlined,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _statusChip(active),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit warehouse',
                onPressed: () => _editWarehouse(existing: warehouse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool active) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active ? scheme.tertiaryContainer : scheme.surfaceContainerHighest;
    final fg = active ? scheme.onTertiaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editWarehouse({Warehouse? existing}) async {
    // The dialog owns (and disposes) its own controllers, so nothing is
    // disposed while the close animation is still running.
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _WarehouseDialog(existing: existing),
    );

    if (body == null) return; // cancelled

    try {
      if (existing == null) {
        await ref.read(inventoryRepositoryProvider).saveWarehouse(body);
      } else {
        await ref.read(inventoryRepositoryProvider).updateWarehouse({
          'id': existing.id,
          ...body,
        });
      }
      if (!mounted) return;
      showSuccess(existing == null ? 'Warehouse created' : 'Warehouse updated');
      reload(); // refresh list (remove if showSuccess already calls reload)
    } catch (e) {
      if (!mounted) return;
      showError(e);
    }
  }
}

InputDecoration _warehouseFieldDecoration(
  BuildContext context,
  String label,
  IconData icon,
) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _WarehouseDialog extends StatefulWidget {
  const _WarehouseDialog({this.existing});

  final Warehouse? existing;

  @override
  State<_WarehouseDialog> createState() => _WarehouseDialogState();
}

class _WarehouseDialogState extends State<_WarehouseDialog> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late String _status;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _address = TextEditingController(text: existing?.address ?? '');
    final s = (existing?.status ?? 'ACTIVE').toUpperCase();
    _status = (s == 'ACTIVE' || s == 'INACTIVE') ? s : 'ACTIVE';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'name': _name.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.existing == null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.warehouse_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNew ? 'Add warehouse' : 'Edit warehouse',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _warehouseFieldDecoration(
                  context,
                  'Warehouse name',
                  Icons.badge_outlined,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: _warehouseFieldDecoration(
                  context,
                  'Address',
                  Icons.place_outlined,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _status,
                borderRadius: BorderRadius.circular(12),
                decoration: _warehouseFieldDecoration(
                  context,
                  'Status',
                  Icons.toggle_on_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}