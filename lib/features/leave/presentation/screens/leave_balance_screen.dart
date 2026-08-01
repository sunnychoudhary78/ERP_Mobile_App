import 'dart:math' as math;
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/leave/presentation/screens/leave_apply_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/leave_balance_provider.dart';

class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaveBalanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Leave Management',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   Stack(
        //     alignment: Alignment.topRight,
        //     children: [
        //       IconButton(
        //         icon: const Icon(Icons.notifications_none_rounded,
        //             color: Color(0xFF1E293B), size: 26),
        //         onPressed: () {},
        //       ),
        //       Positioned(
        //         right: 12,
        //         top: 12,
        //         child: Container(
        //           width: 8,
        //           height: 8,
        //           decoration: const BoxDecoration(
        //             color: Colors.red,
        //             shape: BoxShape.circle,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(leaveBalanceProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (balances) {
          final total = balances.fold<double>(0, (s, b) => s + b.available);

          return RefreshIndicator(
            onRefresh: () => ref.read(leaveBalanceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                OverviewCard(balances: balances, total: total),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Leave Types'),
                const SizedBox(height: 12),
                if (balances.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No leave types found.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: balances.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, i) =>
                        _LeaveTypeCard(balance: balances[i], index: i),
                  ),
                const SizedBox(height: 24),
                // _SectionHeader(title: 'Upcoming Holidays', onViewAll: () {}),
                // const SizedBox(height: 12),
                // ..._sampleHolidays.map((h) => _HolidayTile(holiday: h)),
                // const SizedBox(height: 24),
                // _SectionHeader(title: 'Recent Leave Requests', onViewAll: () {}),
                // const SizedBox(height: 12),
                // ..._sampleRequests.map((r) => _LeaveRequestTile(request: r)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the leave application screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LeaveApplyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'Apply Leave',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Overview card (total + donut + legend) ----------

// Assuming AppColors and AppTheme are imported from your theme file
// import 'path/to/theme.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.balances,
    required this.total,
    this.onViewDetails,
  });

  final List<dynamic> balances;
  final double total;
  final VoidCallback? onViewDetails;

  /// Helper to derive consistent accent colors for legend/chart segments
  Color _getSegmentColor(String name, int index) {
    const palette = [
      Color(0xFF2563EB), // Blue
      Color(0xFFEF4444), // Red
      Color(0xFF10B981), // Green
      Color(0xFF8B5CF6), // Purple
      Color(0xFFF59E0B), // Amber
    ];
    return palette[index % palette.length];
  }

  String _abbreviate(String name, String fallbackId) {
    final text = name.isNotEmpty ? name : fallbackId;
    if (text.length <= 4) return text.toUpperCase();
    final words = text.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    return text.substring(0, math.min(3, text.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Header
          Text(
            'Leave Balance Overview',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),

          // Main Layout Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Total Count (Left)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Available',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total.toStringAsFixed(total % 1 == 0 ? 0 : 1),
                        style: GoogleFonts.dmSans(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Days',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // View Details Button Card
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewDetails ?? () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider Separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: VerticalDivider(
                    color: AppColors.border.withOpacity(0.5),
                    thickness: 1,
                    width: 1,
                  ),
                ),

                // 2. Donut Chart (Center)
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      balances: balances,
                      total: total,
                      getColor: _getSegmentColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toStringAsFixed(total % 1 == 0 ? 0 : 1),
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Total',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // 3. Legend List (Far Right)
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(balances.length, (i) {
                      final b = balances[i];
                      final String rawName = (b.name ?? '').toString();
                      final String typeId = (b.leaveTypeId ?? '').toString();
                      final name = rawName.isEmpty ? typeId : rawName;

                      final num avail = b.available ?? 0;
                      final double availDouble = avail.toDouble();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getSegmentColor(name, i),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _abbreviate(name, typeId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            Text(
                              availDouble.toStringAsFixed(
                                availDouble % 1 == 0 ? 0 : 1,
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.balances,
    required this.total,
    required this.getColor,
  });

  final List<dynamic> balances;
  final double total;
  final Color Function(String name, int index) getColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 10.0;

    if (total <= 0) {
      final paintBg = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        0,
        2 * math.pi,
        false,
        paintBg,
      );
      return;
    }

    double startAngle = -math.pi / 2;

    for (var i = 0; i < balances.length; i++) {
      final b = balances[i];
      final num rawValue = b.available ?? 0;
      final double value = rawValue.toDouble();
      if (value <= 0) continue;

      final sweep = (value / total) * 2 * math.pi;
      final String rawName = (b.name ?? '').toString();
      final String typeId = (b.leaveTypeId ?? '').toString();
      final name = rawName.isEmpty ? typeId : rawName;

      final paint = Paint()
        ..color = getColor(name, i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.balances != balances || oldDelegate.total != total;
}




// ---------- Leave type grid card ----------

class _LeaveTypeCard extends StatelessWidget {
  const _LeaveTypeCard({required this.balance, required this.index});

  final dynamic balance;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double available = balance.available;
    final String name =
        (balance.name as String).isEmpty ? balance.leaveTypeId : balance.name;
    final color = leaveTypeColor(name, index);
    final icon = leaveTypeIcon(name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                available.toStringAsFixed(available % 1 == 0 ? 0 : 1),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'days left',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              width: double.infinity,
              color: color.withOpacity(0.15),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.6, // Progress indicator balance fill preview
                child: Container(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Section header ----------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
      ],
    );
  }
}

// // ---------- Upcoming holidays ----------

// class _Holiday {
//   const _Holiday({
//     required this.day,
//     required this.month,
//     required this.title,
//     required this.dateLabel,
//     required this.tag,
//   });

//   final String day;
//   final String month;
//   final String title;
//   final String dateLabel;
//   final String tag;
// }

// const _sampleHolidays = [
//   _Holiday(
//     day: '15',
//     month: 'AUG',
//     title: 'Independence Day',
//     dateLabel: 'Friday, 15 August 2025',
//     tag: 'National Holiday',
//   ),
// ];

// class _HolidayTile extends StatelessWidget {
//   const _HolidayTile({required this.holiday});

//   final _Holiday holiday;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: const Color(0xFFEFF6FF),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   holiday.month,
//                   style: const TextStyle(
//                     fontSize: 9,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//                 Text(
//                   holiday.day,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2563EB),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   holiday.title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1E293B),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   holiday.dateLabel,
//                   style:
//                       const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFDCFCE7),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               holiday.tag,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF15803D),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ---------- Recent leave requests ----------

// enum _RequestStatus { approved, pending, rejected }

// class _LeaveRequest {
//   const _LeaveRequest({
//     required this.title,
//     required this.dateRange,
//     required this.status,
//   });

//   final String title;
//   final String dateRange;
//   final _RequestStatus status;
// }

// const _sampleRequests = [
//   _LeaveRequest(
//     title: '2 Days Casual Leave',
//     dateRange: '12 Aug 2025 – 13 Aug 2025',
//     status: _RequestStatus.approved,
//   ),
//   _LeaveRequest(
//     title: '1 Day Sick Leave',
//     dateRange: '5 Aug 2025',
//     status: _RequestStatus.pending,
//   ),
//   _LeaveRequest(
//     title: '3 Days Earned Leave',
//     dateRange: '28 Jul 2025 – 30 Jul 2025',
//     status: _RequestStatus.rejected,
//   ),
// ];

// class _LeaveRequestTile extends StatelessWidget {
//   const _LeaveRequestTile({required this.request});

//   final _LeaveRequest request;

//   @override
//   Widget build(BuildContext context) {
//     final statusColor = switch (request.status) {
//       _RequestStatus.approved => const Color(0xFF16A34A),
//       _RequestStatus.pending => const Color(0xFFD97706),
//       _RequestStatus.rejected => const Color(0xFFDC2626),
//     };
//     final statusBg = switch (request.status) {
//       _RequestStatus.approved => const Color(0xFFDCFCE7),
//       _RequestStatus.pending => const Color(0xFFFEF3C7),
//       _RequestStatus.rejected => const Color(0xFFFEE2E2),
//     };
//     final statusLabel = switch (request.status) {
//       _RequestStatus.approved => 'Approved',
//       _RequestStatus.pending => 'Pending',
//       _RequestStatus.rejected => 'Rejected',
//     };

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: statusBg,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(Icons.event_available_rounded,
//                 size: 20, color: statusColor),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   request.title,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1E293B),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   request.dateRange,
//                   style:
//                       const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: statusBg,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               statusLabel,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: statusColor,
//               ),
//             ),
//           ),
//           const SizedBox(width: 4),
//           const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
//         ],
//       ),
//     );
//   }
// }

// ---------- Color & Palette Helpers ----------

const _palette = [
  Color(0xFF2563EB), // Casual Leave - Vibrant Blue
  Color(0xFFEF4444), // Sick Leave - Coral Red
  Color(0xFF10B981), // Earned Leave - Emerald Green
  Color(0xFF8B5CF6), // Leave Without Pay - Soft Purple
  Color(0xFFF59E0B), // Amber / Fallback
];

Color leaveTypeColor(String name, int index) {
  final lower = name.toLowerCase();
  if (lower.contains('casual')) return _palette[0];
  if (lower.contains('sick')) return _palette[1];
  if (lower.contains('earned') || lower.contains('privilege')) {
    return _palette[2];
  }
  if (lower.contains('without pay') ||
      lower.contains('lwp') ||
      lower.contains('unpaid')) {
    return _palette[3];
  }
  return _palette[index % _palette.length];
}

IconData leaveTypeIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('casual')) return Icons.calendar_today_rounded;
  if (lower.contains('sick')) return Icons.favorite_rounded;
  if (lower.contains('earned') || lower.contains('privilege')) {
    return Icons.verified_user_rounded;
  }
  if (lower.contains('without pay') ||
      lower.contains('lwp') ||
      lower.contains('unpaid')) {
    return Icons.lock_outline_rounded;
  }
  return Icons.event_note_rounded;
}

String abbreviate(String name, String leaveTypeId) {
  if (leaveTypeId.isNotEmpty && leaveTypeId.length <= 4) {
    return leaveTypeId.toUpperCase();
  }
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final initials = words.map((w) => w[0]).take(3).join();
  return initials.isEmpty ? name.toUpperCase() : initials.toUpperCase();
}