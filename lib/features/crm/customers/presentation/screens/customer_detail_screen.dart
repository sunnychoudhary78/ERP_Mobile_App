import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/inventory_customer_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerId = ModalRoute.of(context)?.settings.arguments as String?;
    InventoryCustomer? customer;
    final list = ref.watch(crmCustomersProvider).value;
    if (customerId != null && list != null) {
      for (final c in list) {
        if (c.id == customerId) {
          customer = c;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: customer == null
            ? Text(
                customerId == null
                    ? 'Pass customerId via Navigator arguments.'
                    : 'Customer not found: $customerId',
              )
            : ListView(
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Phone: ${customer.phone ?? '—'}'),
                  Text('Email: ${customer.email ?? '—'}'),
                  Text('Address: ${customer.address ?? '—'}'),
                  Text('Status: ${customer.status ?? '—'}'),
                  const SizedBox(height: 12),
                  Text(
                    'TODO (UI): polish customer profile / linked leads.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}
