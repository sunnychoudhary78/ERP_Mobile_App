import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class LeadsListScreen extends ConsumerWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmLeadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Leads')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/crm/leads/form'),
        child: const Icon(Icons.add),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (leads) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${leads.length} lead(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'TODO (UI): cards/filters.\n'
                'Provider: crmLeadsProvider / salesWorkspaceProvider\n'
                'Create: createLead(payload) · Detail: /crm/leads/detail args leadId',
              ),
              if (leads.isEmpty)
                const Text('No leads yet.')
              else
                ...leads.map(
                  (l) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.companyName.isEmpty ? l.contactName : l.companyName,
                    ),
                    subtitle: Text(
                      '${l.status} · ${l.phone.isEmpty ? l.email : l.phone}'
                      '${l.lifecycleStage != null ? ' · ${l.lifecycleStage}' : ''}',
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/crm/leads/detail',
                      arguments: l.id,
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
