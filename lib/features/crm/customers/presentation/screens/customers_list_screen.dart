import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class CustomersListScreen extends StatelessWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Customers',
      subtitle: 'TODO: Customers list + search. Backend CRM API pending.',
      featurePath: 'lib/features/crm/customers/',
    );
  }
}
