import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class VisitTrackingScreen extends StatelessWidget {
  const VisitTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Team Tracking',
      subtitle: 'TODO: Manager team last-location / tracking view.',
      featurePath: 'lib/features/crm/visits/',
    );
  }
}
