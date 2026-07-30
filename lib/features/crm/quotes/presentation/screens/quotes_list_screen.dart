import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class QuotesListScreen extends StatelessWidget {
  const QuotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Quotes',
      subtitle: 'TODO: Quotes list. Backend CRM API pending.',
      featurePath: 'lib/features/crm/quotes/',
    );
  }
}
