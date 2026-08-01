import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(crmCustomersProvider.notifier).refresh(),
        builder: (customers) => RefreshIndicator(
          onRefresh: () =>
              ref.read(crmCustomersProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${customers.length} customer(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const CrmLogicHint(
                'Source: GET /api/customers via crmCustomersProvider.\n'
                'Also: matchCustomer / linkCustomer / ensureCustomer on leads.',
              ),
              if (customers.isEmpty)
                const Text('No customers.')
              else
                ...customers.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        if (c.phone != null && c.phone!.isNotEmpty) c.phone,
                        if (c.email != null && c.email!.isNotEmpty) c.email,
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/crm/customers/detail',
                      arguments: c.id,
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
