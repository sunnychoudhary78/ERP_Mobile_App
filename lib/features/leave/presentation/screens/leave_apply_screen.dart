import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leave_apply_provider.dart';
import '../providers/leave_balance_provider.dart';

/// Logic wired via [leaveApplyProvider] + [leaveBalanceProvider].
/// Junior: build form UI (type, dates, reason, document) then call submitLeave.
class LeaveApplyScreen extends ConsumerWidget {
  const LeaveApplyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applyState = ref.watch(leaveApplyProvider);
    final balances = ref.watch(leaveBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Apply')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logic ready — build apply form UI here.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Providers:\n'
              '• leaveBalanceProvider — leave types + balance for dropdown\n'
              '• leaveApplyProvider — submitLeave(data, document)\n'
              '• leaveTypeProvider — optional catalog of leave types\n\n'
              'submitLeave data keys (LMS-compatible):\n'
              'leaveTypeId, startDate, endDate, isHalfDay, halfDayPart, reason',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            balances.when(
              loading: () => const Text('Loading balances…'),
              error: (e, _) => Text('Balances error: $e'),
              data: (list) => Text('${list.length} leave type(s) available'),
            ),
            const SizedBox(height: 12),
            Text('Apply status: ${applyState.status.name}'),
            if (applyState.message != null) Text(applyState.message!),
          ],
        ),
      ),
    );
  }
}
