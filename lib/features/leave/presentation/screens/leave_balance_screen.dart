import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class LeaveBalanceScreen extends StatelessWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Leave Balance',
      subtitle: 'TODO: Show leave balances by type.',
      featurePath: 'lib/features/leave/',
    );
  }
}
