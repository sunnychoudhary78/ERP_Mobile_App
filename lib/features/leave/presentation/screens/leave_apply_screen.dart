import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeaveApplyScreen extends StatelessWidget {
  const LeaveApplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Apply Leave',
      subtitle: 'TODO: Leave apply form (type, dates, reason).',
      featurePath: 'lib/features/leave/',
    );
  }
}
