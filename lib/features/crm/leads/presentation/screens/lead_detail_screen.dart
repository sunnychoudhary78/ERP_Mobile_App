import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Lead Detail',
      subtitle: 'TODO: Lead detail with status and next action.',
      featurePath: 'lib/features/crm/leads/',
    );
  }
}
