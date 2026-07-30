import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class StockLookupScreen extends StatelessWidget {
  const StockLookupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Stock Lookup',
      subtitle:
          'TODO: Search item by name / SKU / barcode. Show qty by warehouse.',
      featurePath: 'lib/features/inventory/',
    );
  }
}
