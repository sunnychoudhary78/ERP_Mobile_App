import 'package:flutter/material.dart';

/// Contacts are derived from leads — create via lead form.
class ContactFormScreen extends StatelessWidget {
  const ContactFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacts come from leads (no separate create API).',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use Add Lead to create a contact, or edit an existing lead.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                '/crm/leads/form',
              ),
              child: const Text('Go to Add Lead'),
            ),
          ],
        ),
      ),
    );
  }
}
