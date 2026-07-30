import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Notifications',
      subtitle:
          'TODO: Inbox for approval assigned and leave / CRM status updates.',
      featurePath: 'lib/features/notifications/',
    );
  }
}
