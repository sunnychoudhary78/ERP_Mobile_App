import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class WorkOrdersScreen extends StatelessWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Work Orders',
      subtitle:
          'TODO: My open work orders. Update status: start / complete / hold + remark.',
      featurePath: 'lib/features/production/',
    );
  }
}
