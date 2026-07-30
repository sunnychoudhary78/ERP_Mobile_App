import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class ApprovalsInboxScreen extends StatelessWidget {
  const ApprovalsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Approvals Inbox',
      subtitle:
          'TODO: One list for pending leave + CRM approvals. Approve / reject with comment.',
      featurePath: 'lib/features/approvals/',
    );
  }
}
