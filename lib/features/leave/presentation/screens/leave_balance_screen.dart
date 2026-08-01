import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leave_balance_provider.dart';

/// Logic wired via [leaveBalanceProvider]. Replace body with real UI.
class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaveBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Balance')),
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
                      ref.read(leaveBalanceProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (balances) => RefreshIndicator(
          onRefresh: () => ref.read(leaveBalanceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${balances.length} leave type(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'TODO (UI): show balances by type.\n'
                'Provider: leaveBalanceProvider\n'
                'Model: LeaveBalance (name, available, carried, …)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...balances.map(
                (b) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.name.isEmpty ? b.leaveTypeId : b.name),
                  subtitle: Text(
                    'Available: ${b.available} · Pending: ${b.pendingReserved}',
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
