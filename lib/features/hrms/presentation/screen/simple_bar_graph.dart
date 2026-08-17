import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single bar in [SimpleBarChart].
class ChartBar {
  final String label;
  final double value;
  final Color color;

  const ChartBar({required this.label, required this.value, required this.color});
}

/// Minimal grouped/simple bar chart — no external chart package needed.
/// Good for the 7-day attendance graphs and small breakdowns.
class SimpleBarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final double height;

  const SimpleBarChart({super.key, required this.bars, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(
      1,
      (max, b) => b.value > max ? b.value : max,
    );

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((b) {
          final barHeight = (b.value / maxValue) * (height - 28);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    b.value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: barHeight.clamp(3, height),
                    decoration: BoxDecoration(
                      color: b.color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.label,
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Stacked horizontal bar for a breakdown out of a total (e.g. month
/// summary: present / late / leave / absent).
class StackedBreakdownBar extends StatelessWidget {
  final List<ChartBar> segments;

  const StackedBreakdownBar({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    final safeTotal = total <= 0 ? 1.0 : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: segments.map((s) {
                final flex = ((s.value / safeTotal) * 1000).round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(color: s.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: segments.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '${s.label} (${s.value.toStringAsFixed(0)})',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// One ring segment in a [DonutChart].
class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

/// Reusable ring/donut chart with an optional widget centered inside it.
/// Used for "Attendance Overview" and "Employee Distribution".
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;
  final Color trackColor;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 168,
    this.strokeWidth = 20,
    this.centerWidget,
    this.trackColor = const Color(0xFFF1F1F1),
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
              segments: segments,
              strokeWidth: strokeWidth,
              trackColor: trackColor,
            ),
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color trackColor;

  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track so gaps between segments read cleanly.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}

/// One bar in [DepartmentAttendanceChart].
class DepartmentBar {
  final String label;
  final double percent; // 0-100

  const DepartmentBar({required this.label, required this.percent});
}

/// Vertical bar chart scaled 0-100%, used for "Department Wise Attendance".
class DepartmentAttendanceChart extends StatelessWidget {
  final List<DepartmentBar> bars;
  final double height;
  final Color color;

  const DepartmentAttendanceChart({
    super.key,
    required this.bars,
    this.height = 130,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((b) {
              final barHeight = (b.percent.clamp(0, 100) / 100) * height;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: barHeight.clamp(3, height),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: bars.map((b) {
            return Expanded(
              child: Text(
                b.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}