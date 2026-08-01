import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

/// Thin quote create — needs leadId argument; junior builds line items UI.
class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({super.key});

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _leadId = TextEditingController();
  final _account = TextEditingController();
  final _amount = TextEditingController();
  bool _submitting = false;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _leadId.text.isEmpty) {
      _leadId.text = arg;
    }
  }

  @override
  void dispose() {
    _leadId.dispose();
    _account.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final leadId = _leadId.text.trim();
    if (leadId.isEmpty) {
      setState(() => _message = 'leadId is required');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(salesWorkspaceProvider.notifier).createQuote(leadId, {
        'account': _account.text.trim(),
        'amount': double.tryParse(_amount.text.trim()) ?? 0,
        'lines': const [],
      });
      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Create Quote')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Logic ready — raw quote create.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'createQuote(leadId, payload) — junior should add line items UI.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _leadId,
            decoration: const InputDecoration(labelText: 'Lead ID'),
          ),
          TextField(
            controller: _account,
            decoration: const InputDecoration(labelText: 'Account'),
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Saving…' : 'Create quote'),
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
