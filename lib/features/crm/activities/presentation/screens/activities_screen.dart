import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Follow-ups')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (activities) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${activities.length} activity(ies).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'TODO (UI): follow-up list + complete action.\n'
                'completeActivity(id, notes:)\n'
                'logFollowUp(leadId, payload)',
              ),
              if (activities.isEmpty)
                const Text('No follow-ups.')
              else
                ...activities.map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      a.subject.isEmpty ? (a.type ?? 'Activity') : a.subject,
                    ),
                    subtitle: Text(
                      '${a.status} · due ${a.dueAt ?? '—'} · ${a.related}',
                    ),
                    trailing: a.status.toLowerCase() == 'completed'
                        ? null
                        : IconButton(
                            tooltip: 'Complete',
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(salesWorkspaceProvider.notifier)
                                    .completeActivity(a.id);
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
