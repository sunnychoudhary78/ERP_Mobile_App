import 'package:erp_app/core/network/api_service.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';

import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/purchase/orders/data/model/purchase_demand_model.dart';
import 'package:erp_app/features/inventory/purchase/vendors/data/model/vendor_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:erp_app/features/inventory/shared/widget/app_widget.dart';
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
    final statusOptions =
        ref.watch(purchaseDemandStatusesProvider).asData?.value ??
            const <String>[];
    final auth = ref.watch(authProvider);
    final canApprove = auth.canAny(AppPermissions.purchaseDemandApprove);
    final canReject = auth.canAny(AppPermissions.purchaseDemandReject);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        centerTitle: true,
        title: const Text(
          'Purchase Demand',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          _StatusFilter(
            value: _status,
            statuses: statusOptions,
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
                  ref.invalidate(purchaseDemandStatusesProvider);
                  await ref.read(purchaseDemandsProvider(query).future);
                },
                child: page.demands.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 44,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No purchase demands found',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: page.demands.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    await showAppSheet<void>(
      context,
      builder: (_) => AppSheetFrame(
        title: demand.title,
        subtitle: demand.lines.isEmpty
            ? null
            : '${demand.lines.length} shortage '
                '${demand.lines.length == 1 ? 'line' : 'lines'}',
        child: demand.lines.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No shortage lines were returned.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in demand.lines) _LineSummary(line: line),
                ],
              ),
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

    final note = await _askForNote(approve: approve);
    if (note == null || !mounted) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (approve) {
        await repo.approvePurchaseDemand(requestId, note: note);
      } else {
        await repo.rejectPurchaseDemand(requestId, note: note);
      }
      ref.invalidate(purchaseDemandsProvider(_query));
      ref.invalidate(purchaseDemandStatusesProvider);
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

  Future<String?> _askForNote({required bool approve}) {
    return showAppSheet<String>(
      context,
      builder: (_) => _NoteSheet(approve: approve),
    );
  }

  Future<void> _raisePurchases(PurchaseDemand demand) async {
    if (demand.workOrderId.isEmpty) {
      _showMessage('This demand has no work order ID.');
      return;
    }

    final result = await showAppSheet<_RaisePurchasesResult>(
      context,
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
      ref.invalidate(purchaseDemandStatusesProvider);
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

// ─────────────────────────────────────────────────────────────────────────────
// Status filter (chips instead of a dropdown)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilter extends StatelessWidget {
  final String value;
  final List<String> statuses;
  final ValueChanged<String> onChanged;

  const _StatusFilter({
    required this.value,
    required this.statuses,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final all = <String>['', ...{...statuses, if (value.isNotEmpty) value}];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        itemCount: all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = all[index];
          final selected = status == value;
          return ChoiceChip(
            showCheckmark: false,
            selected: selected,
            onSelected: (_) => onChanged(status),
            label: Text(status.isEmpty ? 'All' : appPrettyLabel(status)),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.text,
            ),
            backgroundColor: Colors.white,
            selectedColor: AppColors.accent,
            side: BorderSide(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demand card
// ─────────────────────────────────────────────────────────────────────────────

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
    final showDecision = isPending && (canApprove || canReject);
    final showRaise = isPending && demand.workOrderId.isNotEmpty;
    final statusColor = appStatusColor(demand.status);
    final lineCount = demand.lines.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: statusColor.withValues(alpha: 0.7),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 20,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      demand.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                    if (demand.workOrderId.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Work order: ${demand.workOrderId}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppStatusPill(status: demand.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.list_alt_outlined,
                                      size: 15,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$lineCount shortage '
                                      '${lineCount == 1 ? 'line' : 'lines'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'View details',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                          if (showDecision || showRaise) ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                          ],
                          if (showDecision)
                            Row(
                              children: [
                                if (canReject)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: BorderSide(
                                          color: AppColors.danger
                                              .withValues(alpha: 0.5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: onReject,
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                if (canReject && canApprove)
                                  const SizedBox(width: 10),
                                if (canApprove)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: onApprove,
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Approve'),
                                    ),
                                  ),
                              ],
                            ),
                          if (showDecision && showRaise)
                            const SizedBox(height: 10),
                          if (showRaise)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side: BorderSide(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.5),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: onRaisePurchases,
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                  size: 18,
                                ),
                                label: const Text('Raise purchases'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approve / reject note sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NoteSheet extends StatefulWidget {
  final bool approve;

  const _NoteSheet({required this.approve});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.approve;
    final actionColor = approve ? AppColors.accent : AppColors.danger;

    return AppSheetFrame(
      title: approve ? 'Approve Demand' : 'Reject Demand',
      subtitle: approve
          ? 'Add an optional note for this approval.'
          : 'Let the requester know why this demand is being rejected.',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
              icon: Icon(approve ? Icons.check : Icons.close, size: 18),
              label: Text(approve ? 'Approve' : 'Reject'),
            ),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        maxLines: 4,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        scrollPadding: const EdgeInsets.only(bottom: 160),
        decoration: appFieldDecoration('Note (optional)'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Raise purchases sheet
// ─────────────────────────────────────────────────────────────────────────────

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

class _RaisePurchasesSheetState extends ConsumerState<_RaisePurchasesSheet> {
  final Map<String, int> _selectedVendors = {};
  bool _persistVendorOnItems = false;

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(
      vendorsProvider(const VendorListQuery(limit: 200)),
    );
    final lines = widget.demand.lines;
    final ready = lines.isNotEmpty && _selectedVendors.length == lines.length;

    return AppSheetFrame(
      title: 'Raise Purchases',
      subtitle: 'Select a vendor for each shortage item. '
          '${_selectedVendors.length} of ${lines.length} assigned.',
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.border,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: !ready
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
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Raise Purchases'),
        ),
      ),
      child: vendorsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            error.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.danger),
          ),
        ),
        data: (page) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Builder(
                builder: (context) {
                  final itemId = _itemId(line);
                  return _VendorAssignment(
                    line: line,
                    vendors: page.vendors,
                    selectedVendorId:
                        itemId == null ? null : _selectedVendors[itemId],
                    onChanged: itemId == null
                        ? null
                        : (vendorId) => setState(
                              () => _selectedVendors[itemId] = vendorId,
                            ),
                  );
                },
              ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                activeThumbColor: AppColors.accent,
                value: _persistVendorOnItems,
                onChanged: (value) =>
                    setState(() => _persistVendorOnItems = value),
                title: const Text(
                  'Save vendor on item records',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Use these vendors as the default next time.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),
          ],
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
  final ValueChanged<int>? onChanged;

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
    final assigned = selectedVendorId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assigned
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$itemName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${itemId ?? '-'}',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (assigned) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 18, color: AppColors.accent),
              ],
            ],
          ),
          const SizedBox(height: 12),
          AppPickerField<int>(
            label: 'Vendor',
            hint: 'Select vendor',
            value: selectedVendorId,
            enabled: onChanged != null,
            options: [
              for (final vendor in vendors)
                AppPickerOption<int>(vendor.id, vendor.name),
            ],
            onChanged: (vendorId) => onChanged?.call(vendorId),
          ),
          if (onChanged == null) ...[
            const SizedBox(height: 8),
            Text(
              'This line has no item ID, so a vendor cannot be assigned.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail line tile
// ─────────────────────────────────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${itemName ?? 'Item'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Item ID: ${itemId ?? '-'}',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$quantity',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'SHORT',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

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
            Icon(Icons.error_outline, size: 38, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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