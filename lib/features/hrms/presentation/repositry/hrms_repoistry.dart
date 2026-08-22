import 'package:erp_app/features/hrms/data/hrms_api_services.dart';
import 'package:erp_app/features/hrms/data/model/hrms_model.dart';

class HrmsRepository {
  final HrmsApiService _api;

  HrmsRepository(this._api);

  Future<HrmsHomeModel> loadDashboard({
    required bool isManager,
    required bool isAdmin,
    bool canApproveLeaves = false,
  }) async {
    final today = DateTime.now();
    final month =
        '${today.year}-${today.month.toString().padLeft(2, '0')}';

    // Core employee calls — required, let failures bubble up.
    final attendanceFuture = _api.getTodayAttendance();
    final leaveBalanceFuture = _api.getLeaveBalance();
    final pendingLeavesFuture = _api.getMyPendingLeavesCount();

    // Optional — permission-gated; HrmsApiService already swallows
    // failures here and returns null.
    final summaryFuture = _api.getAttendanceSummary(month);

    final results = await Future.wait([
      attendanceFuture,
      leaveBalanceFuture,
      pendingLeavesFuture,
      summaryFuture,
    ]);

    final punch = TodayPunch.fromAttendanceResponse(
      results[0] as Map<String, dynamic>,
    );
    final leaveBalances = (results[1] as List)
        .cast<Map<String, dynamic>>()
        .map(LeaveBalanceItem.fromJson)
        .toList();
    final pendingLeavesCount = results[2] as int;
    final summaryJson = results[3] as Map<String, dynamic>?;
    final monthSummary = summaryJson != null
        ? AttendanceMonthSummary.fromJson(summaryJson)
        : null;

    // No HRMS-specific unread-notifications endpoint is wired up yet.
    const unreadCount = 0;

    ManagerDashboardData? manager;
    if (isManager) {
      manager = await _loadManagerData(fetchPendingLeaves: canApproveLeaves);
    }

    AdminDashboardData? admin;
    if (isAdmin) {
      final adminJson = await _api.getAdminOverview();
      if (adminJson != null) {
        admin = AdminDashboardData.fromJson(adminJson);
      }
    }

    return HrmsHomeModel(
      punch: punch,
      leaveBalances: leaveBalances,
      pendingLeavesCount: pendingLeavesCount,
      unreadNotifications: unreadCount,
      monthSummary: monthSummary,
      manager: manager,
      admin: admin,
    );
  }

  /// Each manager call soft-fails independently. A 403 on pending leaves
  /// must not prevent team-dashboard cards (or the whole HRMS screen).
  Future<ManagerDashboardData?> _loadManagerData({
    required bool fetchPendingLeaves,
  }) async {
    final pendingFuture = fetchPendingLeaves
        ? _api.getManagerPendingLeavesCount()
        : Future<int>.value(0);
    final correctionsFuture = _api.getPendingCorrectionsCount();
    final teamFuture = _api.getTeamDashboard();

    final results = await Future.wait([
      pendingFuture,
      correctionsFuture,
      teamFuture,
    ]);

    final pendingApprovals = results[0] as int;
    final pendingCorrections = results[1] as int?;
    final teamData = results[2] as Map<String, dynamic>?;

    // No usable team payload → skip manager section entirely.
    if (teamData == null) return null;

    final statsRaw = teamData['stats'];
    final stats = statsRaw is Map
        ? Map<String, dynamic>.from(statsRaw)
        : <String, dynamic>{};

    return ManagerDashboardData(
      pendingApprovals: pendingApprovals,
      pendingCorrections: pendingCorrections,
      teamTotal: (stats['total'] as num?)?.toInt() ?? 0,
      teamPresent: (stats['present'] as num?)?.toInt() ?? 0,
      teamAbsent: (stats['absent'] as num?)?.toInt() ?? 0,
      lastSevenDays: ((stats['lastSevenDays'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(DayAttendanceCount.fromJson)
          .toList(),
      upcomingLeaves: ((stats['upcomingLeaves'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(UpcomingLeave.fromJson)
          .toList(),
    );
  }
}
