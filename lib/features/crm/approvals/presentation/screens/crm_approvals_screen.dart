import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class CrmApprovalsScreen extends ConsumerWidget {
  const CrmApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmApprovalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CRM Approvals')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${items.length} pending item(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'TODO (UI): approve/reject modals.\n'
                'Won: approveWon(leadId) / rejectWon(leadId, reason)\n'
                'Quote: approveQuote(id) / rejectQuote(id, reason)',
              ),
              if (items.isEmpty)
                const Text('No pending CRM approvals.')
              else
                ...items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text('${item.subtitle} · ${item.status}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            final n =
                                ref.read(salesWorkspaceProvider.notifier);
                            try {
                              if (item.kind == 'won') {
                                await n.approveWon(item.id);
                              } else {
                                await n.approveQuote(item.id);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.cancel_outlined),
                          onPressed: () async {
                            final n =
                                ref.read(salesWorkspaceProvider.notifier);
                            try {
                              if (item.kind == 'won') {
                                await n.rejectWon(item.id, 'Rejected');
                              } else {
                                await n.rejectQuote(item.id, 'Rejected');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
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
