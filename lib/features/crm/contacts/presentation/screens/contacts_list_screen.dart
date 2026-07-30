import 'package:flutter/material.dart';

import '../../../../../core/widgets/placeholder_screen.dart';

class ContactsListScreen extends StatelessWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Contacts',
      subtitle: 'TODO: Contacts list + search. Backend CRM API pending.',
      featurePath: 'lib/features/crm/contacts/',
    );
  }
}
