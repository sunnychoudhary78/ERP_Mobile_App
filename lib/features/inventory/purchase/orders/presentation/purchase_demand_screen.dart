import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/core/network/api_service.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_demand_model.dart';
import 'package:erp_app/features/inventory/purchase/vendors/data/model/vendor_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseDemandScreen extends ConsumerStatefulWidget {
  const PurchaseDemandScreen({super.key});

  @override
  ConsumerState<PurchaseDemandScreen> createState() =>
      _PurchaseDemandScreenState();
}

class _PurchaseDemandScreenState extends ConsumerState<PurchaseDemandScreen> {
  String _status = '';

  PurchaseDemandQuery get _query => PurchaseDemandQuery(status: _status);

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final demands = ref.watch(purchaseDemandsProvider(query));
    final auth = ref.watch(authProvider);
    final canApprove = auth.canAny(AppPermissions.purchaseDemandApprove);
    final canReject = auth.canAny(AppPermissions.purchaseDemandReject);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Purchase Demand')),
      body: Column(
        children: [
          _StatusFilter(
            value: _status,
            onChanged: (value) => setState(() => _status = value),
          ),
          Expanded(
            child: demands.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (error, _) => _ErrorView(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(purchaseDemandsProvider(query)),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(purchaseDemandsProvider(query));
                  await ref.read(purchaseDemandsProvider(query).future);
                },
                child: page.demands.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Center(child: Text('No purchase demands found')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: page.demands.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final demand = page.demands[index];
                          return _DemandCard(
                            demand: demand,
                            canApprove: canApprove,
                            canReject: canReject,
                            onOpen: () => _showDetails(demand),
                            onApprove: () =>
                                _actOnDemand(demand, approve: true),
                            onReject: () =>
                                _actOnDemand(demand, approve: false),
                            onRaisePurchases: () => _raisePurchases(demand),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(PurchaseDemand demand) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(demand.title),
        content: SizedBox(
          width: 420,
          child: demand.lines.isEmpty
              ? const Text('No shortage lines were returned.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: demand.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (_, index) =>
                      _LineSummary(line: demand.lines[index]),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _actOnDemand(
    PurchaseDemand demand, {
    required bool approve,
  }) async {
    final requestId = demand.approvalRequestId;
    if (requestId == null) {
      _showMessage('This demand has no approval request ID.');
      return;
    }

    final note = await _askForNote(
      approve ? 'Approve demand' : 'Reject demand',
    );
    if (note == null || !mounted) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (approve) {
        await repo.approvePurchaseDemand(requestId, note: note);
      } else {
        await repo.rejectPurchaseDemand(requestId, note: note);
      }
      ref.invalidate(purchaseDemandsProvider(_query));
      _showMessage(
        approve ? 'Purchase demand approved' : 'Purchase demand rejected',
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _purchaseRaiseError(Object error) {
    if (error is ApiException && error.payload is Map) {
      final missing = error.payload['missingVendors'];
      if (missing is List && missing.isNotEmpty) {
        return '${error.message ?? 'Unable to raise purchases'}: '
            'Missing vendors for ${missing.join(', ')}';
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<String?> _askForNote(String title) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    return note;
  }

  Future<void> _raisePurchases(PurchaseDemand demand) async {
    if (demand.workOrderId.isEmpty) {
      _showMessage('This demand has no work order ID.');
      return;
    }

    final result = await showModalBottomSheet<_RaisePurchasesResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RaisePurchasesSheet(demand: demand),
    );
    if (result == null || !mounted) return;

    try {
      final response = await ref
          .read(inventoryRepositoryProvider)
          .raisePurchases(
            demand.workOrderId,
            vendorByItemId: result.vendorByItemId,
            persistVendorOnItems: result.persistVendorOnItems,
          );
      ref.invalidate(purchaseDemandsProvider(_query));
      _showMessage(
        response['approvalId'] == null
            ? 'Purchases raised successfully'
            : 'Purchases sent for approval',
      );
    } catch (error) {
      _showMessage(_purchaseRaiseError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.filter_list),
          filled: true,
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('All statuses')),
          DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
          DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
          DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  final PurchaseDemand demand;
  final bool canApprove;
  final bool canReject;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRaisePurchases;

  const _DemandCard({
    required this.demand,
    required this.canApprove,
    required this.canReject,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onRaisePurchases,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = demand.status.contains('PENDING');
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      demand.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StatusChip(status: demand.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('${demand.lines.length} shortage line(s)'),
              if (demand.workOrderId.isNotEmpty)
                Text(
                  'Work order: ${demand.workOrderId}',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              if (isPending && (canApprove || canReject)) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canReject)
                      TextButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                      ),
                    if (canApprove)
                      FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                  ],
                ),
              ],
              if (isPending && demand.workOrderId.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRaisePurchases,
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Raise purchases'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RaisePurchasesResult {
  final Map<String, dynamic> vendorByItemId;
  final bool persistVendorOnItems;

  const _RaisePurchasesResult({
    required this.vendorByItemId,
    required this.persistVendorOnItems,
  });
}

class _RaisePurchasesSheet extends ConsumerStatefulWidget {
  final PurchaseDemand demand;

  const _RaisePurchasesSheet({required this.demand});

  @override
  ConsumerState<_RaisePurchasesSheet> createState() =>
      _RaisePurchasesSheetState();
}

class _RaisePurchasesSheetState
    extends ConsumerState<_RaisePurchasesSheet> {
  final Map<String, int> _selectedVendors = {};
  bool _persistVendorOnItems = false;

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(
      vendorsProvider(const VendorListQuery(limit: 200)),
    );
    final lines = widget.demand.lines;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raise purchases',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('Select a vendor for each shortage item.'),
              const SizedBox(height: 12),
              Expanded(
                child: vendorsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (page) => ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final itemId = _itemId(line);
                      return _VendorAssignment(
                        line: line,
                        vendors: page.vendors,
                        selectedVendorId: itemId == null
                            ? null
                            : _selectedVendors[itemId],
                        onChanged: itemId == null
                            ? null
                            : (vendorId) => setState(() {
                                  if (vendorId == null) {
                                    _selectedVendors.remove(itemId);
                                  } else {
                                    _selectedVendors[itemId] = vendorId;
                                  }
                                }),
                      );
                    },
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _persistVendorOnItems,
                onChanged: (value) => setState(
                  () => _persistVendorOnItems = value ?? false,
                ),
                title: const Text('Save vendor on item records'),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: lines.isEmpty ||
                          _selectedVendors.length != lines.length
                      ? null
                      : () => Navigator.pop(
                            context,
                            _RaisePurchasesResult(
                              vendorByItemId: Map<String, dynamic>.from(
                                _selectedVendors,
                              ),
                              persistVendorOnItems: _persistVendorOnItems,
                            ),
                          ),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Raise purchases'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _itemId(Map<String, dynamic> line) {
    final item = line['item'];
    final value = line['itemId'] ?? (item is Map ? item['id'] : null);
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class _VendorAssignment extends StatelessWidget {
  final Map<String, dynamic> line;
  final List<Vendor> vendors;
  final int? selectedVendorId;
  final ValueChanged<int?>? onChanged;

  const _VendorAssignment({
    required this.line,
    required this.vendors,
    required this.selectedVendorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = line['item'];
    final itemName = item is Map
        ? item['name']
        : line['itemName'] ?? line['name'] ?? 'Item';
    final itemId = line['itemId'] ?? (item is Map ? item['id'] : null);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '$itemName (ID: ${itemId ?? '-'})',
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: selectedVendorId,
          hint: const Text('Select vendor'),
          items: vendors
              .map(
                (vendor) => DropdownMenuItem<int>(
                  value: vendor.id,
                  child: Text(vendor.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LineSummary extends StatelessWidget {
  final Map<String, dynamic> line;

  const _LineSummary({required this.line});

  @override
  Widget build(BuildContext context) {
    final item = line['item'];
    final itemName = item is Map
        ? item['name']
        : line['itemName'] ?? line['name'];
    final itemId = line['itemId'] ?? (item is Map ? item['id'] : null);
    final quantity =
        line['shortageQty'] ??
        line['shortage'] ??
        line['quantity'] ??
        line['requiredQty'] ??
        '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${itemName ?? 'Item'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text('Item ID: ${itemId ?? '-'}'),
        Text('Shortage: $quantity'),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.contains('APPROVED')
        ? Colors.green
        : status.contains('REJECTED')
        ? Colors.red
        : Colors.orange;
    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color, fontSize: 11),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
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
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
