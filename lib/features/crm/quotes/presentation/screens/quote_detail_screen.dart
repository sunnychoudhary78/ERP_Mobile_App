import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class QuoteDetailScreen extends ConsumerWidget {
  const QuoteDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteId = ModalRoute.of(context)?.settings.arguments as String?;
    final quote =
        quoteId == null ? null : ref.watch(crmQuoteByIdProvider(quoteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quote Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: quote == null
            ? Text(
                quoteId == null
                    ? 'Pass quoteId via Navigator arguments.'
                    : 'Quote not found: $quoteId',
              )
            : ListView(
                children: [
                  Text(
                    quote.number ?? quote.id,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Account: ${quote.account ?? '—'}'),
                  Text('Status: ${quote.status}'),
                  Text('Amount: ${quote.amount}'),
                  Text('GST: ${quote.gstAmount}'),
                  Text('Lead: ${quote.leadId ?? '—'}'),
                  Text('Valid until: ${quote.validUntil ?? '—'}'),
                  Text(
                    'Approval: ${quote.approval['status'] ?? '—'}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actions: sendQuote · approveQuote · rejectQuote · updateQuote',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}
