import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/sales_contact_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadId = ModalRoute.of(context)?.settings.arguments as String?;
    final async = ref.watch(crmContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Detail')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (contacts) {
          SalesContact? contact;
          if (leadId != null) {
            for (final c in contacts) {
              if (c.leadId == leadId) {
                contact = c;
                break;
              }
            }
          }

          if (contact == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                leadId == null
                    ? 'Pass leadId via Navigator arguments.'
                    : 'Contact not found for lead $leadId',
              ),
            );
          }

          final c = contact;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(c.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Role: ${c.role}'),
              Text('Account: ${c.account}'),
              Text('Phone: ${c.phone}'),
              Text('Email: ${c.email}'),
              Text('Owner: ${c.owner}'),
              Text('Status: ${c.status}'),
              Text('Lead: ${c.leadId}'),
              const SizedBox(height: 12),
              Text(
                'TODO (UI): polish contact profile.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
