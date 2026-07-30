import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Activities',
      subtitle: 'TODO: Activity log (call, meeting, follow-up). Add on lead / contact.',
      featurePath: 'lib/features/crm/activities/',
    );
  }
}
