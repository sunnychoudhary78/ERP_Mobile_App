import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/production_service_provider.dart';
import 'package:erp_app/features/production/presentation/screens/work_orders_screen.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';

const _brandPurple = Color(0xFF635BFF);
const _brandTeal = Color(0xFF00D2B8);
const _brandGreen = Color(0xFF00C853);
const _brandYellow = Color(0xFFFFC01D);
const _bgCard = Color(0xFFF8F9FA);
const _textDark = Color(0xFF1E2022);

class ProductionDashboardScreen extends ConsumerStatefulWidget {
  const ProductionDashboardScreen({super.key});

  @override
  ConsumerState<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState
    extends ConsumerState<ProductionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productionSummaryProvider.notifier).fetch();
    });
  }

  Future<void> _onRefresh() {
    return ref.read(productionSummaryProvider.notifier).fetch(force: true);
  }

  void _navigateToWorkOrders({String? status}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WorkOrdersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productionSummaryProvider);
    final s = state.summary;

    return PermissionGate(
      anyOf: AppPermissions.productionModule,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Production Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _textDark,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _textDark),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: state.isLoading && state.fetchedAt == null
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && state.fetchedAt == null
              ? _ErrorState(message: state.error!, onRetry: _onRefresh)
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Couldn't refresh — showing cached data.",
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Production Units Breakdown Section
                    _ProductionUnitsBreakdownCard(
                      s: s,
                      onTap: _navigateToWorkOrders,
                    ),
                    const SizedBox(height: 16),

                    // Production Overview (Clickable to navigate)
                    _ProductionOverviewGrid(s: s, onTap: _navigateToWorkOrders),
                    const SizedBox(height: 16),

                    // Production Stage Overview Section
                    _ProductionStageOverviewCard(
                      s: s,
                      onTap: _navigateToWorkOrders,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProductionUnitsBreakdownCard extends StatelessWidget {
  final ProductionSummary s;
  final VoidCallback onTap;

  const _ProductionUnitsBreakdownCard({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Units Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _DonutChart(
                  size: 120,
                  strokeWidth: 16,
                  values: [
                    s.inProduction.toDouble(),
                    s.completed.toDouble(),
                    s.shortage.toDouble(),
                    s.qcHold.toDouble(),
                  ],
                  colors: const [
                    _brandPurple,
                    _brandTeal,
                    _brandGreen,
                    _brandYellow,
                  ],
                  center: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Work\nOrders',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _breakdownLegendItem(
                        _brandPurple,
                        'In Process (${s.inProduction})',
                      ),
                      const SizedBox(height: 8),
                      _breakdownLegendItem(
                        _brandTeal,
                        'Completed (${s.completed})',
                      ),
                      const SizedBox(height: 8),
                      _breakdownLegendItem(
                        _brandGreen,
                        'Material Shortage (${s.shortage})',
                      ),
                      const SizedBox(height: 8),
                      _breakdownLegendItem(
                        _brandYellow,
                        'QC Hold (${s.qcHold})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductionOverviewGrid extends StatelessWidget {
  final ProductionSummary s;
  final VoidCallback onTap;

  const _ProductionOverviewGrid({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Production Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              // _OverviewKpiTile(
              //   title: 'ACTIVE ORDERS',
              //   value: '${s.inProduction}',
              //   icon: Icons.chat_bubble_outline_rounded,
              //   iconColor: _brandPurple,
              //   onTap: onTap,
              // ),
              // _OverviewKpiTile(
              //   title: 'PLANNED WORK ORDERS',
              //   value: '${s.plannedWorkOrders}',
              //   icon: Icons.assignment_outlined,
              //   iconColor: _brandPurple,
              //   onTap: onTap,
              // ),
              // _OverviewKpiTile(
              //   title: 'OPEN REQUISITIONS',
              //   value: 'N/A',
              //   icon: Icons.insert_drive_file_outlined,
              //   iconColor: _brandGreen,
              //   onTap: onTap,
              // ),
              // _OverviewKpiTile(
              //   title: 'AVERAGE CYCLE TIME',
              //   value: 'N/A',
              //   icon: Icons.access_time_rounded,
              //   iconColor: _brandPurple,
              //   onTap: onTap,
              // ),
              // _OverviewKpiTile(
              //   title: 'DELAYED WORK ORDERS',
              //   value: '${s.delayedOrders}',
              //   icon: Icons.calendar_today_outlined,
              //   iconColor: _brandGreen,
              //   onTap: onTap,
              // ),
              // _OverviewKpiTile(
              //   title: 'AVERAGE YIELD',
              //   value: '${s.avgYield}',
              //   icon: Icons.pie_chart_outline_rounded,
              //   iconColor: _brandGreen,
              //   onTap: onTap,
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewKpiTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _OverviewKpiTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionStageOverviewCard extends StatelessWidget {
  final ProductionSummary s;
  final VoidCallback onTap;

  const _ProductionStageOverviewCard({required this.s, required this.onTap});

  double get _efficiency {
    final total = s.released + s.inProduction + s.qcHold + s.completed;
    return total == 0 ? 0 : (s.completed / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Stage Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // _stageRow(_brandPurple, 'PLANNING', s.planning, 0.45),
                      _stageRow(_brandPurple, 'RELEASED', s.released, 0.85),
                      _stageRow(
                        _brandGreen,
                        'IN PRODUCTION',
                        s.inProduction,
                        0.60,
                      ),
                      _stageRow(_brandYellow, 'QC HOLD', s.qcHold, 0.20),
                      _stageRow(_brandGreen, 'COMPLETED', s.completed, 0.40),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text(
                        'PRODUCTION\nEFFICIENCY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: _efficiency / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${_efficiency.toInt()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageRow(Color color, String name, int count, double fillFactor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fillFactor,
                minHeight: 14,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$name ($count)',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final Widget? center;
  final double size;
  final double strokeWidth;

  const _DonutChart({
    required this.values,
    required this.colors,
    this.center,
    this.size = 120,
    this.strokeWidth = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              values: values,
              colors: colors,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05,
        math.max(sweep - 0.1, 0.01),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(message),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
