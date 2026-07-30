import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class QuoteFormScreen extends StatelessWidget {
  const QuoteFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Create / Edit Quote',
      subtitle: 'TODO: Simplified mobile quote form.',
      featurePath: 'lib/features/crm/quotes/',
    );
  }
}
