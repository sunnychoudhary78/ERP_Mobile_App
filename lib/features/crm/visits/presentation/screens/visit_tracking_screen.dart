import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

/// Team tracking — thin list of visits (map UI for junior).
class VisitTrackingScreen extends ConsumerWidget {
  const VisitTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmVisitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team Tracking')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (visits) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${visits.length} visit(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'TODO (UI): map + live tracking.\n'
                'Data: crmVisitsProvider (workspace visits).\n'
                'Optional: salesCrmApi.getTeamStats() for team summary.',
              ),
              if (visits.isEmpty)
                const Text('No visits to track.')
              else
                ...visits.map(
                  (v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(v.clientName),
                    subtitle: Text(
                      '${v.repName ?? '—'} · ${v.location} · ${v.at ?? '—'}',
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
