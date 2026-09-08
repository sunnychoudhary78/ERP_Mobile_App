import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trackingDashboardProvider = Provider<TrackingDashboardData>((ref) {
  return TrackingDashboardData(
    title: 'Tracking Dashboard',
    shipmentValues: const [24, 28, 12, 5],
    shipmentLegend: const [
      LegendEntryData('In Transit', '24', TrackingDashboardScreen.purple),
      LegendEntryData('Delivered', '68', TrackingDashboardScreen.teal),
      LegendEntryData('Out for Delivery', '12', TrackingDashboardScreen.green),
      LegendEntryData('Delayed', '5', TrackingDashboardScreen.red),
    ],
    trackingStats: const [
      TrackingStatData(
        'Total Shipments',
        '109',
        Icons.inventory_2_outlined,
        TrackingDashboardScreen.purple,
        Color(0xFFECE9FF),
        TrackingDashboardScreen.purple,
        [0.25, 0.20, 0.32, 0.20, 0.40, 0.26],
      ),
      TrackingStatData(
        'In Transit',
        '24',
        Icons.local_shipping_outlined,
        TrackingDashboardScreen.purple,
        Color(0xFFECE9FF),
        TrackingDashboardScreen.purple,
        [0.20, 0.18, 0.38, 0.20, 0.42, 0.34],
      ),
      TrackingStatData(
        'Delivered',
        '68',
        Icons.check_circle_outline_rounded,
        TrackingDashboardScreen.teal,
        Color(0xFFE3F6F5),
        TrackingDashboardScreen.teal,
        [0.22, 0.20, 0.45, 0.18, 0.48, 0.30],
      ),
      TrackingStatData(
        'Pending',
        '12',
        Icons.access_time_rounded,
        TrackingDashboardScreen.orange,
        Color(0xFFFFF1E0),
        TrackingDashboardScreen.orange,
        [0.30, 0.20, 0.16, 0.42, 0.28, 0.48],
      ),
      TrackingStatData(
        'Delayed',
        '5',
        Icons.warning_amber_rounded,
        TrackingDashboardScreen.red,
        Color(0xFFFFE8EB),
        TrackingDashboardScreen.red,
        [0.20, 0.12, 0.42, 0.50, 0.28, 0.45],
      ),
      TrackingStatData(
        'Returns',
        '3',
        Icons.keyboard_return_rounded,
        TrackingDashboardScreen.blue,
        Color(0xFFE7F0FF),
        TrackingDashboardScreen.blue,
        [0.18, 0.15, 0.40, 0.22, 0.35, 0.25],
      ),
    ],
    statuses: const [
      StatusData('Booked', 18, TrackingDashboardScreen.purple),
      StatusData('Picked Up', 22, TrackingDashboardScreen.blue),
      StatusData('In Transit', 24, TrackingDashboardScreen.teal),
      StatusData('Out for Delivery', 12, TrackingDashboardScreen.green),
      StatusData('Delivered', 68, TrackingDashboardScreen.teal),
    ],
    recentTracking: const [
      RecentTrackingItemData(
        'TRK-10248',
        'Delhi, India  →  Mumbai, India',
        'Today, 10:24 AM',
        'In Transit',
        TrackingDashboardScreen.purple,
      ),
      RecentTrackingItemData(
        'TRK-10247',
        'Pune, India  →  Bangalore, India',
        'Today, 09:10 AM',
        'Delivered',
        TrackingDashboardScreen.green,
      ),
      RecentTrackingItemData(
        'TRK-10246',
        'Ahmedabad, India  →  Surat, India',
        'Yesterday, 06:45 PM',
        'Delayed',
        TrackingDashboardScreen.red,
      ),
    ],
  );
});

@immutable
class TrackingDashboardData {
  const TrackingDashboardData({
    required this.title,
    required this.shipmentValues,
    required this.shipmentLegend,
    required this.trackingStats,
    required this.statuses,
    required this.recentTracking,
  });

  final String title;
  final List<double> shipmentValues;
  final List<LegendEntryData> shipmentLegend;
  final List<TrackingStatData> trackingStats;
  final List<StatusData> statuses;
  final List<RecentTrackingItemData> recentTracking;
}

class LegendEntryData {
  const LegendEntryData(this.title, this.value, this.color);

  final String title;
  final String value;
  final Color color;
}

class TrackingStatData {
  const TrackingStatData(
    this.title,
    this.value,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.lineColor,
    this.points,
  );

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color lineColor;
  final List<double> points;
}

class RecentTrackingItemData {
  const RecentTrackingItemData(
    this.trackingId,
    this.route,
    this.time,
    this.status,
    this.statusColor,
  );

  final String trackingId;
  final String route;
  final String time;
  final String status;
  final Color statusColor;
}

class TrackingDashboardScreen extends ConsumerWidget {
  const TrackingDashboardScreen({super.key});

  // ================= COLORS =================

  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF7B8490);

  static const Color purple = Color(0xFF5B4DB7);
  static const Color blue = Color(0xFF3867C8);
  static const Color teal = Color(0xFF22A6A6);
  static const Color green = Color(0xFF25A65A);
  static const Color orange = Color(0xFFFF8A00);
  static const Color red = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(trackingDashboardProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, dashboard.title),

              const SizedBox(height: 28),

              _buildShipmentOverview(dashboard),

              const SizedBox(height: 28),

              _sectionTitle('Tracking Overview'),

              const SizedBox(height: 18),

              _buildTrackingOverview(dashboard),

              const SizedBox(height: 24),

              _buildDeliveryPerformance(),

              const SizedBox(height: 24),

              _buildShipmentStatusOverview(dashboard),

              const SizedBox(height: 24),

              _buildRecentTracking(dashboard),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric( vertical: 18),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  // ================= SHIPMENT OVERVIEW =================

  Widget _buildShipmentOverview(TrackingDashboardData dashboard) {
    return _dashboardCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Shipment Overview'),

          const SizedBox(height: 24),

          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    values: dashboard.shipmentValues,
                    colors: dashboard.shipmentLegend
                        .map((entry) => entry.color)
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      int index = 0;
                      index < dashboard.shipmentLegend.length;
                      index++
                    ) ...[
                      _LegendItem(
                        color: dashboard.shipmentLegend[index].color,
                        title: dashboard.shipmentLegend[index].title,
                        value: dashboard.shipmentLegend[index].value,
                      ),
                      if (index != dashboard.shipmentLegend.length - 1)
                        const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TRACKING OVERVIEW =================

  Widget _buildTrackingOverview(TrackingDashboardData dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 1,
      children: dashboard.trackingStats
          .map(
            (stat) => _TrackingStatCard(
              title: stat.title,
              value: stat.value,
              icon: stat.icon,
              iconColor: stat.iconColor,
              iconBackground: stat.iconBackground,
              lineColor: stat.lineColor,
              points: stat.points,
            ),
          )
          .toList(),
    );
  }

  // ================= DELIVERY PERFORMANCE =================

  Widget _buildDeliveryPerformance() {
    return _dashboardCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('Delivery Performance'),
              const Spacer(),
              const Text(
                'Last 30 days',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(
                child: _performanceItem(
                  title: 'Delivered',
                  count: '68',
                  label: 'shipments',
                  color: green,
                  progress: 0.88,
                ),
              ),

              Container(width: 1, height: 100, color: const Color(0xFFE3E6EB)),

              const SizedBox(width: 28),

              Expanded(
                child: _performanceItem(
                  title: 'Delayed',
                  count: '5',
                  label: 'shipments',
                  color: red,
                  progress: 0.12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceItem({
    required String title,
    required String count,
    required String label,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: textPrimary),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE6E9EE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ================= SHIPMENT STATUS =================

  Widget _buildShipmentStatusOverview(TrackingDashboardData dashboard) {
    final statuses = dashboard.statuses;

    return _dashboardCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Shipment Status Overview'),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    for (final status in statuses) ...[
                      _statusBar(status),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 28),

              Expanded(
                flex: 5,
                child: Column(
                  children: statuses
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  status.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '${status.value}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              Container(width: 1, height: 190, color: const Color(0xFFE3E6EB)),

              const SizedBox(width: 20),

              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const Text(
                      'Delivery Success Rate',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: ProgressRingPainter(
                          progress: 0.94,
                          color: teal,
                        ),
                        child: const Center(
                          child: Text(
                            '94%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBar(StatusData status) {
    final widthFactor = switch (status.title) {
      'Booked' => 0.55,
      'Picked Up' => 0.72,
      'In Transit' => 0.82,
      'Out for Delivery' => 0.48,
      'Delivered' => 1.0,
      _ => 0.5,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 16,
          decoration: BoxDecoration(
            color: status.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ================= RECENT TRACKING =================

  Widget _buildRecentTracking(TrackingDashboardData dashboard) {
    return _dashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _sectionTitle('Recent Tracking'),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: purple,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          for (
            int index = 0;
            index < dashboard.recentTracking.length;
            index++
          ) ...[
            _recentTrackingItem(
              trackingId: dashboard.recentTracking[index].trackingId,
              route: dashboard.recentTracking[index].route,
              time: dashboard.recentTracking[index].time,
              status: dashboard.recentTracking[index].status,
              statusColor: dashboard.recentTracking[index].statusColor,
            ),
            if (index != dashboard.recentTracking.length - 1)
              const Divider(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _recentTrackingItem({
    required String trackingId,
    required String route,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 30),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trackingId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                route,
                style: const TextStyle(fontSize: 14, color: textSecondary),
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 5),

              Text(
                time,
                style: const TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  // ================= COMMON WIDGETS =================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  Widget _dashboardCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7E9EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// LEGEND ITEM
// ============================================================

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            '$title ($value)',
            style: const TextStyle(
              fontSize: 14,
              color: TrackingDashboardScreen.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TRACKING STAT CARD
// ============================================================

class _TrackingStatCard extends StatelessWidget {
  const _TrackingStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.lineColor,
    required this.points,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color lineColor;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: TrackingDashboardScreen.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TrackingDashboardScreen.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: SparkLinePainter(points: points, color: lineColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA MODEL
// ============================================================

class StatusData {
  const StatusData(this.title, this.value, this.color);

  final String title;
  final int value;
  final Color color;
}

// ============================================================
// DONUT CHART PAINTER
// ============================================================

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.reduce((a, b) => a + b);

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 12;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;

      paint.color = colors[i];

      canvas.drawArc(rect, startAngle, sweepAngle - 0.03, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// PROGRESS RING PAINTER
// ============================================================

class ProgressRingPainter extends CustomPainter {
  ProgressRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 10;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE7EAEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// SPARK LINE PAINTER
// ============================================================

class SparkLinePainter extends CustomPainter {
  SparkLinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path();

    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
