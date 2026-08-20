import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/hrms/data/model/hrms_model.dart';
import 'package:erp_app/features/hrms/presentation/provider/hrms_provider.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Optional: Use fl_chart or custom painters for the donut chart

import '../../../../core/theme/app_theme.dart';

class HrmsScreen extends ConsumerWidget {
  const HrmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(hrmsDashboardProvider);

    return PermissionGate(
      anyOf: AppPermissions.hrmsModule,
      child: Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'HRMS Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hrmsDashboardProvider);
          await ref.read(hrmsDashboardProvider.future);
        },
        child: dashboardAsync.when(
          loading: () => const _LoadingBody(),
          error: (err, _) => _ErrorBody(
            message: err.toString(),
            onRetry: () => ref.invalidate(hrmsDashboardProvider),
          ),
          data: (model) =>
              _DashboardBody(model: model, isLoading: authState.isLoading),
        ),
      ),
    ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: AppColors.muted,
        ),
        const SizedBox(height: 12),
        const Text(
          'Couldn\'t load dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final HrmsHomeModel model;
  final bool isLoading;

  const _DashboardBody({required this.model, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final canLeave = auth.canAny(AppPermissions.leaveSelf);
    final canPunch = auth.canAny(AppPermissions.punch);
    final canApprove = auth.canAny(AppPermissions.leaveApprovals);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QUICK ACTIONS HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6E7C87),
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Customize',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // QUICK ACTIONS HORIZONTAL LIST
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.calendar_today_rounded,
                    iconBgColor: const Color(0xFFE8F0FE),
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Apply Leave',
                    subtitle: 'Submit leave request',
                    onTap: () => Navigator.pushNamed(context, '/leave-apply'),
                  ),
                if (canPunch)
                  _buildQuickActionCard(
                    icon: Icons.access_time_filled_rounded,
                    iconBgColor: const Color(0xFFE6F4EA),
                    iconColor: const Color(0xFF10B981),
                    title: 'Mark Attendance',
                    subtitle: 'Punch in/out',
                    onTap: () async {
                      await Navigator.pushNamed(context, '/punch');
                      ref.invalidate(hrmsDashboardProvider);
                    },
                  ),
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    iconBgColor: const Color(0xFFFCE8E6),
                    iconColor: const Color(0xFFEF4444),
                    title: 'Leave Balance',
                    subtitle: 'Show your leave balance',
                    onTap: () {
                      Navigator.pushNamed(context, '/leave-balance');
                    },
                  ),
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.description_rounded,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'My Leave',
                    subtitle: 'Leave status',
                    onTap: () {
                      Navigator.pushNamed(context, '/leave-status');
                    },
                  ),
                if (canApprove)
                  _buildQuickActionCard(
                    icon: Icons.approval_rounded,
                    iconBgColor: const Color.fromARGB(255, 199, 241, 254),
                    iconColor: const Color.fromARGB(255, 11, 93, 245),
                    title: 'Approval',
                    subtitle: 'Approval Screen',
                    onTap: () {
                      Navigator.pushNamed(context, '/approvals');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // STAFF DISTRIBUTION CARD (Donut Chart) — department headcount
          if (model.admin != null &&
              model.admin!.departmentDistribution.isNotEmpty) ...[
            _buildContainerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            startDegreeOffset: 270,
                            sections: [
                              for (var i = 0;
                                  i < model.admin!.departmentDistribution.length;
                                  i++)
                                PieChartSectionData(
                                  color: _distributionColor(i),
                                  value: model
                                      .admin!
                                      .departmentDistribution[i]
                                      .count
                                      .toDouble(),
                                  radius: 18,
                                  showTitle: false,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0;
                                i < model.admin!.departmentDistribution.length;
                                i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i ==
                                          model.admin!.departmentDistribution
                                                  .length -
                                              1
                                      ? 0
                                      : 10,
                                ),
                                child: _LegendItem(
                                  color: _distributionColor(i),
                                  label:
                                      '${model.admin!.departmentDistribution[i].name} '
                                      '(${model.admin!.departmentDistribution[i].count})',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // HR METRICS OVERVIEW (2x2 Grid)
          if (model.admin != null) ...[
            _buildContainerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HR Metrics Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricItem(
                        title: 'Total Employees',
                        value: '${model.admin!.employeesCount}',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFE6F4EA),
                      ),
                      _buildMetricItem(
                        title: 'Present Today',
                        value: '${model.manager?.teamPresent ?? model.admin!.attendanceTodayCount}',
                        icon: Icons.check_circle_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFE6F4EA),
                      ),
                      _buildMetricItem(
                        title: 'Leave Requests',
                        value: '${model.pendingLeavesCount}',
                        icon: Icons.shopping_basket_rounded,
                        iconColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFCE8E6),
                      ),
                      _buildMetricItem(
                        title: 'Pending Claims',
                        value: '${model.admin!.pendingClaims}',
                        icon: Icons.insert_drive_file_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFE8F0FE),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // STAFF ATTENDANCE CARD
          if (model.manager != null) ...[
            Builder(builder: (context) {
              final teamTotal = model.manager!.teamTotal;
              final present = model.manager!.teamPresent;
              final absent = model.manager!.teamAbsent;
              final presentRatio = teamTotal == 0 ? 0.0 : present / teamTotal;
              final absentRatio = teamTotal == 0 ? 0.0 : absent / teamTotal;

              return _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'PRESENT: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$present staff',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: presentRatio,
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Color(0xFF10B981),
                                    child: Icon(
                                      Icons.people,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'ABSENT / ON LEAVE: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$absent staff',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: absentRatio,
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Color(0xFFEF4444),
                                    child: Icon(
                                      Icons.people_outline,
                                      size: 12,
                                      color: Colors.white,
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
              );
            }),
            const SizedBox(height: 20),
          ],

          // TODAY'S ACTIVITIES CARD
          if (model.admin != null && model.admin!.todaysActivities.isNotEmpty) ...[
            _buildContainerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/calendar'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View Calendar',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < model.admin!.todaysActivities.length; i++)
                    _buildActivityItem(
                      '${model.admin!.todaysActivities[i].title} '
                      '(${model.admin!.todaysActivities[i].time})',
                      isFirst: i == 0,
                      isLast: i == model.admin!.todaysActivities.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // Cycling color palette for the Staff Distribution donut/legend —
  // works for any number of departments the API returns.
  static const _distributionPalette = [
    Color(0xFF5B67F6),
    Color(0xFF00C49F),
    Color(0xFF10B981),
    Color(0xFFFBBF24),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];

  Color _distributionColor(int index) =>
      _distributionPalette[index % _distributionPalette.length];

  // Quick Action Component
  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // General White Card Wrapper
  Widget _buildContainerCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Metric Item for Grid
  Widget _buildMetricItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Activity Timeline Row Item
  Widget _buildActivityItem(
    String text, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: const Color(0xFFE5E7EB)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Legend Widget for Donut Chart
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}