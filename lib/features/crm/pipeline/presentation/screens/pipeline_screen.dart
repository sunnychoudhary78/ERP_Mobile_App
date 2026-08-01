import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmPipelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (stages) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${stages.length} stage(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'TODO (UI): kanban columns.\n'
                'Provider: crmPipelineProvider (Map stage → List<SalesLead>)\n'
                'Move stage: updateLead / qualifyLead',
              ),
              if (stages.isEmpty)
                const Text('No pipeline data.')
              else
                ...stages.entries.expand((e) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        '${e.key} (${e.value.length})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ...e.value.map(
                      (l) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          l.companyName.isEmpty
                              ? l.contactName
                              : l.companyName,
                        ),
                        subtitle: Text(l.status),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/crm/leads/detail',
                          arguments: l.id,
                        ),
                      ),
                    ),
                  ];
                }),
            ],
          ),
        ),
      ),
    );
  }
}
