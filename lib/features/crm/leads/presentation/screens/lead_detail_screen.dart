import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/crm/activities/presentation/screens/follow_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/sales_lead_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({super.key});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  int _selectedTabIndex = 0;
  bool _actionBusy = false;

  // Stage to actions mapping based on your screenshots
  static const Map<String, List<String>> _stageActions = {
    // Initial stage - just created
    'lead_entered': ['edit', 'assign', 'qualify'],
    
    // Client type stage - before qualification
    'client_type': ['edit', 'assign', 'qualify'],
    
    // Qualification stage - shown in screenshots 1, 6
    'qualify': ['edit', 'assign', 'qualify', 'log_followup'],
    
    // Follow-up stage - shown in screenshots 2, 3, 4, 7
    'follow_up': ['edit', 'assign', 'log_followup', 'create_quotation'],
    
    // Quotation stage - shown in screenshot 5
    'quotation': ['edit', 'assign', 'log_followup', 'edit_quotation', 'email_quote', 'download_quote', 'move_negotiation'],
    
    // Negotiation stage - shown in screenshot 7
    'negotiation': ['edit', 'assign', 'log_followup', 'create_quotation', 'move_negotiation'],
    
    // Won stage - show bill/sales order actions
    'won': ['view_customer', 'view_bill', 'download_bill', 'email_bill', 'view_sales_order'],
    
    // Lost stage - minimal actions
    'lost': ['view_customer'],
  };

  String _leadDisplayName(SalesLead lead) {
    if (lead.companyName.isNotEmpty) return lead.companyName;
    if (lead.contactName.isNotEmpty) return lead.contactName;
    return lead.id;
  }

  bool _isClosed(SalesLead lead) {
    final s = lead.status.toLowerCase();
    final stage = (lead.lifecycleStage ?? '').toLowerCase();
    return s == 'lost' ||
        s == 'converted' ||
        stage == 'lost' ||
        stage == 'won';
  }

  bool _isWon(SalesLead lead) {
    final stage = (lead.lifecycleStage ?? '').toLowerCase();
    return stage == 'won' || stage == 'converted';
  }

  String _normalizeStage(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<String> _getAllowedActions(SalesLead lead) {
    if (_isWon(lead)) return _stageActions['won'] ?? ['view_customer'];
    if (_isClosed(lead)) return _stageActions['lost'] ?? ['view_customer'];
    
    final stage = (lead.lifecycleStage ?? '').toLowerCase();
    final normalized = _normalizeStage(stage);
    
    // Map stage aliases to normalized keys
    final stageMap = {
      'new': 'lead_entered',
      'leadentered': 'lead_entered',
      'created': 'lead_entered',
      'clienttype': 'client_type',
      'qualify': 'qualify',
      'qualified': 'qualify',
      'followup': 'follow_up',
      'infollowup': 'follow_up',
      'contacted': 'follow_up',
      'quoted': 'quotation',
      'quotation': 'quotation',
      'quote': 'quotation',
      'proposal': 'quotation',
      'negotiation': 'negotiation',
      'negotiating': 'negotiation',
      'won': 'won',
      'lost': 'lost',
      'closedwon': 'won',
      'closedlost': 'lost',
      'wonlost': 'won',
    };
    
    final mappedStage = stageMap[normalized] ?? 'lead_entered';
    return _stageActions[mappedStage] ?? ['edit'];
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await action();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  void _openFollowUp(String leadId, SalesLead lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowUpScreen(
          leadId: leadId,
          leadName: _leadDisplayName(lead),
        ),
      ),
    );
  }

  void _openEdit(String leadId) {
    Navigator.pushNamed(context, '/crm/leads/form', arguments: leadId);
  }

  Future<void> _markLost(String leadId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close as lost'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why was this lead lost?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Mark lost'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;

    await _runAction(() async {
      await ref.read(salesWorkspaceProvider.notifier).markLost(leadId, reason);
      _snack('Lead marked as lost');
    });
  }

  Future<void> _qualify(String leadId, SalesLead lead) async {
    String temperature = lead.temperature ?? 'Warm';
    final reqController = TextEditingController(text: lead.requirements);
    final valueController = TextEditingController(
      text: lead.value > 0 ? lead.value.toStringAsFixed(0) : '',
    );
    const temps = ['Hot', 'Warm', 'Cold', 'Later'];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Qualify lead',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: temps.contains(temperature) ? temperature : 'Warm',
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      border: OutlineInputBorder(),
                    ),
                    items: temps
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setSheet(() => temperature = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reqController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Requirements',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Value (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Qualify'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    final payload = <String, dynamic>{
      'temperature': temperature,
      'requirements': reqController.text.trim(),
      'value': double.tryParse(valueController.text) ?? lead.value,
    };
    reqController.dispose();
    valueController.dispose();
    if (confirmed != true) return;

    await _runAction(() async {
      await ref.read(salesWorkspaceProvider.notifier).qualifyLead(leadId, payload);
      _snack('Lead qualified');
    });
  }

  Future<void> _assign(String leadId) async {
    final selected = await showModalBottomSheet<CrmTeamMember>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final async = sheetRef.watch(crmTeamProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Assign to rep',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.45,
                      child: async.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        data: (members) {
                          if (members.isEmpty) {
                            return const Center(
                              child: Text('No team members found.'),
                            );
                          }
                          return ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final m = members[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.12),
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(m.name),
                                subtitle: m.email != null
                                    ? Text(m.email!)
                                    : null,
                                onTap: () => Navigator.pop(ctx, m),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;

    await _runAction(() async {
      await ref.read(salesWorkspaceProvider.notifier).updateLead(leadId, {
        'ownerId': selected.id,
        'ownerName': selected.name,
      });
      _snack('Assigned to ${selected.name}');
    });
  }

  Future<void> _markWonOrRequest(String leadId, SalesLead lead) async {
    if (lead.hasPendingWonApproval) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pending approval'),
          content: const Text(
            'This lead already has a pending won approval request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open approvals'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        Navigator.pushNamed(context, '/crm/approvals');
      }
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as won'),
        content: const Text(
          'Mark this lead won now, or request approval first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'request'),
            child: const Text('Request approval'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'won'),
            child: const Text('Mark won'),
          ),
        ],
      ),
    );
    if (choice == null) return;

    await _runAction(() async {
      final notifier = ref.read(salesWorkspaceProvider.notifier);
      if (choice == 'request') {
        await notifier.requestWonApproval(leadId);
        _snack('Won approval requested');
      } else {
        try {
          await notifier.markWon(leadId);
          _snack('Lead marked as won');
        } catch (e) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (!mounted) rethrow;
          final request = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Could not mark won'),
              content: Text('$msg\n\nRequest won approval instead?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Request approval'),
                ),
              ],
            ),
          );
          if (request == true) {
            await notifier.requestWonApproval(leadId);
            _snack('Won approval requested');
          } else {
            rethrow;
          }
        }
      }
    });
  }

  Future<void> _convertCustomer(String leadId, SalesLead lead) async {
    if (lead.customerId != null && lead.customerId!.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Already linked'),
          content: Text('This lead is linked to customer ${lead.customerId}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View customer'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        Navigator.pushNamed(
          context,
          '/crm/customers/detail',
          arguments: lead.customerId,
        );
      }
      return;
    }

    await _runAction(() async {
      final result =
          await ref.read(salesWorkspaceProvider.notifier).ensureCustomer(leadId);
      final id = result.customerId;
      final created = result.created;
      if (id == null || id.isEmpty) {
        _snack('Customer linked, but no id returned');
        return;
      }
      _snack(created ? 'Customer created: $id' : 'Customer linked: $id');
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Customer ready'),
          content: Text(
            created
                ? 'Created customer $id from this lead.'
                : 'Matched existing customer $id.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View customer'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        Navigator.pushNamed(context, '/crm/customers/detail', arguments: id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leadId = ModalRoute.of(context)?.settings.arguments as String?;
    final lead = leadId == null ? null : ref.watch(crmLeadByIdProvider(leadId));
    final ws = ref.watch(salesWorkspaceProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          if (lead != null && leadId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.text),
              enabled: !_actionBusy,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _openEdit(leadId);
                    break;
                  case 'qualify':
                    _qualify(leadId, lead);
                    break;
                  case 'won':
                    _markWonOrRequest(leadId, lead);
                    break;
                  case 'convert':
                    _convertCustomer(leadId, lead);
                    break;
                  case 'assign':
                    _assign(leadId);
                    break;
                  case 'lost':
                    _markLost(leadId);
                    break;
                }
              },
              itemBuilder: (ctx) {
                final allowedActions = _getAllowedActions(lead);
                final items = <PopupMenuItem<String>>[];
                
                // Always show Edit if allowed
                if (allowedActions.contains('edit')) {
                  items.add(
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit lead'),
                    ),
                  );
                }

                // Show Qualify if allowed and not closed
                if (allowedActions.contains('qualify') && !_isClosed(lead)) {
                  items.add(
                    const PopupMenuItem(
                      value: 'qualify',
                      child: Text('Qualify'),
                    ),
                  );
                }

                // Show Won/Approval if not closed and in follow-up or later stages
                if (!_isClosed(lead) && 
                    (allowedActions.contains('log_followup') || 
                     allowedActions.contains('create_quotation'))) {
                  items.add(
                    PopupMenuItem(
                      value: 'won',
                      child: Text(
                        lead.hasPendingWonApproval
                            ? 'Won approval status'
                            : 'Mark won / request approval',
                      ),
                    ),
                  );
                }

                // Show Convert/View Customer if allowed or if has customerId
                if (allowedActions.contains('view_customer') || 
                    (lead.customerId != null && lead.customerId!.isNotEmpty)) {
                  items.add(
                    PopupMenuItem(
                      value: 'convert',
                      child: Text(
                        lead.customerId != null && lead.customerId!.isNotEmpty
                            ? 'View linked customer'
                            : 'Convert to customer',
                      ),
                    ),
                  );
                }

                // Show Assign if allowed
                if (allowedActions.contains('assign')) {
                  items.add(
                    const PopupMenuItem(
                      value: 'assign',
                      child: Text('Assign to rep'),
                    ),
                  );
                }

                // Show Lost if allowed
                if (allowedActions.contains('lost')) {
                  items.add(
                    const PopupMenuItem(
                      value: 'lost',
                      child: Text('Close as lost'),
                    ),
                  );
                }

                return items;
              },
            ),
        ],
      ),
      body: ws.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lead == null
              ? Center(
                  child: Text(
                    leadId == null
                        ? 'Pass leadId via Navigator arguments.'
                        : 'Lead not found: $leadId',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : SafeArea(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(
                              title: lead.companyName.isNotEmpty
                                  ? lead.companyName
                                  : (lead.contactName.isNotEmpty ? lead.contactName : 'Testing Lead'),
                              leadId: leadId ?? 'N/A',
                            ),
                            const SizedBox(height: 16),
                            _buildTabBar(),
                            const SizedBox(height: 20),
                            if (_selectedTabIndex == 0) ...[
                              _buildSectionHeader('LIFECYCLE'),
                              const SizedBox(height: 10),
                              _buildLifecycleStepper(lead.lifecycleStage ?? ''),
                              const SizedBox(height: 24),
                              _buildSectionHeader('LEAD INFORMATION'),
                              const SizedBox(height: 10),
                              _buildSnapshotCard(
                                lead.clientType,
                                lead.lifecycleStage ?? '',
                                lead.status,
                                lead.repeatFrequency,
                              ),
                              const SizedBox(height: 16),
                              _buildContactCard(lead),
                              const SizedBox(height: 16),
                              _buildLeadDetailsCard(lead),
                              const SizedBox(height: 24),
                              _buildSectionHeader('NEXT STEPS'),
                              const SizedBox(height: 12),
                              _buildNextStepsActions(leadId!, lead),
                            ] else ...[
                              _buildTimelineList(lead),
                            ],
                          ],
                        ),
                      ),
                      if (_actionBusy)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x33000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard({required String title, required String leadId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  leadId,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _selectedTabIndex == 0 ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _selectedTabIndex == 1 ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 0.8,
      ),
    );
  }

  static const Map<String, String> _stageAliasMap = {
    'new': 'Lead entered',
    'leadentered': 'Lead entered',
    'created': 'Lead entered',
    'clienttype': 'Client type',
    'qualify': 'Qualify',
    'qualified': 'Qualify',
    'followup': 'Follow-up',
    'infollowup': 'Follow-up',
    'contacted': 'Follow-up',
    'quoted': 'Quotation',
    'quotation': 'Quotation',
    'quote': 'Quotation',
    'proposal': 'Quotation',
    'negotiation': 'Negotiation',
    'negotiating': 'Negotiation',
    'won': 'Won / Lost',
    'lost': 'Won / Lost',
    'closedwon': 'Won / Lost',
    'closedlost': 'Won / Lost',
    'wonlost': 'Won / Lost',
  };

  Widget _buildLifecycleStepper(String currentStage) {
    final stages = [
      'Lead entered',
      'Client type',
      'Qualify',
      'Follow-up',
      'Quotation',
      'Negotiation',
      'Won / Lost',
    ];

    final normalizedCurrent = _normalizeStage(currentStage);
    final mappedStage = _stageAliasMap[normalizedCurrent];
    final currentIndex = mappedStage != null
        ? stages.indexOf(mappedStage)
        : stages.indexWhere((s) => _normalizeStage(s) == normalizedCurrent);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(stages.length * 2 - 1, (i) {
          if (i.isOdd) {
            final beforeIndex = i ~/ 2;
            final arrowPassed =
                currentIndex != -1 && beforeIndex < currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: arrowPassed ? AppColors.success : AppColors.border,
              ),
            );
          }

          final index = i ~/ 2;
          final stage = stages[index];
          final isSelected = index == currentIndex;
          final isPassed = currentIndex != -1 && index < currentIndex;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isPassed
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isPassed
                        ? AppColors.success
                        : AppColors.border,
              ),
            ),
            child: Text(
              stage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isPassed
                        ? AppColors.success
                        : AppColors.muted,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _timelineField(dynamic entry, String key) {
    try {
      if (entry is Map) {
        return (entry[key] ?? '').toString();
      }
      switch (key) {
        case 'at':
          return (entry.at ?? '').toString();
        case 'text':
          return (entry.text ?? '').toString();
        case 'type':
          return (entry.type ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  Widget _buildTimelineList(dynamic lead) {
    final List<dynamic> rawTimeline =
        (lead.timeline as List?)?.toList() ?? const [];

    if (rawTimeline.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No timeline activity yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final sorted = List<dynamic>.from(rawTimeline)
      ..sort((a, b) =>
          _timelineField(b, 'at').compareTo(_timelineField(a, 'at')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sorted.length, (index) {
        final entry = sorted[index];
        final isLast = index == sorted.length - 1;
        final text = _timelineField(entry, 'text');
        final at = _timelineField(entry, 'at');
        final type = _timelineField(entry, 'type').toUpperCase();

        return Stack(
          children: [
            if (!isLast)
              Positioned(
                top: 16,
                bottom: 0,
                left: 5,
                child: Container(
                  width: 2,
                  color: AppColors.border,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.isNotEmpty ? text : 'Activity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            at,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (type.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatSnapshotLabel(String value) {
    if (value.trim().isEmpty) return '';
    return value.replaceAll(RegExp(r'[_\-]+'), ' ').trim().toUpperCase();
  }

  Widget _buildSnapshotCard(
    String clientType,
    String lifecycleStage,
    String status,
    String repeatFrequency,
  ) {
    final pills = <String, bool>{};

    final clientTypeLabel = _formatSnapshotLabel(clientType);
    if (clientTypeLabel.isNotEmpty) pills[clientTypeLabel] = false;

    final lifecycleLabel = _formatSnapshotLabel(lifecycleStage);
    if (lifecycleLabel.isNotEmpty &&
        _normalizeStage(lifecycleLabel) != _normalizeStage(status)) {
      pills[lifecycleLabel] = false;
    }

    final statusLabel = _formatSnapshotLabel(status);
    if (statusLabel.isNotEmpty) pills[statusLabel] = true;

    final repeatLabel = _formatSnapshotLabel(repeatFrequency);
    if (repeatLabel.isNotEmpty) pills[repeatLabel] = false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SNAPSHOT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills.entries.map((pillEntry) {
              final pill = pillEntry.key;
              final isActive = pillEntry.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.accent : Colors.transparent,
                  ),
                ),
                child: Text(
                  pill,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.accent : AppColors.muted,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(dynamic lead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTACT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Owner', lead.ownerName.isNotEmpty ? lead.ownerName : 'Unassigned'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Phone', lead.phone.isNotEmpty ? lead.phone : 'N/A'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Email', lead.email.isNotEmpty ? lead.email : 'N/A'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Address', lead.address?.isNotEmpty == true ? lead.address : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildLeadDetailsCard(dynamic lead) {
    final rows = <MapEntry<String, String>>[];

    final double value = lead.value;
    if (value > 0) {
      rows.add(MapEntry('Value', '₹${value.toStringAsFixed(0)}'));
    }

    final int? score = lead.score;
    if (score != null) {
      rows.add(MapEntry('Score', score.toString()));
    }

    final String source = lead.source.toString();
    if (source.isNotEmpty) {
      rows.add(MapEntry('Source', source));
    }

    final String requirements = lead.requirements.toString();
    if (requirements.isNotEmpty) {
      rows.add(MapEntry('Requirements', requirements));
    }

    final String gstNumber = lead.gstNumber.toString();
    if (gstNumber.isNotEmpty) {
      rows.add(MapEntry('GST Number', gstNumber));
    }

    final String? quoteId = lead.quoteId;
    if (quoteId != null && quoteId.isNotEmpty) {
      rows.add(MapEntry('Quote', quoteId));
    }

    final String? nextFollowUpAt = lead.nextFollowUpAt;
    if (nextFollowUpAt != null && nextFollowUpAt.isNotEmpty) {
      rows.add(MapEntry('Next follow-up', nextFollowUpAt));
    }

    final String? lastFollowUpAt = lead.lastFollowUpAt;
    if (lastFollowUpAt != null && lastFollowUpAt.isNotEmpty) {
      rows.add(MapEntry('Last follow-up', lastFollowUpAt));
    }

    final String? lostReason = lead.lostReason;
    if (lostReason != null && lostReason.isNotEmpty) {
      rows.add(MapEntry('Lost reason', lostReason));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            _buildDetailRow(rows[i].key, rows[i].value),
            if (i != rows.length - 1)
              const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Updated Next Steps Actions with dynamic visibility based on screenshots
  Widget _buildNextStepsActions(String leadId, SalesLead lead) {
    final allowedActions = _getAllowedActions(lead);
    final closed = _isClosed(lead);
    final isWon = _isWon(lead);
    
    final List<Widget> buttonRows = [];
    
    // ============ Row 1: Start Follow-up & Log Follow-up ============
    final List<Widget> row1Buttons = [];
    
    // Start follow-up - only show if not closed and in early stages (lead entered, client type, qualify)
    if (allowedActions.contains('start_followup')) {
      row1Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy
                ? null
                : () {
                    Navigator.pushNamed(
                      context,
                      '/crm/activities',
                      arguments: leadId,
                    );
                  },
            child: const Text('Start follow-up', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    // Log follow-up - show from qualify stage onwards
    if (allowedActions.contains('log_followup') && !isWon) {
      row1Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _openFollowUp(leadId, lead),
            child: const Text('Log follow-up', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (row1Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row1Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 2: Create Quotation & Close as Lost ============
    final List<Widget> row2Buttons = [];
    
    // Create quotation - show from follow-up stage onwards (except won)
    if (allowedActions.contains('create_quotation') && !isWon) {
      row2Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy
                ? null
                : () => Navigator.pushNamed(
                      context,
                      '/crm/quotes/form',
                      arguments: leadId,
                    ),
            child: const Text('Create quotation', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    // Close as lost - show for all stages except won
    if (allowedActions.contains('lost') && !closed && !isWon) {
      row2Buttons.add(
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (_actionBusy) ? null : () => _markLost(leadId),
            child: const Text('Close as lost', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (row2Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row2Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 3: Quotation Actions (only in quotation stage) ============
    final List<Widget> row3Buttons = [];
    
    if (allowedActions.contains('edit_quotation')) {
      row3Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Edit quotation'),
            child: const Text('Edit quotation', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (allowedActions.contains('email_quote')) {
      row3Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Email quote to client'),
            child: const Text('Email quote', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (row3Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row3Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 4: Download Quote & Move Negotiation ============
    final List<Widget> row4Buttons = [];
    
    if (allowedActions.contains('download_quote')) {
      row4Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Download quote PDF'),
            child: const Text('Download quote', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (allowedActions.contains('move_negotiation')) {
      row4Buttons.add(
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Move to negotiation'),
            child: const Text('Move to negotiation', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
    
    if (row4Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row4Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 5: Close as Won (in quotation/negotiation) ============
    if (allowedActions.contains('move_negotiation')) {
      buttonRows.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _markWonOrRequest(leadId, lead),
            child: const Text('Close as won', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      );
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 6: Bill/Sales Order Actions (Won stage) ============
    final List<Widget> row6Buttons = [];
    
    if (allowedActions.contains('view_bill')) {
      row6Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('View bill'),
            child: const Text('View bill', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (allowedActions.contains('download_bill')) {
      row6Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Download bill PDF'),
            child: const Text('Download bill', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (row6Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row6Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 7: Email Bill & View Sales Order ============
    final List<Widget> row7Buttons = [];
    
    if (allowedActions.contains('email_bill')) {
      row7Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('Email bill to client'),
            child: const Text('Email bill', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (allowedActions.contains('view_sales_order')) {
      row7Buttons.add(
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _actionBusy ? null : () => _snack('View sales order'),
            child: const Text('Sales order', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    
    if (row7Buttons.isNotEmpty) {
      buttonRows.add(Row(children: row7Buttons));
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // ============ Row 8: Assign to rep ============
    if (allowedActions.contains('assign')) {
      buttonRows.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (_actionBusy) ? null : () => _assign(leadId),
            child: const Text('Assign to rep', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
      buttonRows.add(const SizedBox(height: 12));
    }
    
    // If no actions available, show a message
    if (buttonRows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No actions available for this stage',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    
    // Remove last SizedBox height
    if (buttonRows.last is SizedBox) {
      buttonRows.removeLast();
    }
    
    return Column(
      children: buttonRows,
    );
  }
}