import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Contact Detail',
      subtitle: 'TODO: Contact detail screen.',
      featurePath: 'lib/features/crm/contacts/',
    );
  }
}
