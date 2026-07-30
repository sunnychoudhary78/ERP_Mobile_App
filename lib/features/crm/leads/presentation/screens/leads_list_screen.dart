import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class LeadsListScreen extends StatelessWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Leads',
      subtitle: 'TODO: Leads list, search, filters. Backend CRM API pending.',
      featurePath: 'lib/features/crm/leads/',
    );
  }
}
