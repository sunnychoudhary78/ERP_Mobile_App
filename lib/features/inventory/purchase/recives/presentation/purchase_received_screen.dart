import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_order_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PurchaseReceivedScreen extends ConsumerStatefulWidget {
  const PurchaseReceivedScreen({super.key});

  @override
  ConsumerState<PurchaseReceivedScreen> createState() =>
      _PurchaseReceivedScreenState();
}

class _PurchaseReceivedScreenState
    extends ConsumerState<PurchaseReceivedScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  static const List<String> _statusFilters = [
    '',
    'CREATED',
    'RECEIVE_PENDING_APPROVAL',
    'PARTIALLY_RECEIVED',
    'RECEIVED',
    'REJECTED',
    'DRAFT',
  ];
  int _statusIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PurchaseOrderQuery get _query => PurchaseOrderQuery(
        search: _search,
        status: _statusFilters[_statusIndex],
      );

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(purchaseOrdersProvider(_query));
    final billsAsync = ref.watch(purchaseBillsProvider);
    final bills = billsAsync.hasValue ? billsAsync.value : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Received'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                labelText: 'Search PO number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _statusIndex;
                return FilterChip(
                  selected: selected,
                  label: Text(_statusFilters[i].isEmpty
                      ? 'All'
                      : _statusFilters[i].replaceAll('_', ' ')),
                  onSelected: (_) => setState(() => _statusIndex = i),
                );
              },
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () {
                  ref.invalidate(purchaseOrdersProvider(_query));
                  ref.invalidate(purchaseBillsProvider);
                },
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(purchaseOrdersProvider(_query));
                  ref.invalidate(purchaseBillsProvider);
                  await ref.read(purchaseOrdersProvider(_query).future);
                },
                child: page.orders.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 160),
                          Center(
                            child: Text(
                              _statusFilters[_statusIndex].isEmpty
                                  ? 'No purchase orders found'
                                  : 'No ${_statusFilters[_statusIndex].replaceAll('_', ' ').toLowerCase()} purchase orders',
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: page.orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, index) => _PurchaseReceivedCard(
                          order: page.orders[index],
                          isBilled: bills
                                  ?.billedPurchaseIds
                                  .contains(page.orders[index].id) ??
                              false,
                          onChanged: () {
                            ref.invalidate(purchaseOrdersProvider(_query));
                            ref.invalidate(purchaseBillsProvider);
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseReceivedCard extends ConsumerWidget {
  final PurchaseOrder order;
  final bool isBilled;
  final VoidCallback onChanged;

  const _PurchaseReceivedCard({
    required this.order,
    required this.isBilled,
    required this.onChanged,
  });

  bool get _canReceive {
    final s = order.status.toUpperCase();
    return s != 'RECEIVED' && s != 'REJECTED';
  }

  bool get _canReject {
    final s = order.status.toUpperCase();
    if (s == 'RECEIVED' ||
        s == 'REJECTED' ||
        s == 'RECEIVE_PENDING_APPROVAL' ||
        s == 'PARTIALLY_RECEIVED') {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final canReceive = auth.canAny(AppPermissions.purchaseReceiveAction);
    final canBill = auth.canAny(AppPermissions.billCreateFromPurchase);
    final hasItemLevelReceived = order.items.any((it) {
      final v = it['receivedQty'] ?? it['received_qty'];
      return v is num && v > 0;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.poNumber.isEmpty ? 'PO #${order.id}' : order.poNumber,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.vendorName.isEmpty ? 'Vendor unavailable' : order.vendorName} • '
                        '${order.warehouseName.isEmpty ? 'Warehouse unavailable' : order.warehouseName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          order.createdAt!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(order.status),
                    const SizedBox(height: 6),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ItemsPreview(items: order.items),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (isBilled)
                  const Chip(
                    avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
                    label: Text('Billed'),
                  ),
                if (canBill && _canCreateBill && !isBilled)
                  FilledButton.tonalIcon(
                    onPressed: () => _onCreateBill(context, ref),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Create bill'),
                  ),
                if (canReceive && _canReject && !hasItemLevelReceived)
                  OutlinedButton.icon(
                    onPressed: () => _onReject(context, ref),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Reject'),
                  ),
                if (canReceive && _canReceive)
                  FilledButton.icon(
                    onPressed: () => _onReceive(context, ref),
                    icon: const Icon(Icons.call_received),
                    label: const Text('Receive'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canCreateBill {
    final s = order.status.toUpperCase();
    return s == 'RECEIVED' || s == 'PARTIALLY_RECEIVED';
  }

  Future<void> _onReceive(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ReceiveDialogResult>(
      context: context,
      builder: (_) => _ReceiveDialog(order: order),
    );
    if (result == null) return;

    try {
      final Map<String, dynamic> res;
      if (result.invoicePhotoPath != null) {
        res = await ref.read(inventoryRepositoryProvider).receivePurchaseWithPhoto(
              order.id,
              warehouseId: result.warehouseId,
              invoiceNumber: result.invoiceNumber,
              items: result.items,
              invoicePhotoPath: result.invoicePhotoPath!,
              invoicePhotoFilename: result.invoicePhotoFilename,
            );
      } else {
        res = await ref.read(inventoryRepositoryProvider).receivePurchase(
              order.id,
              warehouseId: result.warehouseId,
              invoiceNumber: result.invoiceNumber,
              items: result.items,
            );
      }
      if (!context.mounted) return;
      onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['approvalId'] == null
                ? 'Purchase order received'
                : 'Receive submitted for approval',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _onReject(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject purchase order?'),
        content: const Text(
          'This will mark the PO as REJECTED and it will no longer be receivable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(inventoryRepositoryProvider).rejectPurchase(order.id);
      if (!context.mounted) return;
      onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase order rejected')),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _onCreateBill(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create bill from purchase?'),
        content: const Text(
          'A new bill will be generated using the received items and totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create bill'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ref
          .read(inventoryRepositoryProvider)
          .createBillFromPurchase(order.id);
      if (!context.mounted) return;
      onChanged();
      final billId = res['data'] is Map ? res['data']['id'] : res['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billId != null
              ? 'Bill #$billId created'
              : res['approvalId'] != null
                  ? 'Bill creation sent for approval'
                  : 'Bill created'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  (Color, Color) get _palette {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'DRAFT':
        return (Colors.grey.shade100, Colors.black87);
      case 'RECEIVE_PENDING_APPROVAL':
        return (Colors.orange.shade100, Colors.orange.shade900);
      case 'PARTIALLY_RECEIVED':
        return (Colors.blue.shade100, Colors.blue.shade900);
      case 'RECEIVED':
        return (Colors.green.shade100, Colors.green.shade900);
      case 'REJECTED':
        return (Colors.red.shade100, Colors.red.shade900);
      default:
        return (Colors.grey.shade100, Colors.black87);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ItemsPreview extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ItemsPreview({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${items.length})',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < items.length && i < 3; i++)
            _ItemLine(item: items[i]),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${items.length - 3} more',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ItemLine({required this.item});

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ??
            item['itemName'] ??
            item['item_name'] ??
            'Item ${item['itemId'] ?? item['item_id'] ?? '?'}')
        .toString();
    final ordered = _int(item['orderedQty'] ??
        item['ordered_qty'] ??
        item['quantity'] ??
        item['qty']);
    final received = _int(item['receivedQty'] ?? item['received_qty']);
    final rejected = _int(item['rejectedQty'] ?? item['rejected_qty']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '• $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            received > 0 || rejected > 0
                ? '$received/$ordered${rejected > 0 ? '  -$rejected' : ''}'
                : '$ordered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: received > 0
                      ? Colors.green.shade700
                      : rejected > 0
                          ? Colors.red.shade700
                          : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveDialogResult {
  final int warehouseId;
  final String invoiceNumber;
  final List<Map<String, dynamic>> items;
  final String? invoicePhotoPath;
  final String? invoicePhotoFilename;

  const _ReceiveDialogResult({
    required this.warehouseId,
    required this.invoiceNumber,
    required this.items,
    this.invoicePhotoPath,
    this.invoicePhotoFilename,
  });
}

class _ReceiveDialog extends ConsumerStatefulWidget {
  final PurchaseOrder order;

  const _ReceiveDialog({required this.order});

  @override
  ConsumerState<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends ConsumerState<_ReceiveDialog> {
  final _invoiceNumberController = TextEditingController();
  int? _warehouseId;
  late final List<_ReceiveItemController> _rows;
  XFile? _photo;
  String? _error;

  static const List<String> _rejectionReasons = [
    'DAMAGED',
    'SHORT',
    'WRONG_SPEC',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    final items = widget.order.items;
    if (items.isNotEmpty) {
      _rows = items.map((it) {
        final itemId = it['itemId'] ?? it['item_id'];
        final ordered = it['orderedQty'] ??
            it['ordered_qty'] ??
            it['quantity'] ??
            it['qty'] ??
            0;
        return _ReceiveItemController(
          itemId: itemId is int
              ? itemId
              : int.tryParse('$itemId') ?? 0,
          orderedQty: ordered is num
              ? ordered.toInt()
              : int.tryParse('$ordered') ?? 0,
        );
      }).toList();
    } else {
      _rows = [_ReceiveItemController(itemId: 0, orderedQty: 0)];
    }
    if (widget.order.warehouseId != 0) {
      _warehouseId = widget.order.warehouseId;
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _photo = picked);
    } catch (e) {
      setState(() => _error =
          'Could not pick photo: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _submit() {
    setState(() => _error = null);
    final whId = _warehouseId;
    if (whId == null) {
      setState(() => _error = 'Select a warehouse');
      return;
    }
    if (_invoiceNumberController.text.trim().isEmpty) {
      setState(() => _error = 'Enter invoice number');
      return;
    }
    final bodyItems = <Map<String, dynamic>>[];
    for (int i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      final itemId = r.itemId;
      final received = r.received;
      final rejected = r.rejected;
      final reason = r.rejectionReason;
      if (itemId <= 0) {
        setState(() => _error = 'Row ${i + 1}: Item ID required');
        return;
      }
      if (received < 0 || rejected < 0) {
        setState(() => _error = 'Row ${i + 1}: qty must be ≥ 0');
        return;
      }
      if (received == 0 && rejected == 0) {
        setState(() =>
            _error = 'Row ${i + 1}: enter received or rejected quantity');
        return;
      }
      if (rejected > 0 && (reason == null || reason.isEmpty)) {
        setState(() =>
            _error = 'Row ${i + 1}: rejection reason required');
        return;
      }
      bodyItems.add({
        'itemId': itemId,
        'receivedQty': received,
        'rejectedQty': rejected,
        if (rejected > 0) 'rejectionReason': reason,
      });
    }

    Navigator.pop(
      context,
      _ReceiveDialogResult(
        warehouseId: whId,
        invoiceNumber: _invoiceNumberController.text.trim(),
        items: bodyItems,
        invoicePhotoPath: _photo?.path,
        invoicePhotoFilename: _photo?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(productWarehousesProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Receive purchase order'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              warehousesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Warehouse error: ${error.toString().replaceFirst('Exception: ', '')}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                data: (whs) {
                  if (whs.isEmpty) {
                    return const Text('No warehouses available');
                  }
                  if (_warehouseId == null ||
                      !whs.any((w) => w.id == _warehouseId)) {
                    _warehouseId = whs.first.id;
                  }
                  return DropdownButtonFormField<int>(
                    value: _warehouseId,
                    decoration: const InputDecoration(labelText: 'Warehouse'),
                    items: whs
                        .map((w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _warehouseId = v),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice number',
                  hintText: 'INV-001',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photo == null
                    ? 'Attach invoice photo (optional)'
                    : 'Photo attached: ${_photo!.name}'),
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ..._rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return _ReceiveItemRow(
                  index: i,
                  controller: row,
                  canRemove: _rows.length > 1,
                  rejectionReasons: _rejectionReasons,
                  onRemove: () {
                    if (_rows.length <= 1) return;
                    setState(() {
                      _rows[i].dispose();
                      _rows.removeAt(i);
                    });
                  },
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() =>
                    _rows.add(_ReceiveItemController(itemId: 0, orderedQty: 0))),
                icon: const Icon(Icons.add),
                label: const Text('Add item row'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Receive')),
      ],
    );
  }
}

class _ReceiveItemController {
  int itemId;
  final int orderedQty;
  final TextEditingController itemIdCtrl;
  final TextEditingController receivedCtrl;
  final TextEditingController rejectedCtrl;
  String? rejectionReason;

  _ReceiveItemController({required this.itemId, required this.orderedQty})
      : itemIdCtrl = TextEditingController(text: itemId > 0 ? '$itemId' : ''),
        receivedCtrl = TextEditingController(
            text: orderedQty > 0 ? '$orderedQty' : '0'),
        rejectedCtrl = TextEditingController(text: '0');

  int get received {
    final v = num.tryParse(receivedCtrl.text);
    return v == null ? 0 : v.toInt();
  }

  int get rejected {
    final v = num.tryParse(rejectedCtrl.text);
    return v == null ? 0 : v.toInt();
  }

  void syncItemId() {
    itemId = int.tryParse(itemIdCtrl.text) ?? 0;
  }

  void dispose() {
    itemIdCtrl.dispose();
    receivedCtrl.dispose();
    rejectedCtrl.dispose();
  }
}

class _ReceiveItemRow extends StatelessWidget {
  final int index;
  final _ReceiveItemController controller;
  final bool canRemove;
  final List<String> rejectionReasons;
  final VoidCallback onRemove;

  const _ReceiveItemRow({
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.rejectionReasons,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Item ${index + 1}', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove this row',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onRemove,
                  ),
              ],
            ),
            TextField(
              controller: controller.itemIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Item ID',
                isDense: true,
              ),
              onChanged: (_) => controller.syncItemId(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.receivedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Received qty',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.rejectedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rejected qty',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: controller.rejectionReason,
              decoration: const InputDecoration(
                labelText: 'Rejection reason (if rejected > 0)',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('—')),
                ...rejectionReasons.map(
                  (r) => DropdownMenuItem(value: r, child: Text(r)),
                ),
              ],
              onChanged: (v) => controller.rejectionReason = v,
            ),
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
