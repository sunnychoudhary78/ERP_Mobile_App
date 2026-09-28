import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared helpers for every inventory section screen.
///
/// Every section owns its own Future and its own typed builder, so one
/// section's data can never reach another section's builder. (Sharing a single
/// FutureBuilder between tabs was the cause of both the
/// `RangeError (length)` and the
/// `List<dynamic> is not a subtype of List<Warehouse>` crashes.)
mixin InventoryUiHelpers<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Each screen implements this to re-run its own loader.
  void reload();

  // ------------------------------------------------------------ loading
  /// Spinner while loading, friendly retry state on error, and a friendly
  /// retry state (instead of the red screen) if the data has an unexpected
  /// shape.
  Widget loadBody<D>({
    required Future<D> future,
    required String what,
    required Widget Function(D data) builder,
  }) {
    return FutureBuilder<D>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return messageList(
            'Could not load $what',
            _clean(snapshot.error),
            retry: true,
          );
        }
        try {
          return builder(snapshot.data as D);
        } catch (e, st) {
          debugPrint('Could not display $what: $e\n$st');
          return messageList(
            'Could not display $what',
            _clean(e),
            retry: true,
          );
        }
      },
    );
  }

  String _clean(Object? e) => '$e'.replaceFirst('Exception: ', '');

  /// Awaits a repository call and returns it as a plain list.
  Future<List<dynamic>> asList(Future<dynamic> pending) async =>
      List<dynamic>.from((await pending) as List);

  // ------------------------------------------------------------ lists
  Widget refreshList(
    List<Widget> children, {
    EdgeInsets padding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
  }) => RefreshIndicator(
    onRefresh: () async => reload(),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    ),
  );

  Widget cardList<E>(
    Iterable<E> items, {
    required String emptyTitle,
    required String emptyMessage,
    required Widget Function(E item) itemBuilder,
  }) {
    if (items.isEmpty) return messageList(emptyTitle, emptyMessage);
    return refreshList([for (final item in items) itemBuilder(item)]);
  }

  Widget messageList(String title, String message, {bool retry = false}) =>
      RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 80),
            Icon(
              retry ? Icons.cloud_off_outlined : Icons.inbox_outlined,
              size: 42,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            if (retry)
              Center(
                child: TextButton(
                  onPressed: reload,
                  child: const Text('Retry'),
                ),
              ),
          ],
        ),
      );

  // ------------------------------------------------------------ small widgets
  Widget pageHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget countBadge(String label, int count, {IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 7),
          ],
          Text(
            '$label  ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget dataCard({
    required String title,
    String? subtitle,
    String? amount,
    required IconData icon,
    VoidCallback? onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
      trailing: amount == null
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 104),
              child: Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
      onTap: onTap,
    ),
  );

  Widget metricCard(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );

  Widget hintText(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(message, style: const TextStyle(color: Colors.black54)),
  );


  Widget recordCard(
    Map<String, dynamic> row,
    List<String> keys, {
    required IconData icon,
  }) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(pickText(row, keys, fallback: 'Record')),
      subtitle: Text(
        [
          pickText(row, ['status'], fallback: ''),
          pickText(row, ['amount', 'totalAmount'], fallback: ''),
        ].where((v) => v.isNotEmpty).join('  •  '),
      ),
    ),
  );

  // ------------------------------------------------------------ data helpers
  Map<String, dynamic> mapOf(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  String pickText(
    Map<String, dynamic> value,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final v = value[key];
      if (v is Map && v['name'] != null) return '${v['name']}';
      if (v != null && '$v'.trim().isNotEmpty) return '$v';
    }
    return fallback;
  }

  int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  String fmtMoney(dynamic v) {
    final n = v is num ? v : num.tryParse('$v') ?? 0;
    return n.toStringAsFixed(2);
  }

  String fmtDate(dynamic v) {
    if (v == null) return '—';
    final date = DateTime.tryParse('$v')?.toLocal();
    return date == null
        ? '$v'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }


  List<Map<String, dynamic>> asRows(dynamic input) {
    dynamic value = input;
    if (value is Map && value['data'] != null) value = value['data'];
    if (value is Map) {
      for (final key in [
        'data',
        'items',
        'approvals',
        'requests',
        'customers',
        'sales',
        'invoices',
        'creditNotes',
        'salesReturns',
        'returns',
        'orders',
      ]) {
        if (value[key] is List) {
          value = value[key];
          break;
        }
      }
    }
    return value is List
        ? value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];
  }


  String fieldLabel(String value) => value
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
      .replaceAll('_', ' ')
      .trim();

  // ------------------------------------------------------------ dialogs
  Future<bool> textDialog({
    required String title,
    required String label,
    required TextEditingController controller,
    bool multiline = false,
    required String confirm,
  }) async =>
      (await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: multiline ? 5 : 1,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
          ],
        ),
      )) ==
      true;
  Future<bool> confirmDialog(String title, String message) async =>
      (await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
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
      )) ==
      true;
  Future<void> mutate(
    Future<dynamic> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      reload();
    } catch (e) {
      showError(e);
    }
  }


  Future<void> showDetails(Map<String, dynamic> record) =>
      showModalBottomSheet<void>(
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
                  pickText(record, ['name', 'billNo'], fallback: 'Details'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final entry in record.entries)
                  ListTile(
                    dense: true,
                    title: Text(entry.key),
                    subtitle: Text('${entry.value ?? '—'}'),
                  ),
              ],
            ),
          ),
        ),
      );


  void showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    reload();
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_clean(error))),
    );
  }
}
