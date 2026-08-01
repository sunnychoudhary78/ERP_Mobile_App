import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (contacts) => RefreshIndicator(
          onRefresh: () =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${contacts.length} contact(s) (from leads).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'Derived via crmContactsProvider (SalesContact.fromLead).\n'
                'TODO (UI): contact cards. Detail args: leadId',
              ),
              if (contacts.isEmpty)
                const Text('No contacts.')
              else
                ...contacts.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    subtitle: Text(
                      '${c.account} · ${c.phone.isEmpty ? c.email : c.phone}',
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/crm/contacts/detail',
                      arguments: c.leadId,
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
