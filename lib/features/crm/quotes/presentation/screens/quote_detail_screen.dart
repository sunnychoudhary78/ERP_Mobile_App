import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class QuoteDetailScreen extends StatelessWidget {
  const QuoteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Quote Detail',
      subtitle: 'TODO: Quote detail + approval flow.',
      featurePath: 'lib/features/crm/quotes/',
    );
  }
}
