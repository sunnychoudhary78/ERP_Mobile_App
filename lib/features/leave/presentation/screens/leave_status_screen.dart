import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leave_status_provider.dart';

class LeaveStatusScreen extends ConsumerStatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  ConsumerState<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends ConsumerState<LeaveStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSort = 'Newest First';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaveStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Leave',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Track and manage your leave requests',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_outlined,
                color: Color(0xFF3B5284),
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment
                .centerLeft, // Changed from Alignment.centerRight to centerLeft
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment
                  .start, // Keeps tabs aligned strictly to the start/left
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All Requests'),
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString().replaceFirst('Exception: ', '')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(leaveStatusProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          // Dynamic Stats Counts
          final total = requests.length;
          final pending = requests
              .where((r) => _matchesStatus(r, 'pending'))
              .length;
          final approved = requests
              .where((r) => _matchesStatus(r, 'approved'))
              .length;
          final rejected = requests
              .where((r) => _matchesStatus(r, 'rejected'))
              .length;

          // Filter list based on selected Tab index
          final filteredRequests = requests.where((r) {
            switch (_tabController.index) {
              case 1:
                return _matchesStatus(r, 'pending');
              case 2:
                return _matchesStatus(r, 'approved');
              case 3:
                return _matchesStatus(r, 'rejected');
              case 4:
                return _matchesStatus(r, 'cancelled');
              default:
                return true;
            }
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(leaveStatusProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Metrics Dashboard
                _MetricsOverviewCard(
                  total: total,
                  pending: pending,
                  approved: approved,
                  rejected: rejected,
                ),
                const SizedBox(height: 20),

                // List Header + Sort Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leave Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedSort,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B5284),
                      ),
                      items: ['Newest First', 'Oldest First']
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSort = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Request List Cards
                if (filteredRequests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No leave requests found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...filteredRequests.map(
                    (r) => _LeaveRequestCard(
                      request: r,
                      onTap: () {
                        // TODO: Navigate using leaveDetailsProvider(r.id)
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesStatus(dynamic r, String status) {
    return (r.status ?? '').toString().toLowerCase() == status;
  }
}

// -----------------------------------------------------------------------------
// Top Summary Metrics
// -----------------------------------------------------------------------------
class _MetricsOverviewCard extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _MetricsOverviewCard({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMetricItem(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF2F60FF),
            count: total,
            label: 'Total',
          ),
          _divider(),
          _buildMetricItem(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFE67E22),
            count: pending,
            label: 'Pending',
          ),
          _divider(),
          _buildMetricItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF27AE60),
            count: approved,
            label: 'Approved',
          ),
          _divider(),
          _buildMetricItem(
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFE74C3C),
            count: rejected,
            label: 'Rejected',
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(height: 36, width: 1, color: Colors.grey.shade200);

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Individual Leave Card
// -----------------------------------------------------------------------------
class _LeaveRequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const _LeaveRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = (request.status ?? 'Pending').toString().toLowerCase();
    final style = _getStatusStyle(status);

    // Dynamic icon color based on leave title style
    final leaveType =
        (request.leaveType ?? request.reference ?? 'Leave Request').toString();
    final iconBg = _getIconBgColor(leaveType);
    final iconColor = _getIconColor(leaveType);

    final remarks = request.reason ?? request.remarks;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Leave Type Icon Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle Section: Name, Date, Duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leaveType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDates(request.startDate, request.endDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.days ?? '1'} ${request.days == 1 ? 'Day' : 'Days'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Section: Badge, Applied On, Chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: style.bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: style.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Applied on ${request.appliedDate ?? request.createdAt ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom Remarks Section (For Rejected/Cancelled/Custom states)
              if (remarks != null && remarks.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Remarks:  ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: remarks,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDates(String? start, String? end) {
    if (start == null) return '';
    if (end == null || start == end) return start;
    return '$start – $end';
  }

  _StatusStyle _getStatusStyle(String status) {
    switch (status) {
      case 'approved':
        return _StatusStyle(
          label: 'Approved',
          bgColor: const Color(0xFFE8F8EE),
          textColor: const Color(0xFF27AE60),
        );
      case 'pending':
        return _StatusStyle(
          label: 'Pending',
          bgColor: const Color(0xFFFEF5ED),
          textColor: const Color(0xFFE67E22),
        );
      case 'rejected':
        return _StatusStyle(
          label: 'Rejected',
          bgColor: const Color(0xFFFDE8E8),
          textColor: const Color(0xFFE74C3C),
        );
      case 'cancelled':
        return _StatusStyle(
          label: 'Cancelled',
          bgColor: const Color(0xFFF0F2F5),
          textColor: const Color(0xFF7F8C8D),
        );
      default:
        return _StatusStyle(
          label: status,
          bgColor: const Color(0xFFF0F2F5),
          textColor: Colors.black54,
        );
    }
  }

  Color _getIconBgColor(String name) {
    if (name.contains('Casual')) return const Color(0xFFEAF8F0);
    if (name.contains('Sick')) return const Color(0xFFFEF5ED);
    if (name.contains('Earned')) return const Color(0xFFF1F0FF);
    return const Color(0xFFEBF3FE);
  }

  Color _getIconColor(String name) {
    if (name.contains('Casual')) return const Color(0xFF27AE60);
    if (name.contains('Sick')) return const Color(0xFFE67E22);
    if (name.contains('Earned')) return const Color(0xFF7B61FF);
    return const Color(0xFF2F60FF);
  }
}

class _StatusStyle {
  final String label;
  final Color bgColor;
  final Color textColor;

  _StatusStyle({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}
