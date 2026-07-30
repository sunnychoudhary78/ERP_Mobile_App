import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class VisitCheckInScreen extends StatelessWidget {
  const VisitCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Visit Check-in',
      subtitle:
          'TODO: Start / end visit with GPS, photo proof, note / outcome. My visits today / history.',
      featurePath: 'lib/features/crm/visits/',
    );
  }
}
