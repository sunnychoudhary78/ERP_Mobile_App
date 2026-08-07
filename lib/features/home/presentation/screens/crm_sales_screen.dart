import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:erp_app/features/crm/shared/data/models/sales_lead_model.dart';
import 'package:erp_app/features/crm/shared/presentation/providers/sales_workspace_provider.dart';
import '../../../../core/theme/app_theme.dart';

// --- QUICK ACTIONS DATA MODEL & DYNAMIC PROVIDER ---
class QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String route;

  const QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.route,
  });
}

final quickActionsProvider = Provider<List<QuickActionItem>>((ref) {
  return const [
    QuickActionItem(
      title: 'View Lead',
      subtitle: 'Capture new leads',
      icon: Icons.person,
      iconColor: Color(0xFF7C3AED), // Purple
      backgroundColor: Color(0xFFF3E8FF),
      route: '/crm/leads',
    ),
    QuickActionItem(
      title: 'Add Deal',
      subtitle: 'Create new deal',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: Color(0xFF10B981), // Emerald Green
      backgroundColor: Color(0xFFD1FAE5),
      route: '/crm/leads/form',
    ),
    QuickActionItem(
      title: 'Follow-up',
      subtitle: 'Plan your follow-up',
      icon: Icons.calendar_month_rounded,
      iconColor: Color(0xFF2563EB), // Blue
      backgroundColor: Color(0xFFDBEAFE),
      route: '/crm/activities',
    ),
    QuickActionItem(
      title: 'View Contacts',
      subtitle: 'All your contacts',
      icon: Icons.people_alt_rounded,
      iconColor: Color(0xFFF97316), // Orange
      backgroundColor: Color(0xFFFFEDD5),
      route: '/crm/contacts',
    ),
    QuickActionItem(
      title: 'Pipeline Overview',
      subtitle: 'Pipeline stages & stats',
      icon: Icons.oil_barrel_outlined,
      iconColor: Color(0xFF0284C7), // Sky Blue
      backgroundColor: Color(0xFFE0F2FE),
      route: '/crm/pipeline',
    ),
    QuickActionItem(
      title: 'Approval Overview',
      subtitle: 'Pending approvals & stats',
      icon: Icons.approval_outlined,
      iconColor: Color(0xFF059669), // Mint Teal
      backgroundColor: Color(0xFFD1E7DD),
      route: '/crm/approvals',
    ),
    QuickActionItem(
      title: 'Visit Overview',
      subtitle: 'Scheduled visits & tracking',
      icon: Icons.location_on_outlined,
      iconColor: Color(0xFFDC2626), // Crimson Red
      backgroundColor: Color(0xFFFEE2E2),
      route: '/crm/visits',
    ),
    QuickActionItem(
      title: 'Tracking Overview',
      subtitle: 'Pending tracking & stats',
      icon: Icons.track_changes_outlined,
      iconColor: Color(0xFFD97706), // Amber Gold
      backgroundColor: Color(0xFFFEF3C7),
      route: '/crm/tracking',
    ),
  ];
});



// --- MAIN CRM SALES SCREEN ---
class CrmSalesScreen extends ConsumerStatefulWidget {
  const CrmSalesScreen({super.key});

  @override
  ConsumerState<CrmSalesScreen> createState() => _CrmSalesScreenState();
}

class _CrmSalesScreenState extends ConsumerState<CrmSalesScreen> {
 // int _currentNavIndex = 0;
  String _selectedPeriod = 'This Week';

  static String _formatInr(num value) {
    final v = value.toDouble();
    if (v.abs() >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
   // final workspaceAsync = ref.watch(salesWorkspaceProvider);
    final statsAsync = ref.watch(crmDashboardStatsProvider);
    final funnelAsync = ref.watch(crmPipelineFunnelProvider);
    final nextActionsAsync = ref.watch(crmNextActionsProvider);
    final chartsAsync = ref.watch(crmChartsDataProvider);
    final quickActions = ref.watch(quickActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'CRM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesWorkspaceProvider);
          ref.invalidate(crmDashboardStatsProvider);
          ref.invalidate(crmPipelineFunnelProvider);
          ref.invalidate(crmNextActionsProvider);
          ref.invalidate(crmChartsDataProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            SizedBox(height: 12),
            // Dynamic Quick Actions Section
            _buildSectionHeader(
              'QUICK ACTIONS',
              actionText: 'Customize',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            _QuickActionsGrid(actions: quickActions),
            const SizedBox(height: 24),

            // Key Stats Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KEY STATS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                DropdownButton<String>(
                  underline: const SizedBox(),
                  value: _selectedPeriod,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'This Week',
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPeriod = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _KeyStatsGrid(
              statsAsync: statsAsync,
              chartsAsync: chartsAsync,
              formatInr: _formatInr,
            ),
            const SizedBox(height: 24),

            // Dynamic Pipeline Overview
            const Text(
              'PIPELINE OVERVIEW',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _PipelineOverviewCard(
              funnelAsync: funnelAsync,
              chartsAsync: chartsAsync,
              formatInr: _formatInr,
            ),
            const SizedBox(height: 24),

            // Dynamic Activities Section
            _buildSectionHeader(
              'TODAY\'S ACTIVITIES',
              actionText: 'View Calendar',
              onAction: () => Navigator.pushNamed(context, '/crm/activities'),
            ),
            const SizedBox(height: 12),
            _TodayActivitiesCard(nextActionsAsync: nextActionsAsync),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required String actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        InkWell(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              // const SizedBox(width: 4),
              // Icon(
              //   actionText == 'Customize'
              //       ? Icons.tune_rounded
              //       : Icons.calendar_today_outlined,
              //   size: 14,
              //   color: AppColors.primary,
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- DYNAMIC QUICK ACTIONS GRID ---
class _QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;

  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = actions[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, item.route),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- DYNAMIC KEY STATS GRID ---
class _KeyStatsGrid extends StatelessWidget {
  final AsyncValue<CrmDashboardStats> statsAsync;
  final AsyncValue<CrmChartsData> chartsAsync;
  final String Function(num) formatInr;

  const _KeyStatsGrid({
    required this.statsAsync,
    required this.chartsAsync,
    required this.formatInr,
  });

  @override
  Widget build(BuildContext context) {
    // Agar koi bhi dataset loading state me hai to loading layout dikhayenge
    final isLoading = statsAsync.isLoading || chartsAsync.isLoading;
    final hasError = statsAsync.hasError || chartsAsync.hasError;

    if (isLoading) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: List.generate(4, (_) => const _StatCardLoadingSkeleton()),
      );
    }

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Failed to load stats data',
            style: TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      );
    }

    final stats = statsAsync.value ?? const CrmDashboardStats();
    final charts = chartsAsync.value;
    final wonCount = charts?.won ?? 0;
    final lostCount = charts?.lost ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _StatSparklineCard(
          title: 'Total Leads',
          value: '${stats.openLeads}',
          subText: 'Status: Open',
          chartColor: Colors.purple,
          spots: _generateDynamicSpots(stats.openLeads.toDouble()),
        ),
        _StatSparklineCard(
          title: 'Open Deals',
          value: '${stats.openDeals}',
          subText: 'In Pipeline',
          chartColor: Colors.teal,
          spots: _generateDynamicSpots(stats.openDeals.toDouble()),
        ),
        _StatSparklineCard(
          title: 'Won Deals',
          value: '$wonCount',
          subText: 'Lost: $lostCount',
          chartColor: Colors.blue,
          spots: _generateDynamicSpots(wonCount.toDouble()),
        ),
        _StatSparklineCard(
          title: 'Deal Value',
          value: formatInr(stats.pipelineValue),
          subText: 'Pipeline value',
          chartColor: Colors.orange,
          spots: _generateDynamicSpots(stats.pipelineValue.toDouble()),
        ),
      ],
    );
  }

  List<FlSpot> _generateDynamicSpots(double base) {
    if (base <= 0) return const [FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0)];
    return [
      FlSpot(0, base * 0.4),
      FlSpot(1, base * 0.7),
      FlSpot(2, base * 0.5),
      FlSpot(3, base * 0.9),
      FlSpot(4, base),
    ];
  }
}

// Loading Skeleton Placeholder Component
class _StatCardLoadingSkeleton extends StatelessWidget {
  const _StatCardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _StatSparklineCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final Color chartColor;
  final List<FlSpot> spots;

  const _StatSparklineCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.chartColor,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DYNAMIC PIPELINE OVERVIEW ---
class _PipelineOverviewCard extends StatelessWidget {
  final AsyncValue<List<CrmFunnelStage>> funnelAsync;
  final AsyncValue<CrmChartsData> chartsAsync;
  final String Function(num) formatInr;

  const _PipelineOverviewCard({
    required this.funnelAsync,
    required this.chartsAsync,
    required this.formatInr,
  });

  static const _stageColors = [
    Color(0xFF6366F1), // Indigo / Purple
    Color(0xFF2563EB), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final charts = chartsAsync.asData?.value;
    final winRate = charts?.winRate ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: funnelAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text(
          'Error loading pipeline data',
          style: TextStyle(color: AppColors.danger),
        ),
        data: (stages) {
          if (stages.isEmpty) {
            return const Center(
              child: Text(
                'No pipeline data available',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            );
          }

          // Fixed widths for clean, proportional triangle funnel matching the design
          const double maxWidth = 120.0;
          const double minWidth = 45.0;
          final int count = stages.length;
          final double step = count > 1 ? (maxWidth - minWidth) / count : 0;

          return Row(
            children: [
              // Smooth Rounded Triangle Funnel
              SizedBox(
                width: maxWidth,
                child: Column(
                  children: [
                    for (int i = 0; i < stages.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final currentTopWidth = maxWidth - (i * step);
                          final currentBottomWidth =
                              maxWidth - ((i + 1) * step);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2.0),
                            height: 24,
                            child: CustomPaint(
                              size: Size(maxWidth, 24),
                              painter: RoundedTrapezoidPainter(
                                color: _stageColors[i % _stageColors.length],
                                topWidth: currentTopWidth,
                                bottomWidth: currentBottomWidth,
                                isFirst: i == 0,
                                isLast: i == stages.length - 1,
                              ),
                              child: Center(
                                child: Text(
                                  '${stages[i].count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Dynamic Funnel Labels
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < stages.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _stageColors[i % _stageColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stages[i].label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${stages[i].count}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),
              const VerticalDivider(width: 1),
              const SizedBox(width: 12),

              // Conversion / Win Rate Donut
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Conversion Rate',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 20,
                            sections: [
                              PieChartSectionData(
                                value: winRate.clamp(0.0, 100.0),
                                color: AppColors.primary,
                                title: '',
                                radius: 7,
                              ),
                              PieChartSectionData(
                                value: (100.0 - winRate).clamp(0.0, 100.0),
                                color: const Color(0xFFE2E8F0),
                                title: '',
                                radius: 7,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${winRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom Painter for Rounded Corners on Trapezoid Stages
class RoundedTrapezoidPainter extends CustomPainter {
  final Color color;
  final double topWidth;
  final double bottomWidth;
  final bool isFirst;
  final bool isLast;

  RoundedTrapezoidPainter({
    required this.color,
    required this.topWidth,
    required this.bottomWidth,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double topLeft = (size.width - topWidth) / 2;
    final double topRight = topLeft + topWidth;
    final double bottomLeft = (size.width - bottomWidth) / 2;
    final double bottomRight = bottomLeft + bottomWidth;

    const double radius = 6.0;

    path.moveTo(topLeft + (isFirst ? radius : 2), 0);
    path.lineTo(topRight - (isFirst ? radius : 2), 0);

    if (isFirst) {
      path.quadraticBezierTo(topRight, 0, topRight - 2, radius);
    }

    path.lineTo(
      bottomRight + (isLast ? 2 : 0),
      size.height - (isLast ? radius : 0),
    );

    if (isLast) {
      path.quadraticBezierTo(
        bottomRight,
        size.height,
        bottomRight - radius,
        size.height,
      );
      path.lineTo(bottomLeft + radius, size.height);
      path.quadraticBezierTo(
        bottomLeft,
        size.height,
        bottomLeft - 2,
        size.height - radius,
      );
    } else {
      path.lineTo(bottomLeft, size.height);
    }

    path.lineTo(topLeft + (isFirst ? 2 : 0), isFirst ? radius : 0);

    if (isFirst) {
      path.quadraticBezierTo(topLeft, 0, topLeft + radius, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Funnel Visualization
class TrapezoidPainter extends CustomPainter {
  final Color color;
  final double topWidth;
  final double bottomWidth;

  TrapezoidPainter({
    required this.color,
    required this.topWidth,
    required this.bottomWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final topLeft = (size.width - topWidth) / 2;
    final topRight = topLeft + topWidth;
    final bottomLeft = (size.width - bottomWidth) / 2;
    final bottomRight = bottomLeft + bottomWidth;

    path.moveTo(topLeft, 0);
    path.lineTo(topRight, 0);
    path.lineTo(bottomRight, size.height);
    path.lineTo(bottomLeft, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- DYNAMIC TODAY'S ACTIVITIES ---
class _TodayActivitiesCard extends StatelessWidget {
  final AsyncValue<List<SalesLead>> nextActionsAsync;

  const _TodayActivitiesCard({required this.nextActionsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: nextActionsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text(
          'Error loading activities',
          style: TextStyle(color: AppColors.danger),
        ),
        data: (leads) {
          if (leads.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No activities scheduled today',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
            );
          }

          return Column(
            children: [
              for (int i = 0; i < leads.length; i++) ...[
                _DynamicActivityRow(lead: leads[i]),
                if (i != leads.length - 1) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 1,
                        height: 16,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DynamicActivityRow extends StatelessWidget {
  final SalesLead lead;

  const _DynamicActivityRow({required this.lead});

  @override
  Widget build(BuildContext context) {
    final title = lead.companyName.isNotEmpty
        ? lead.companyName
        : (lead.contactName.isNotEmpty
              ? lead.contactName
              : 'Lead Action #${lead.id}');

    final stage = lead.lifecycleStage ?? 'Follow-up';
    final status = lead.status.isNotEmpty ? lead.status : 'Open';

    Color color;
    IconData icon;

    switch (stage.toLowerCase()) {
      case 'meeting':
        color = Colors.green;
        icon = Icons.groups_rounded;
        break;
      case 'call':
        color = Colors.blue;
        icon = Icons.phone_in_talk_rounded;
        break;
      default:
        color = Colors.orange;
        icon = Icons.assignment_turned_in_rounded;
        break;
    }

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/crm/leads'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              stage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}
