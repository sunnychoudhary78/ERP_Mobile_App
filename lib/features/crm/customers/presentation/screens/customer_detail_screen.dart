import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Customer Detail',
      subtitle: 'TODO: Customer detail + link to lead / order context.',
      featurePath: 'lib/features/crm/customers/',
    );
  }
}
