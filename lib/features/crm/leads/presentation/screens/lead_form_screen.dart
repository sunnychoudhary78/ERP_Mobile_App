import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class LeadFormScreen extends StatelessWidget {
  const LeadFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Create / Edit Lead',
      subtitle: 'TODO: Create / edit lead form.',
      featurePath: 'lib/features/crm/leads/',
    );
  }
}
