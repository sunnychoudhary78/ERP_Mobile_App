import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/approvals_inbox_provider.dart';

/// Logic wired via [approvalsInboxProvider] (leave approvals only for now).
class ApprovalsInboxScreen extends ConsumerWidget {
  const ApprovalsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalsInboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals Inbox')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(approvalsInboxProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(approvalsInboxProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${items.length} item(s) (leave).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'TODO (UI): approve/reject with comment.\n'
                'approveLeave(item, comment:, dates:)\n'
                'rejectLeave(item, comment:)\n'
                'Item.type == ApprovalInboxType.leave\n'
                'CRM approvals: not wired (backend pending)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('${item.subtitle} · ${item.status}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
