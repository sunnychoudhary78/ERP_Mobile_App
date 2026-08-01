import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leave_status_provider.dart';

/// Logic wired via [leaveStatusProvider]. Details: [leaveDetailsProvider](id).
class LeaveStatusScreen extends ConsumerWidget {
  const LeaveStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaveStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Leave Requests')),
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
                      ref.read(leaveStatusProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (requests) => RefreshIndicator(
          onRefresh: () => ref.read(leaveStatusProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${requests.length} request(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'TODO (UI): cards + timeline.\n'
                'Withdraw: leaveStatusProvider.notifier.revokeLeave(id)\n'
                'Details: leaveDetailsProvider(id)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...requests.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.leaveType ?? r.reference),
                  subtitle: Text(
                    '${r.startDate} → ${r.endDate} · ${r.status}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
