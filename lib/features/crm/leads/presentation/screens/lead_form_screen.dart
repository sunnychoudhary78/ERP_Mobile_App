import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

/// Thin form stub — junior builds real fields; submit calls [createLead].
class LeadFormScreen extends ConsumerStatefulWidget {
  const LeadFormScreen({super.key});

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(salesWorkspaceProvider.notifier).createLead({
        'companyName': _company.text.trim(),
        'contactName': _contact.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
      });
      if (mounted) {
        setState(() => _message = 'Lead created');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lead')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Logic ready — raw fields for junior UI polish.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'submit → salesWorkspaceProvider.notifier.createLead(payload)\n'
            'Expected keys: companyName, contactName, phone, email, '
            'source, requirements, requirementLines, …',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _company,
            decoration: const InputDecoration(labelText: 'Company'),
          ),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(labelText: 'Contact'),
          ),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Saving…' : 'Create lead'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
