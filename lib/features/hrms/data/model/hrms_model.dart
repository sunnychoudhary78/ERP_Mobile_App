// HRMS Dashboard models
// Maps to: docs/mobile/HRMS_Dashboard_Mobile_APIs.md

enum PunchStatus { notPunched, checkedIn, checkedOut }

class TodayPunch {
  final PunchStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const TodayPunch({
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });

  factory TodayPunch.fromAttendanceResponse(Map<String, dynamic> json) {
    final sessions = (json['sessions'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    if (sessions.isEmpty) {
      return const TodayPunch(status: PunchStatus.notPunched);
    }

    // Session with no checkout => currently checked in
    final openSession = sessions.firstWhere(
      (s) => s['checkOutTime'] == null,
      orElse: () => <String, dynamic>{},
    );

    if (openSession.isNotEmpty) {
      return TodayPunch(
        status: PunchStatus.checkedIn,
        checkInTime: _parseDate(openSession['checkInTime']),
      );
    }

    // All sessions closed => checked out
    final last = sessions.last;
    return TodayPunch(
      status: PunchStatus.checkedOut,
      checkInTime: _parseDate(last['checkInTime']),
      checkOutTime: _parseDate(last['checkOutTime']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  String get label {
    switch (status) {
      case PunchStatus.notPunched:
        return 'Not punched';
      case PunchStatus.checkedIn:
        return 'Punched In';
      case PunchStatus.checkedOut:
        return 'Punched Out';
    }
  }

  String get ctaLabel {
    switch (status) {
      case PunchStatus.notPunched:
        return 'Punch In';
      case PunchStatus.checkedIn:
        return 'Punch Out';
      case PunchStatus.checkedOut:
        return 'View History';
    }
  }
}

class LeaveBalanceItem {
  final String id;
  final String leaveTypeId;
  final String name;
  final num available;

  const LeaveBalanceItem({
    required this.id,
    required this.leaveTypeId,
    required this.name,
    required this.available,
  });

  factory LeaveBalanceItem.fromJson(Map<String, dynamic> json) {
    final leaveType = json['leave_type'] as Map<String, dynamic>?;
    return LeaveBalanceItem(
      id: json['id']?.toString() ?? '',
      leaveTypeId: json['leave_type_id']?.toString() ?? '',
      name: leaveType?['name']?.toString() ?? 'Leave',
      available: (json['available'] as num?) ?? 0,
    );
  }
}

class AttendanceMonthSummary {
  final int workingDays;
  final int lateDays;
  final int totalLeaves;
  final int absentDays;
  final int payableDays;
  final String workingHours;

  const AttendanceMonthSummary({
    required this.workingDays,
    required this.lateDays,
    required this.totalLeaves,
    required this.absentDays,
    required this.payableDays,
    required this.workingHours,
  });

  factory AttendanceMonthSummary.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>? ?? json;
    return AttendanceMonthSummary(
      workingDays: (s['workingDays'] as num?)?.toInt() ?? 0,
      lateDays: (s['lateDays'] as num?)?.toInt() ?? 0,
      totalLeaves: (s['totalLeaves'] as num?)?.toInt() ?? 0,
      absentDays: (s['absentDays'] as num?)?.toInt() ?? 0,
      payableDays: (s['payableDays'] as num?)?.toInt() ?? 0,
      workingHours: s['workingHours']?.toString() ?? '--',
    );
  }

  int get total => workingDays + totalLeaves + absentDays;
}

class DayAttendanceCount {
  final String date;
  final int present;
  final int absent;
  final int? total;

  const DayAttendanceCount({
    required this.date,
    required this.present,
    required this.absent,
    this.total,
  });

  factory DayAttendanceCount.fromJson(Map<String, dynamic> json) {
    return DayAttendanceCount(
      date: json['date']?.toString() ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt(),
    );
  }
}

class UpcomingLeave {
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String status;

  const UpcomingLeave({
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory UpcomingLeave.fromJson(Map<String, dynamic> json) {
    // Team-dashboard flattens leaves; admin-overview returns nested Sequelize rows.
    final user = json['user'];
    final leaveTypeRaw = json['leave_type'];

    String leaveTypeName = '—';
    if (leaveTypeRaw is Map) {
      leaveTypeName = leaveTypeRaw['name']?.toString() ?? '—';
    } else if (leaveTypeRaw != null) {
      leaveTypeName = leaveTypeRaw.toString();
    }

    final nestedName = user is Map ? user['name']?.toString() : null;

    return UpcomingLeave(
      employeeName: json['employee_name']?.toString() ?? nestedName ?? '—',
      leaveType: leaveTypeName,
      startDate: json['start_date']?.toString() ??
          json['startDate']?.toString() ??
          '',
      endDate:
          json['end_date']?.toString() ?? json['endDate']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class ManagerDashboardData {
  final int pendingApprovals;
  final int? pendingCorrections; // null if not permitted / failed
  final int teamTotal;
  final int teamPresent;
  final int teamAbsent;
  final List<DayAttendanceCount> lastSevenDays;
  final List<UpcomingLeave> upcomingLeaves;

  const ManagerDashboardData({
    required this.pendingApprovals,
    required this.pendingCorrections,
    required this.teamTotal,
    required this.teamPresent,
    required this.teamAbsent,
    required this.lastSevenDays,
    required this.upcomingLeaves,
  });
}

/// Present / Absent / Leave split used by the "Attendance Overview" donut.
class AttendanceOverview {
  final int present;
  final int absent;
  final int leave;

  const AttendanceOverview({
    required this.present,
    required this.absent,
    required this.leave,
  });

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) {
    return AttendanceOverview(
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      leave: (json['leave'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => present + absent + leave;

  /// e.g. 93.0 for "93% Present" in the donut center label.
  double get presentPercent => total == 0 ? 0 : (present / total) * 100;
}

/// One bar in the "Department Wise Attendance" chart.
class DepartmentAttendanceItem {
  final String name;
  final double percent; // 0-100

  const DepartmentAttendanceItem({required this.name, required this.percent});

  factory DepartmentAttendanceItem.fromJson(Map<String, dynamic> json) {
    return DepartmentAttendanceItem(
      name: json['name']?.toString() ?? '—',
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Permanent / Contract / Intern split used by the "Employee Distribution" donut.
class EmployeeDistribution {
  final int permanent;
  final int contract;
  final int intern;

  const EmployeeDistribution({
    required this.permanent,
    required this.contract,
    required this.intern,
  });

  factory EmployeeDistribution.fromJson(Map<String, dynamic> json) {
    return EmployeeDistribution(
      permanent: (json['permanent'] as num?)?.toInt() ?? 0,
      contract: (json['contract'] as num?)?.toInt() ?? 0,
      intern: (json['intern'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => permanent + contract + intern;
}

/// One slice of the "Staff Distribution" donut — headcount by
/// department (e.g. Software, Marketing, Sales, Admin).
class DepartmentStaffCount {
  final String name;
  final int count;

  const DepartmentStaffCount({required this.name, required this.count});

  factory DepartmentStaffCount.fromJson(Map<String, dynamic> json) {
    return DepartmentStaffCount(
      name: json['name']?.toString() ?? '—',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One row in the "Today's Activities" timeline.
class TodayActivity {
  final String title;
  final String time;

  const TodayActivity({required this.title, required this.time});

  factory TodayActivity.fromJson(Map<String, dynamic> json) {
    return TodayActivity(
      title: json['title']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

class AdminDashboardData {
  final int employeesCount;
  final double employeesChangePercent;
  final int departmentsCount;
  final int adminsCount;

  final int onLeaveToday;
  final double onLeaveChangePercent;

  final int attendanceTodayCount;
  final double attendanceTodayChangePercent;

  final int openPositions;
  final double openPositionsChangePercent;

  final AttendanceOverview attendanceOverview;
  final List<DepartmentAttendanceItem> departmentAttendance;
  final EmployeeDistribution employeeDistribution;

  /// Pre-formatted display string, e.g. "₹3.45 Cr".
  final String payrollThisMonth;

  /// e.g. 4.3 (out of 5).
  final double performanceRating;

  /// Headcount by department — drives the "Staff Distribution" donut
  /// and its legend on the HRMS home screen.
  final List<DepartmentStaffCount> departmentDistribution;

  /// "Pending Claims" metric on the HR Metrics Overview grid.
  final int pendingClaims;

  /// "Today's Activities" timeline (interviews, onboarding, etc.).
  final List<TodayActivity> todaysActivities;

  final List<DayAttendanceCount> last7DaysAttendance;
  final List<UpcomingLeave> upcomingLeaves;

  const AdminDashboardData({
    required this.employeesCount,
    required this.employeesChangePercent,
    required this.departmentsCount,
    required this.adminsCount,
    required this.onLeaveToday,
    required this.onLeaveChangePercent,
    required this.attendanceTodayCount,
    required this.attendanceTodayChangePercent,
    required this.departmentDistribution,
    required this.pendingClaims,
    required this.todaysActivities,
    required this.openPositions,
    required this.openPositionsChangePercent,
    required this.attendanceOverview,
    required this.departmentAttendance,
    required this.employeeDistribution,
    required this.payrollThisMonth,
    required this.performanceRating,
    required this.last7DaysAttendance,
    required this.upcomingLeaves,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      employeesCount: (json['employeesCount'] as num?)?.toInt() ?? 0,
      employeesChangePercent:
          (json['employeesChangePercent'] as num?)?.toDouble() ?? 0,
      departmentsCount: (json['departmentsCount'] as num?)?.toInt() ?? 0,
      adminsCount: (json['adminsCount'] as num?)?.toInt() ?? 0,
      onLeaveToday: (json['onLeaveToday'] as num?)?.toInt() ?? 0,
      onLeaveChangePercent:
          (json['onLeaveChangePercent'] as num?)?.toDouble() ?? 0,
      attendanceTodayCount:
          (json['attendanceTodayCount'] as num?)?.toInt() ?? 0,
      attendanceTodayChangePercent:
          (json['attendanceTodayChangePercent'] as num?)?.toDouble() ?? 0,
      openPositions: (json['openPositions'] as num?)?.toInt() ?? 0,
      openPositionsChangePercent:
          (json['openPositionsChangePercent'] as num?)?.toDouble() ?? 0,
      attendanceOverview: AttendanceOverview.fromJson(
        (json['attendanceOverview'] as Map<String, dynamic>?) ?? const {},
      ),
      departmentAttendance: ((json['departmentAttendance'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(DepartmentAttendanceItem.fromJson)
          .toList(),
      employeeDistribution: EmployeeDistribution.fromJson(
        (json['employeeDistribution'] as Map<String, dynamic>?) ?? const {},
      ),
      payrollThisMonth: json['payrollThisMonth']?.toString() ?? '—',
      performanceRating:
          (json['performanceRating'] as num?)?.toDouble() ?? 0,
      departmentDistribution: ((json['departmentDistribution'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(DepartmentStaffCount.fromJson)
          .toList(),
      pendingClaims: (json['pendingClaims'] as num?)?.toInt() ?? 0,
      todaysActivities: ((json['todaysActivities'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(TodayActivity.fromJson)
          .toList(),
      last7DaysAttendance: ((json['last7DaysAttendance'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(DayAttendanceCount.fromJson)
          .toList(),
      upcomingLeaves: ((json['upcomingLeaves'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(UpcomingLeave.fromJson)
          .toList(),
    );
  }
}

/// Aggregated model the HRMS home screen renders from.
/// `manager` / `admin` / `monthSummary` are null when the user lacks
/// permission or the call failed (403) — UI hides those sections.
class HrmsHomeModel {
  final TodayPunch punch;
  final List<LeaveBalanceItem> leaveBalances;
  final int pendingLeavesCount;
  final int unreadNotifications;
  final AttendanceMonthSummary? monthSummary;
  final ManagerDashboardData? manager;
  final AdminDashboardData? admin;

  const HrmsHomeModel({
    required this.punch,
    required this.leaveBalances,
    required this.pendingLeavesCount,
    required this.unreadNotifications,
    this.monthSummary,
    this.manager,
    this.admin,
  });
}