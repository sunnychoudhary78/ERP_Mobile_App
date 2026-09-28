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
  ConsumerState<InventoryWarehousesScreen> createState() => _InventoryWarehousesScreenState();
}

class _InventoryWarehousesScreenState extends ConsumerState<InventoryWarehousesScreen>
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 34,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No warehouses yet',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a warehouse to organize stock by location.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final warehouse in warehouses) _warehouseCard(warehouse),
        ]),
      ),
    );
  }

  Widget _warehouseCard(Warehouse warehouse) {
    final scheme = Theme.of(context).colorScheme;
    final active = (warehouse.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.warehouse_outlined, color: scheme.primary),
        ),
        title: Text(
          warehouse.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? scheme.tertiaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                active ? 'ACTIVE' : 'INACTIVE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit warehouse',
          onPressed: () => _editWarehouse(existing: warehouse),
        ),
      ),
    );
  }

  Future<void> _editWarehouse({Warehouse? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final address = TextEditingController();
    String status = existing?.status ?? 'ACTIVE';
    final key = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: Text(existing == null ? 'Add warehouse' : 'Edit warehouse'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Warehouse name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'INACTIVE',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (v) => setModal(() => status = v ?? status),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;
    try {
      final body = <String, dynamic>{
        'name': name.text.trim(),
        if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
        'status': status,
      };
      if (existing == null) {
        await ref.read(inventoryRepositoryProvider).saveWarehouse(body);
      } else {
        await ref.read(inventoryRepositoryProvider).updateWarehouse({
          'id': existing.id,
          ...body,
        });
      }
      showSuccess(existing == null ? 'Warehouse created' : 'Warehouse updated');
    } catch (e) {
      showError(e);
    }
  }
}
