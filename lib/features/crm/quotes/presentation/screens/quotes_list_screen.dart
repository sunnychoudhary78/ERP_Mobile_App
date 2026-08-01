import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class QuotesListScreen extends ConsumerWidget {
  const QuotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmQuotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/crm/quotes/form'),
        child: const Icon(Icons.add),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (quotes) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${quotes.length} quote(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'Provider: crmQuotesProvider\n'
                'createQuote(leadId, payload) · approveQuote / rejectQuote / sendQuote',
              ),
              if (quotes.isEmpty)
                const Text('No quotes.')
              else
                ...quotes.map(
                  (q) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(q.number ?? q.account ?? q.id),
                    subtitle: Text(
                      '${q.status} · ${q.amount} · lead ${q.leadId ?? '—'}',
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/crm/quotes/detail',
                      arguments: q.id,
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
