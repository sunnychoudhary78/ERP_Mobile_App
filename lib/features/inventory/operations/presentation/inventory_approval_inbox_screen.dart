import 'dart:convert';

import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_ui_helpers.dart';

class InventoryApprovalInboxScreen extends ConsumerStatefulWidget {
  const InventoryApprovalInboxScreen({super.key});

  @override
  ConsumerState<InventoryApprovalInboxScreen> createState() => _InventoryApprovalInboxScreenState();
}

class _InventoryApprovalInboxScreenState extends ConsumerState<InventoryApprovalInboxScreen>
    with InventoryUiHelpers<InventoryApprovalInboxScreen> {
  late Future<List<dynamic>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(inventoryRepositoryProvider);
    final auth = ref.read(authProvider);
    return Future.wait<dynamic>([
      auth.canAny(const [
            AppPermissions.approvalView,
            AppPermissions.myApprovalView,
          ])
          ? repo.getInventoryApprovals()
          : Future.value(<String, dynamic>{'data': <dynamic>[]}),
      auth.can(AppPermissions.myApprovalView)
          ? repo.getMyPendingApprovals()
          : Future.value(<String, dynamic>{'data': <dynamic>[]}),
      auth.can(AppPermissions.approvalView)
          ? repo.getMyApprovalRequests()
          : Future.value(<String, dynamic>{'data': <dynamic>[]}),
    ]);
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Team inbox'),
              Tab(text: 'My pending'),
              Tab(text: 'My requests'),
            ],
          ),
        ),
        body: loadBody<List<dynamic>>(
          future: _load,
          what: 'approvals',
          builder: _content,
        ),
      ),
    );
  }

  Widget _content(List<dynamic> data) {
    final inbox = asRows(data[0]);
    final minePending = asRows(data[1]);
    final mine = asRows(data[2]);
    final auth = ref.read(authProvider);
    final canApprove = auth.canAny(const [
      AppPermissions.approvalApprove,
      AppPermissions.myApprovalView,
    ]);
    final canReject = auth.can(AppPermissions.approvalReject) || canApprove;
    final canResubmit = auth.can(AppPermissions.myApprovalView);
    return TabBarView(
      children: [
        _approvalList(
          title: 'Team inbox',
          subtitle: 'Review and action requests from your team.',
          icon: Icons.inbox_outlined,
          rows: inbox,
          emptyTitle: 'Nothing to review',
          emptyMessage: 'No requests are waiting for your review.',
          itemBuilder: (r) =>
              _approvalCard(r, canApprove: canApprove, canReject: canReject),
        ),
        _approvalList(
          title: 'My pending',
          subtitle: 'Requests assigned to you that still need attention.',
          icon: Icons.hourglass_top_outlined,
          rows: minePending,
          emptyTitle: 'No pending approvals',
          emptyMessage: 'Requests awaiting a decision appear here.',
          itemBuilder: (r) => _approvalCard(r, resubmit: canResubmit),
        ),
        _approvalList(
          title: 'My requests',
          subtitle: 'Track the status of requests you have submitted.',
          icon: Icons.outbox_outlined,
          rows: mine,
          emptyTitle: 'No submitted requests',
          emptyMessage: 'Requests you have submitted appear here.',
          itemBuilder: (r) => _approvalCard(r, resubmit: canResubmit),
        ),
      ],
    );
  }

  Widget _approvalList({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> rows,
    required String emptyTitle,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) => refreshList([
    pageHeader(title: title, subtitle: subtitle, icon: icon),
    countBadge('Requests', rows.length, icon: icon),
    const SizedBox(height: 12),
    if (rows.isEmpty)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 9),
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      )
    else
      for (final row in rows) itemBuilder(row),
  ]);

  Widget _approvalCard(
    Map<String, dynamic> row, {
    bool canApprove = false,
    bool canReject = false,
    bool resubmit = false,
  }) {
    final id = row['requestId'] ?? row['id'];
    final title = pickText(row, [
      'title',
      'type',
      'requestType',
    ], fallback: 'Approval request');
    final status = pickText(row, ['status'], fallback: 'Pending');
    final scheme = Theme.of(context).colorScheme;
    final pending = status.toUpperCase() == 'PENDING';
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
            color: pending ? scheme.tertiaryContainer : scheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            pending ? Icons.hourglass_top : Icons.fact_check_outlined,
            color: pending
                ? scheme.onTertiaryContainer
                : scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$status  •  ${_requesterName(row)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (row['description'] != null || row['summary'] != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${row['description'] ?? row['summary']}'),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                if (id != null)
                  OutlinedButton.icon(
                    onPressed: () => _viewRequest(
                      row,
                      canApprove: canApprove,
                      canReject: canReject,
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View request'),
                  ),
                if (canApprove && id != null)
                  FilledButton.tonalIcon(
                    onPressed: () => _approvalDecision(id, approve: true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                if (canReject && id != null)
                  OutlinedButton.icon(
                    onPressed: () => _approvalDecision(id, approve: false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                /* Temporarily disabled at the user's request.
                if (id != null &&
                    ref.read(authProvider).can(AppPermissions.approvalForward))
                  OutlinedButton.icon(
                    onPressed: () => _forward(id),
                    icon: const Icon(Icons.forward),
                    label: const Text('Forward'),
                  ),
                */
                if (resubmit &&
                    id != null &&
                    status.toUpperCase() == 'REJECTED')
                  TextButton(
                    onPressed: () => mutate(
                      () => ref
                          .read(inventoryRepositoryProvider)
                          .resubmitInventoryRequest(id),
                      'Request resubmitted',
                    ),
                    child: const Text('Resubmit'),
                  ),
                /* Temporarily disabled at the user's request.
                if (resubmit && id != null && status.toUpperCase() != 'PENDING')
                  TextButton(
                    onPressed: () => _updateApproval(id, row),
                    child: const Text('Edit request (advanced)'),
                  ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewRequest(
    Map<String, dynamic> row, {
    required bool canApprove,
    required bool canReject,
  }) async {
    final id = row['requestId'] ?? row['id'];
    final title = _requestTitle(row);
    final status = pickText(row, ['status'], fallback: 'Unknown');
    final fields = _basicRequestFields(row);
    final requestedBy = _requesterName(row);
    final requestedAt = fmtDate(
      row['requestedAt'] ?? row['createdAt'] ?? row['submittedAt'],
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final screen = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.maxFinite,
            height: screen.height * .78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Request #$id  ·  ${_requestEntity(row)}  ·  By $requestedBy  ·  $requestedAt',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _requestFieldGrid([
                        MapEntry('Module', pickText(row, [
                          'module',
                          'moduleName',
                        ], fallback: title)),
                        MapEntry('Entity', _requestEntity(row)),
                        MapEntry('Status', status),
                        MapEntry(
                          'Requested at',
                          fmtDate(
                            row['requestedAt'] ??
                                row['createdAt'] ??
                                row['submittedAt'],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Text(
                        '${_requestEntity(row).toUpperCase()} DETAILS',
                        style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (fields.isEmpty)
                        Text(
                          'No basic request details were included in the approval response.',
                          style: Theme.of(dialogContext).textTheme.bodyMedium,
                        )
                      else
                        _requestFieldGrid(fields),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                      if (canReject && id != null)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext, 'reject'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      if (canApprove && id != null)
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(dialogContext, 'approve'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == 'approve' && id != null) {
      await _approvalDecision(id, approve: true);
    } else if (result == 'reject' && id != null) {
      await _approvalDecision(id, approve: false);
    }
  }

  dynamic _requestPayload(Map<String, dynamic> row) {
    for (final key in [
      'requestData',
      'requestedData',
      'requestPayload',
      'request',
      'details',
      'payload',
      'data',
      'changes',
    ]) {
      final value = row[key];
      if (value is Map || value is List) return value;
      if (value is String && value.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map || decoded is List) return decoded;
        } catch (_) {}
      }
    }
    const metadata = {
      'id',
      'requestId',
      'status',
      'type',
      'requestType',
      'title',
      'module',
      'moduleName',
      'entity',
      'entityName',
      'entityType',
      'requestedBy',
      'requestedByName',
      'submittedByName',
      'employeeName',
      'createdByName',
      'approverName',
      'requestedAt',
      'createdAt',
      'submittedAt',
      'description',
      'summary',
    };
    return Map<String, dynamic>.fromEntries(
      row.entries.where((entry) => !metadata.contains(entry.key)),
    );
  }

  String _requestTitle(Map<String, dynamic> row) {
    final title = pickText(row, ['title'], fallback: '');
    if (title.isNotEmpty) return title;
    return _titleCase(
      pickText(row, ['requestType', 'type'], fallback: 'Approval request'),
    );
  }

  String _requesterName(Map<String, dynamic> row) {
    for (final key in [
      'requestedByName',
      'employeeName',
      'createdByName',
      'submittedByName',
      'requestedBy',
    ]) {
      final value = row[key];
      final candidate = value is Map
          ? '${value['displayName'] ?? value['fullName'] ?? value['associatesName'] ?? value['name'] ?? ''}'
          : '${value ?? ''}';
      final name = candidate.trim();
      if (name.isEmpty ||
          RegExp(r'^\d+$').hasMatch(name) ||
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(name)) {
        continue;
      }
      return name;
    }
    return 'Unknown';
  }

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');

  List<MapEntry<String, String>> _basicRequestFields(
    Map<String, dynamic> row,
  ) {
    final all = _flattenRequestFields(_requestPayload(row));
    final type = pickText(row, ['requestType', 'type'], fallback: '')
        .toUpperCase();
    final preferred = type.startsWith('ITEM_') || type.startsWith('PRODUCT_')
        ? [
            'productcode',
            'name',
            'sku',
            'unit',
            'categoryid',
            'categoryname',
            'brandname',
            'brand',
            'mrp',
            'b2bprice',
            'sellingprice',
          ]
        : type.startsWith('CUSTOMER_') || type.startsWith('VENDOR_')
        ? ['name', 'email', 'phone', 'address', 'gstnumber']
        : type.startsWith('PURCHASE_')
        ? ['ponumber', 'vendorname', 'warehouse', 'totalamount', 'amount']
        : ['name', 'email', 'phone', 'quantity', 'amount', 'warehouse'];

    final selected = <MapEntry<String, String>>[];
    final used = <int>{};
    for (final key in preferred) {
      final index = all.indexWhere((field) {
        final normalized = field.key.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        return key == 'name'
            ? normalized == key
            : normalized == key || normalized.endsWith(key);
      });
      if (index >= 0 && used.add(index)) selected.add(all[index]);
      if (selected.length == 8) break;
    }
    if (selected.isNotEmpty) return selected;

    for (final field in all) {
      final normalized = field.key.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      if (normalized == 'id' ||
          normalized.endsWith('id') ||
          normalized.contains('createdat') ||
          normalized.contains('updatedat') ||
          normalized.contains('companyid') ||
          normalized.contains('userid')) {
        continue;
      }
      selected.add(field);
      if (selected.length == 6) break;
    }
    return selected;
  }

  String _requestEntity(Map<String, dynamic> row) {
    final explicit = pickText(row, ['entityName', 'entity', 'entityType'], fallback: '');
    if (explicit.isNotEmpty) return explicit;
    final type = pickText(row, ['requestType', 'type'], fallback: 'Request');
    final normalized = type.toUpperCase();
    for (final prefix in [
      'LOT_PROCESSING_',
      'PURCHASE_',
      'ITEM_',
      'VENDOR_',
      'CUSTOMER_',
      'SALES_',
      'CATEGORY_',
    ]) {
      if (normalized.startsWith(prefix)) {
        return prefix.replaceAll('_', ' ').trim().toLowerCase().split(' ')
            .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
      }
    }
    return 'Request';
  }

  List<MapEntry<String, String>> _flattenRequestFields(dynamic value) {
    final fields = <MapEntry<String, String>>[];
    void visit(dynamic current, String label) {
      if (current is Map) {
        for (final entry in current.entries) {
          final key = entry.key.toString();
          visit(entry.value, label.isEmpty ? key : '$label · $key');
        }
      } else if (current is List) {
        for (var i = 0; i < current.length; i++) {
          visit(current[i], '$label ${i + 1}');
        }
      } else if (label.isNotEmpty) {
        final display = current == null
            ? '—'
            : current is bool
            ? (current ? 'Yes' : 'No')
            : '$current';
        fields.add(MapEntry(fieldLabel(label), display));
      }
    }

    visit(value, '');
    return fields;
  }

  Widget _requestFieldGrid(List<MapEntry<String, String>> fields) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final gap = 10.0;
          final width = constraints.maxWidth >= 500
              ? (constraints.maxWidth - gap) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final field in fields)
                SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: .7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.key.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .35,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SelectableText(
                          field.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Future<void> _approvalDecision(dynamic id, {required bool approve}) async {
    final note = TextEditingController();
    final result = await textDialog(
      title: approve ? 'Approve request' : 'Reject request',
      label: 'Note (optional)',
      controller: note,
      multiline: true,
      confirm: approve ? 'Approve' : 'Reject',
    );
    if (!result) return;
    await mutate(
      () => approve
          ? ref
                .read(inventoryRepositoryProvider)
                .approveInventoryRequest(id, note: note.text.trim())
          : ref
                .read(inventoryRepositoryProvider)
                .rejectInventoryRequest(id, note: note.text.trim()),
      approve ? 'Request approved' : 'Request rejected',
    );
  }

  // Retained so the forwarding flow can be restored when needed.
  // ignore: unused_element
  Future<void> _forward(dynamic id) async {
    final userId = TextEditingController();
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward request'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forward sends this approval to another approver for review. Enter that user’s account ID (UUID).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: userId,
                  decoration: const InputDecoration(
                    labelText: 'Approver user ID (UUID)',
                    helperText: 'Ask your administrator for this ID.',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  validator: (value) {
                    final id = (value ?? '').trim();
                    if (id.isEmpty) return 'Enter the approver user ID';
                    if (!RegExp(
                      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                    ).hasMatch(id)) {
                      return 'Enter a valid UUID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Forward'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await mutate(
      () => ref
          .read(inventoryRepositoryProvider)
          .forwardInventoryRequest(
            id,
            forwardToUserId: userId.text.trim(),
            note: note.text.trim(),
          ),
      'Request forwarded',
    );
  }

  // Retained so request editing can be restored when needed.
  // ignore: unused_element
  Future<void> _updateApproval(dynamic id, Map<String, dynamic> row) async {
    final current = _requestPayload(row);
    final initial = current is Map
        ? Map<String, dynamic>.from(current)
        : current is List
        ? <String, dynamic>{'items': current}
        : <String, dynamic>{};
    final data = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(initial),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Edit request data'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This advanced editor updates the saved request fields. The values are shown as JSON because fields differ by request type. Keep the field names and enter a valid JSON object. Updating does not approve the request.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: data,
                  minLines: 10,
                  maxLines: 16,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Request fields (JSON object)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.data_object),
                  ),
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
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final decoded = jsonDecode(data.text);
      if (decoded is! Map<String, dynamic>)
        throw const FormatException('Enter a JSON object.');
      await mutate(
        () => ref
            .read(inventoryRepositoryProvider)
            .updateInventoryRequest(id, decoded),
        'Request updated',
      );
    } catch (e) {
      showError(e);
    }
  }
}
