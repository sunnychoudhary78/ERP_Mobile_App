import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/hrms/data/model/hrms_model.dart';
import 'package:erp_app/features/hrms/presentation/provider/hrms_provider.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';

class HrmsScreen extends ConsumerWidget {
  const HrmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (!authState.canAny(AppPermissions.hrmsDashboard)) {
      return PermissionGate(
        anyOf: AppPermissions.hrmsDashboard,
        child: const SizedBox.shrink(),
      );
    }

    final dashboardAsync = ref.watch(hrmsDashboardProvider);

    return PermissionGate(
      anyOf: AppPermissions.hrmsDashboard,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'HRMS Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          backgroundColor: const Color(0xFFF4F6F9),
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
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
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
          size: 48,
          color: AppColors.muted,
        ),
        const SizedBox(height: 12),
        const Text(
          'Couldn\'t load dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
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
    final isAdmin = model.admin != null;
    final isManagerOnly = model.manager != null && !isAdmin;
    final showPersonal = !isAdmin;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== QUICK ACTIONS ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 125,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.calendar_month_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    title: 'Apply Leave',
                    subtitle: 'Submit request',
                    onTap: () => Navigator.pushNamed(context, '/leave-apply'),
                  ),
                if (canPunch)
                  _buildQuickActionCard(
                    icon: Icons.fingerprint_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    title: 'Mark Attendance',
                    subtitle: 'Punch in/out',
                    onTap: () async {
                      await Navigator.pushNamed(context, '/punch');
                      ref.invalidate(hrmsDashboardProvider);
                    },
                  ),
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.donut_small_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    title: 'Leave Balance',
                    subtitle: 'View balance',
                    onTap: () {
                      Navigator.pushNamed(context, '/leave-balance');
                    },
                  ),
                if (canLeave)
                  _buildQuickActionCard(
                    icon: Icons.assignment_outlined,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                    ),
                    title: 'My Leave',
                    subtitle: 'Leave status',
                    onTap: () {
                      Navigator.pushNamed(context, '/leave-status');
                    },
                  ),
                if (canApprove)
                  _buildQuickActionCard(
                    icon: Icons.verified_user_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
                    ),
                    title: 'Approval',
                    subtitle: 'Manage requests',
                    onTap: () {
                      Navigator.pushNamed(context, '/approvals');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== ADMIN ORG STATS (stats.read) ====================
          if (isAdmin) ...[
            // 2x2 METRICS GRID
            Row(
              children: [
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Total Employees',
                    value: '${model.admin!.employeesCount}',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF3B82F6),
                    subtitle: 'Registered workforce',
                    changePercent: model.admin!.employeesChangePercent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Present Today',
                    value: '${model.admin!.attendanceTodayCount}',
                    icon: Icons.task_alt_rounded,
                    accentColor: const Color(0xFF10B981),
                    subtitle: 'Active checked-in',
                    changePercent: model.admin!.attendanceTodayChangePercent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Leave Requests',
                    value: '${model.pendingLeavesCount}',
                    icon: Icons.pending_actions_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    subtitle: 'Awaiting review',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Pending Claims',
                    value: '${model.admin!.pendingClaims}',
                    icon: Icons.receipt_long_rounded,
                    accentColor: const Color(0xFFEC4899),
                    subtitle: 'Reimbursements',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'On Leave Today',
                    value: '${model.admin!.onLeaveToday}',
                    icon: Icons.event_busy_rounded,
                    accentColor: const Color(0xFF6366F1),
                    subtitle: 'Out of office',
                    changePercent: model.admin!.onLeaveChangePercent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Open Positions',
                    value: '${model.admin!.openPositions}',
                    icon: Icons.work_outline_rounded,
                    accentColor: const Color(0xFF14B8A6),
                    subtitle: 'Currently hiring',
                    changePercent: model.admin!.openPositionsChangePercent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Payroll (This Month)',
                    value: model.admin!.payrollThisMonth,
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF0EA5E9),
                    subtitle: 'Total payout',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernMetricCard(
                    title: 'Performance',
                    value: model.admin!.performanceRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    subtitle: 'Avg. rating / 5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // STAFF DISTRIBUTION CARD (DONUT CHART)
            if (model.admin!.departmentDistribution.isNotEmpty) ...[
              _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Staff Distribution',
                      subtitle: 'Department-wise headcount distribution',
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
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              startDegreeOffset: 270,
                              sections: [
                                for (
                                  var i = 0;
                                  i <
                                      model
                                          .admin!
                                          .departmentDistribution
                                          .length;
                                  i++
                                )
                                  PieChartSectionData(
                                    color: _distributionColor(i),
                                    value: model
                                        .admin!
                                        .departmentDistribution[i]
                                        .count
                                        .toDouble(),
                                    radius: 16,
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
                              for (
                                var i = 0;
                                i < model.admin!.departmentDistribution.length;
                                i++
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        i ==
                                            model
                                                    .admin!
                                                    .departmentDistribution
                                                    .length -
                                                1
                                        ? 0
                                        : 8,
                                  ),
                                  child: _LegendItem(
                                    color: _distributionColor(i),
                                    label:
                                        '${model.admin!.departmentDistribution[i].name}',
                                    value:
                                        '${model.admin!.departmentDistribution[i].count}',
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

            // EMPLOYEE DISTRIBUTION CARD (PERMANENT / CONTRACT / INTERN)
            if (model.admin!.employeeDistribution.total > 0) ...[
              Builder(
                builder: (context) {
                  final dist = model.admin!.employeeDistribution;
                  final slices = <_LegendItem>[
                    _LegendItem(
                      color: const Color(0xFF3B82F6),
                      label: 'Permanent',
                      value: '${dist.permanent}',
                    ),
                    _LegendItem(
                      color: const Color(0xFFF59E0B),
                      label: 'Contract',
                      value: '${dist.contract}',
                    ),
                    _LegendItem(
                      color: const Color(0xFF8B5CF6),
                      label: 'Intern',
                      value: '${dist.intern}',
                    ),
                  ];
                  final values = [dist.permanent, dist.contract, dist.intern];
                  return _buildContainerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: 'Employee Distribution',
                          subtitle:
                              'Employment type breakdown (${dist.total} total)',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 34,
                                  startDegreeOffset: 270,
                                  sections: [
                                    for (var i = 0; i < values.length; i++)
                                      if (values[i] > 0)
                                        PieChartSectionData(
                                          color: slices[i].color,
                                          value: values[i].toDouble(),
                                          radius: 16,
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
                                  for (var i = 0; i < slices.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: i == slices.length - 1 ? 0 : 8,
                                      ),
                                      child: slices[i],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // DEPARTMENT-WISE ATTENDANCE CARD
            if (model.admin!.departmentAttendance.isNotEmpty) ...[
              _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Department-wise Attendance',
                      subtitle: "Today's attendance rate by department",
                    ),
                    const SizedBox(height: 18),
                    for (
                      var i = 0;
                      i < model.admin!.departmentAttendance.length;
                      i++
                    )
                      Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              i == model.admin!.departmentAttendance.length - 1
                              ? 0
                              : 14,
                        ),
                        child: _buildAttendanceBar(
                          label: model.admin!.departmentAttendance[i].name
                              .toUpperCase(),
                          count:
                              '${model.admin!.departmentAttendance[i].percent.toStringAsFixed(0)}%',
                          ratio:
                              (model.admin!.departmentAttendance[i].percent /
                                      100)
                                  .clamp(0.0, 1.0),
                          barColor: _distributionColor(i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Upcoming Leaves (admin org view — matches web Dashboard)
            if (model.admin!.upcomingLeaves.isNotEmpty) ...[
              _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Upcoming Leaves',
                      subtitle: 'Approved leave across the organization',
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < model.admin!.upcomingLeaves.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == model.admin!.upcomingLeaves.length - 1
                              ? 0
                              : 12,
                        ),
                        child: _buildApprovalItem(
                          model.admin!.upcomingLeaves[i],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],

          // ==================== MANAGER TEAM (team.dashboard, not admin) =====
          if (isManagerOnly) ...[
            Builder(
              builder: (context) {
                final teamTotal = model.manager!.teamTotal;
                final present = model.manager!.teamPresent;
                final absent = model.manager!.teamAbsent;
                final presentRatio = teamTotal == 0 ? 0.0 : present / teamTotal;
                final absentRatio = teamTotal == 0 ? 0.0 : absent / teamTotal;

                return _buildContainerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        title: 'Team Attendance',
                        subtitle:
                            'Live status of your direct reports ($teamTotal Total)',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttendanceBar(
                              label: 'PRESENT',
                              count: '$present staff',
                              ratio: presentRatio,
                              barColor: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAttendanceBar(
                              label: 'ABSENT / LEAVE',
                              count: '$absent staff',
                              ratio: absentRatio,
                              barColor: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // ==================== PENDING APPROVALS (leave.approve) ============
          if (canApprove &&
              model.manager != null &&
              model.manager!.upcomingLeaves.isNotEmpty) ...[
            _buildContainerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(
                        title: 'Pending Approvals',
                        subtitle: 'Leave requests from your team',
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/approvals'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < model.manager!.upcomingLeaves.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == model.manager!.upcomingLeaves.length - 1
                            ? 0
                            : 12,
                      ),
                      child: _buildApprovalItem(
                        model.manager!.upcomingLeaves[i],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ==================== PERSONAL (employee + manager, not admin) =====
          if (showPersonal) ...[
            if (canLeave && model.leaveBalances.isNotEmpty) ...[
              _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Leave Balance Overview',
                      subtitle: 'Current leave credits available',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 36,
                                  sections: [
                                    for (
                                      var i = 0;
                                      i < model.leaveBalances.length;
                                      i++
                                    )
                                      PieChartSectionData(
                                        color: _distributionColor(i),
                                        value: model.leaveBalances[i].available
                                            .toDouble(),
                                        radius: 14,
                                        showTitle: false,
                                      ),
                                  ],
                                ),
                              ),
                              const Text(
                                'Leave\nBalance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
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
                              for (
                                var i = 0;
                                i < model.leaveBalances.length;
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: _LegendItem(
                                    color: _distributionColor(i),
                                    label: model.leaveBalances[i].name,
                                    value:
                                        '${model.leaveBalances[i].available}',
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

            if (canLeave) ...[
              const Text(
                'MY LEAVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              _buildContainerCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${model.pendingLeavesCount} Pending Request${model.pendingLeavesCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Awaiting manager approval',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/leave-status'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (model.monthSummary != null) ...[
              _buildContainerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Attendance This Month',
                      subtitle:
                          '${model.monthSummary!.workingHours} logged hours',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            label: 'Payable',
                            value: '${model.monthSummary!.payableDays}',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            label: 'Working',
                            value: '${model.monthSummary!.workingDays}',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            label: 'Leaves',
                            value: '${model.monthSummary!.totalLeaves}',
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            label: 'Absent',
                            value: '${model.monthSummary!.absentDays}',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],

          // TODAY'S ACTIVITIES (admin org view)
          if (isAdmin && model.admin!.todaysActivities.isNotEmpty) ...[
            _buildContainerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(
                        title: 'Today\'s Activities',
                        subtitle: 'Scheduled events & timeline',
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/calendar'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                        child: const Text(
                          'View Calendar',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < model.admin!.todaysActivities.length; i++)
                    _buildActivityItem(
                      '${model.admin!.todaysActivities[i].title} (${model.admin!.todaysActivities[i].time})',
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

  static const _distributionPalette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF6366F1),
    Color(0xFFF97316),
  ];

  Color _distributionColor(int index) =>
      _distributionPalette[index % _distributionPalette.length];

  // SECTION HEADER COMPONENT
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // MODERN GRADIENT METRIC CARD
  Widget _buildModernMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
    double? changePercent,
  }) {
    final hasTrend = changePercent != null && changePercent != 0;
    final isPositive = (changePercent ?? 0) >= 0;
    final trendColor = !hasTrend
        ? accentColor.withOpacity(0.7)
        : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              if (hasTrend)
                Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 15,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${changePercent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              // else
              //   Icon(Icons.trending_flat_rounded, size: 16, color: trendColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // QUICK ACTION CARD WITH GRADIENT
  Widget _buildQuickActionCard({
    required IconData icon,
    required LinearGradient gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
                    gradient: gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceBar({
    required String label,
    required String count,
    required double ratio,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // PENDING APPROVAL ROW ITEM (manager/admin)
  Widget _buildApprovalItem(UpcomingLeave leave) {
    final statusColor = _statusColor(leave.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            leave.employeeName.isNotEmpty
                ? leave.employeeName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leave.employeeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${leave.leaveType} · ${leave.startDate} - ${leave.endDate}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            leave.status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
      case 'declined':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B); // pending / awaiting
    }
  }

  // SMALL 4-UP ATTENDANCE STAT
  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildContainerCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

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
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 26, color: const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
