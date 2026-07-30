import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Pipeline',
      subtitle: 'TODO: Pipeline stages board. Move lead across stages.',
      featurePath: 'lib/features/crm/pipeline/',
    );
  }
}
