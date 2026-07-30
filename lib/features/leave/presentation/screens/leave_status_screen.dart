import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeaveStatusScreen extends StatelessWidget {
  const LeaveStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'My Leave Requests',
      subtitle: 'TODO: List my leave requests with status.',
      featurePath: 'lib/features/leave/',
    );
  }
}
