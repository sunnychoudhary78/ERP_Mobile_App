import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class VisitCheckInScreen extends ConsumerStatefulWidget {
  const VisitCheckInScreen({super.key});

  @override
  ConsumerState<VisitCheckInScreen> createState() => _VisitCheckInScreenState();
}

class _VisitCheckInScreenState extends ConsumerState<VisitCheckInScreen> {
  final _client = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _client.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(salesWorkspaceProvider.notifier).checkInVisit({
        'clientName': _client.text.trim(),
        'location': _location.text.trim(),
        'notes': _notes.text.trim(),
        'visitType': 'Field',
      });
      setState(() => _message = 'Visit checked in');
      _client.clear();
      _location.clear();
      _notes.clear();
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
    final async = ref.watch(crmVisitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Visits')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Logic ready — check-in + visit history.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const CrmLogicHint(
            'checkInVisit(payload) — junior adds GPS/photo.\n'
            'Payload: clientName, location, notes, visitType, lat/lng…',
          ),
          TextField(
            controller: _client,
            decoration: const InputDecoration(labelText: 'Client name'),
          ),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _checkIn,
            child: Text(_submitting ? 'Saving…' : 'Check in'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!),
          ],
          const Divider(height: 32),
          CrmAsyncBody(
            async: async,
            onRetry: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            builder: (visits) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${visits.length} visit(s)'),
                ...visits.map(
                  (v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(v.clientName),
                    subtitle: Text(
                      '${v.at ?? '—'} · ${v.location} · ${v.repName ?? ''}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
