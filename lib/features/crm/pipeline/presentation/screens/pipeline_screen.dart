import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmPipelineProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Sales Pipeline',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (stages) {
          final pipelines = _groupIntoPipelines(stages);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Summary Stat Cards
                SliverToBoxAdapter(
                  child: _HeaderSummarySection(stages: stages),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'ACTIVE PIPELINES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),

                // Pipeline List Section
                if (pipelines.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No pipeline data found.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = pipelines[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: _PipelineCard(pipeline: item),
                      );
                    }, childCount: pipelines.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Safe accessor helper for model properties that may not exist on SalesLead
  static String? _getProp(dynamic obj, String propName) {
    try {
      if (obj is Map) {
        return obj[propName]?.toString();
      }
      switch (propName) {
        case 'industry':
          return (obj as dynamic).industry as String?;
        case 'type':
          return (obj as dynamic).type as String?;
        case 'stage':
          return (obj as dynamic).stage as String?;
        case 'status':
          return (obj as dynamic).status as String?;
        case 'assignedTo':
          return (obj as dynamic).assignedTo?.toString();
        case 'companyName':
          return (obj as dynamic).companyName as String?;
        case 'contactName':
          return (obj as dynamic).contactName as String?;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  // Groups stages by client/company or fallback pipeline item
  List<Map<String, dynamic>> _groupIntoPipelines(
    Map<String, List<dynamic>> stages,
  ) {
    final Map<String, List<dynamic>> grouped = {};
    for (var stageList in stages.values) {
      for (var lead in stageList) {
        final companyName = _getProp(lead, 'companyName');
        final contactName = _getProp(lead, 'contactName');
        final key = (companyName?.isNotEmpty == true)
            ? companyName!
            : (contactName ?? 'Unknown');
        grouped.putIfAbsent(key, () => []).add(lead);
      }
    }

    return grouped.entries.map((e) {
      final leads = e.value;
      final firstLead = leads.first;
      final totalValue = leads.fold<double>(0, (sum, l) => sum + _valueOf(l));
      final openDays = _calculateOpenDays(leads);
      final stalledCount = leads.where((l) => _isStalled(l)).length;

      final industry = _getProp(firstLead, 'industry') ?? 'Tech';
      final type = _getProp(firstLead, 'type') ?? 'Remote';

      return {
        'title': e.key,
        'subtitle': '$industry • $type • opened ${openDays}d ago',
        'leads': leads,
        'totalValue': totalValue,
        'stalledCount': stalledCount,
        'teamMembers': _extractTeam(leads),
      };
    }).toList();
  }

  static double _valueOf(dynamic lead) {
    try {
      return ((lead as dynamic).value as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static bool _isStalled(dynamic lead) {
    try {
      final raw =
          ((lead as dynamic).updatedAt ?? (lead as dynamic).lastFollowUpAt)
              ?.toString();
      if (raw == null) return false;
      final dt = DateTime.tryParse(raw);
      if (dt == null) return false;
      return DateTime.now().difference(dt.toLocal()).inDays >= 7;
    } catch (_) {
      return false;
    }
  }

  static int _calculateOpenDays(List<dynamic> leads) {
    try {
      final dates = leads
          .map(
            (l) =>
                DateTime.tryParse(((l as dynamic).createdAt ?? '').toString()),
          )
          .whereType<DateTime>();
      if (dates.isEmpty) return 1;
      final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      return DateTime.now().difference(earliest).inDays;
    } catch (_) {
      return 1;
    }
  }

  static List<String> _extractTeam(List<dynamic> leads) {
    final Set<String> members = {};
    for (var lead in leads) {
      final assigned = _getProp(lead, 'assignedTo');
      if (assigned != null && assigned.isNotEmpty) {
        members.add(assigned);
      }
    }
    return members.toList();
  }
}

// Top Horizontal Stat Summary
class _HeaderSummarySection extends StatelessWidget {
  const _HeaderSummarySection({required this.stages});

  final Map<String, List<dynamic>> stages;

  @override
  Widget build(BuildContext context) {
    final totalCount = stages.values.fold<int>(0, (a, b) => a + b.length);
    final wonCount =
        (stages['won']?.length ?? 0) + (stages['Won']?.length ?? 0);
    final pendingCount =
        (stages['quotation']?.length ?? 0) +
        (stages['quoted']?.length ?? 0) +
        (stages['Quoted']?.length ?? 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatBox(
            title: 'TOTAL VALUE',
            value: '$totalCount',
            subtitle: 'in pipeline',
            valueColor: AppColors.primary,
          ),
          _StatBox(
            title: 'FINAL STAGE',
            value: '$wonCount',
            subtitle: 'won',
            valueColor: AppColors.success,
          ),
          _StatBox(
            title: 'OFFERS OUT',
            value: '$pendingCount',
            subtitle: 'pending',
            valueColor: AppColors.text,
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// Main Pipeline Card item
class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.pipeline});

  final Map<String, dynamic> pipeline;

  @override
  Widget build(BuildContext context) {
    final leads = pipeline['leads'] as List<dynamic>;
    final stalledCount = pipeline['stalledCount'] as int;
    final double totalValue = pipeline['totalValue'] as double;
    final List<String> team = pipeline['teamMembers'] as List<String>;

    // Distribution breakdown across 4 visual dynamic stages
    final stageCounts = _calculateStageDistribution(leads);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pipeline['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pipeline['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (stalledCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$stalledCount stalled 7d+',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Wedge Pipeline Visualizer
          SizedBox(
            height: 40,
            width: double.infinity,
            child: CustomPaint(
              painter: _PipelineFunnelPainter(
                fillColor: AppColors.primary.withOpacity(0.12),
                lineColor: AppColors.primary.withOpacity(0.2),
                nodeColor: AppColors.primary,
                lastNodeColor: stageCounts[3] > 0
                    ? AppColors.success
                    : AppColors.muted.withOpacity(0.6),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic stage count labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              final isLast = i == 3 && stageCounts[3] > 0;
              return SizedBox(
                width: 32,
                child: Text(
                  '${stageCounts[i]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLast ? AppColors.success : AppColors.text,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamAvatarStack(members: team),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_formatCurrency(totalValue)} in pipeline',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _calculateStageDistribution(List<dynamic> leads) {
    int s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    for (var l in leads) {
      final st =
          (PipelineScreen._getProp(l, 'stage') ??
                  PipelineScreen._getProp(l, 'status') ??
                  '')
              .toLowerCase();
      if (st.contains('qualif')) {
        s1++;
      } else if (st.contains('follow') || st.contains('quot')) {
        s2++;
      } else if (st.contains('negot')) {
        s3++;
      } else if (st.contains('won')) {
        s4++;
      } else {
        s1++;
      }
    }
    return [s1, s2, s3, s4];
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '\$$buf';
  }
}

// Custom Painter for Funnel Graph
class _PipelineFunnelPainter extends CustomPainter {
  _PipelineFunnelPainter({
    required this.fillColor,
    required this.lineColor,
    required this.nodeColor,
    required this.lastNodeColor,
  });

  final Color fillColor;
  final Color lineColor;
  final Color nodeColor;
  final Color lastNodeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final topStart = size.height * 0.1;
    final topEnd = size.height * 0.45;
    final bottomStart = size.height * 0.9;
    final bottomEnd = size.height * 0.55;

    path.moveTo(0, topStart);
    path.lineTo(size.width, topEnd);
    path.lineTo(size.width, bottomEnd);
    path.lineTo(0, bottomStart);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawLine(Offset(0, topStart), Offset(size.width, topEnd), linePaint);
    canvas.drawLine(
      Offset(0, bottomStart),
      Offset(size.width, bottomEnd),
      linePaint,
    );

    // Node Dots
    final double step = size.width / 3;
    for (int i = 0; i < 4; i++) {
      final double x = step * i;
      final double progress = i / 3;
      final double y =
          (topStart +
              (topEnd - topStart) * progress +
              bottomStart +
              (bottomEnd - bottomStart) * progress) /
          2;

      final dotPaint = Paint()
        ..color = i == 3 ? lastNodeColor : nodeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Stacked Avatar Widget
class _TeamAvatarStack extends StatelessWidget {
  const _TeamAvatarStack({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'Unassigned',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      );
    }

    final visible = members.take(3).toList();
    final remaining = members.length - visible.length;

    return Row(
      children: [
        SizedBox(
          height: 28,
          width: visible.length * 20.0 + (remaining > 0 ? 24 : 8),
          child: Stack(
            children: [
              for (int i = 0; i < visible.length; i++)
                Positioned(
                  left: i * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surface,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.accent.withOpacity(0.2),
                      child: Text(
                        visible[i][0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (remaining > 0)
                Positioned(
                  left: visible.length * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surface,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.border,
                      child: Text(
                        '+$remaining',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'team member${members.length > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}
