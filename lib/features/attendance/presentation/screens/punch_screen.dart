import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

class PunchScreen extends StatelessWidget {
  const PunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Attendance Punch',
      subtitle:
          'TODO: Punch In / Out with GPS. Selfie only if company mobile-config requires it.',
      featurePath: 'lib/features/attendance/',
    );
  }
}
