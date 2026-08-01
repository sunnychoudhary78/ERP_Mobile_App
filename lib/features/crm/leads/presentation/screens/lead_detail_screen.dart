import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadId = ModalRoute.of(context)?.settings.arguments as String?;
    final lead =
        leadId == null ? null : ref.watch(crmLeadByIdProvider(leadId));
    final ws = ref.watch(salesWorkspaceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lead Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ws.isLoading
            ? const Center(child: CircularProgressIndicator())
            : lead == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leadId == null
                            ? 'Pass leadId via Navigator arguments.'
                            : 'Lead not found: $leadId',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TODO (UI): full lead profile, timeline, actions.',
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      Text(
                        lead.companyName.isEmpty
                            ? lead.contactName
                            : lead.companyName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${lead.status}'),
                      Text('Stage: ${lead.lifecycleStage ?? '—'}'),
                      Text('Contact: ${lead.contactName}'),
                      Text('Phone: ${lead.phone}'),
                      Text('Email: ${lead.email}'),
                      Text('Owner: ${lead.ownerName}'),
                      Text('Value: ${lead.value}'),
                      Text('CustomerId: ${lead.customerId ?? '—'}'),
                      const SizedBox(height: 16),
                      Text(
                        'Actions (notifier):\n'
                        'qualifyLead · updateLead · logFollowUp · createQuote\n'
                        'markWon / markLost · requestWonApproval\n'
                        'ensureCustomer / linkCustomer',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
      ),
    );
  }
}
