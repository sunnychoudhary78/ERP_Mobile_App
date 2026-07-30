import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class ContactFormScreen extends StatelessWidget {
  const ContactFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Create / Edit Contact',
      subtitle: 'TODO: Create / update contact form.',
      featurePath: 'lib/features/crm/contacts/',
    );
  }
}
