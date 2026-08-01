import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';



class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  static const _stageOrder = ['Qualified', 'Proposal', 'Negotiation', 'Won'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmPipelineProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppColors.primary,
      //   foregroundColor: Colors.white,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //   ),
      //   onPressed: () => Navigator.pushNamed(context, '/crm/leads/new'),
      //   child: const Icon(Icons.add_rounded),
      // ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (stages) {
          final orderedKeys = [
            ..._stageOrder.where(stages.containsKey),
            ...stages.keys.where((k) => !_stageOrder.contains(k)),
          ];

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PipelineSummary(stages: stages),
                ),
                if (stages.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No pipeline data.')),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _KanbanBoard(
                      orderedKeys: orderedKeys,
                      stages: stages,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({required this.stages});

  final Map<String, List<dynamic>> stages;

  @override
  Widget build(BuildContext context) {
    //final totalLeads = stages.values.fold<int>(0, (a, b) => a + b.length);
    final totalValue = stages.values
        .expand((l) => l)
        .fold<double>(0, (sum, lead) => sum + _valueOf(lead));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _StatCard(
              label: 'Total Pipeline',
              value: _formatCurrency(totalValue),
              highlighted: true,
            ),
            const SizedBox(width: 12),
            ...stages.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _StatCard(
                  label: e.key,
                  value: '${e.value.length}',
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: highlighted ? null : Border.all(color: AppColors.border),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? Colors.white.withOpacity(0.75)
                      : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: highlighted ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.orderedKeys, required this.stages});

  final List<String> orderedKeys;
  final Map<String, List<dynamic>> stages;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: orderedKeys.map((key) {
          final leads = stages[key]!;
          final stageValue =
              leads.fold<double>(0, (sum, l) => sum + _valueOf(l));
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _StageColumn(
              title: key,
              leads: leads,
              stageValue: stageValue,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({
    required this.title,
    required this.leads,
    required this.stageValue,
  });

  final String title;
  final List<dynamic> leads;
  final double stageValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${title.toUpperCase()} (${leads.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  _formatCurrency(stageValue),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          ...leads.map((lead) => _LeadCard(lead: lead)),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final dynamic lead;

  @override
  Widget build(BuildContext context) {
    final title = (lead.companyName as String).isEmpty
        ? lead.contactName as String
        : lead.companyName as String;
    final status = lead.status as String;
    final badge = _statusBadge(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(
            context,
            '/crm/leads/detail',
            arguments: lead.id,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(_valueOf(lead)),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lead.contactName as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badge.fg,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _daysAgo(lead),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge {
  const _Badge(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

_Badge _statusBadge(String status) {
  switch (status.toLowerCase()) {
    case 'ready':
      return _Badge(AppColors.success.withOpacity(0.14), AppColors.success);
    case 'urgent':
      return _Badge(AppColors.danger.withOpacity(0.12), AppColors.danger);
    default:
      return _Badge(AppColors.muted.withOpacity(0.12), AppColors.muted);
  }
}

// --- helpers: adjust field names here if your SalesLead model differs ---

double _valueOf(dynamic lead) {
  try {
    return (lead.estimatedValue as num?)?.toDouble() ?? 0;
  } catch (_) {
    return 0;
  }
}

String _daysAgo(dynamic lead) {
  try {
    final DateTime? last = lead.lastActivity as DateTime?;
    if (last == null) return '—';
    final days = DateTime.now().difference(last).inDays;
    return days <= 0 ? 'Today' : '$days day${days == 1 ? '' : 's'}';
  } catch (_) {
    return '—';
  }
}

String _formatCurrency(double value) {
  if (value >= 100000) {
    return '₹${(value / 1000).toStringAsFixed(0)}K';
  }
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '₹$buf';
}