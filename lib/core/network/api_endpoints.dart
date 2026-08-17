class ApiEndpoints {
  // ───────── AUTH ─────────
  static const String login = 'auth/login'; // done
  static const String permissions = 'auth/permissions';
  static const String changePassword = 'auth/change-password'; // not done
  static const String forgotPassword = 'auth/forgot-password'; // not done
  static const String resetPassword = 'auth/reset-password';
  static const String registerFcmToken = 'auth/register-fcm-token';
  static const String unregisterFcmToken = 'auth/unregister-fcm-token'; //done

  // ───────── USER / EMPLOYEE ─────────
  static const String userDetails = 'auth/me'; // done
  static const String employeeLeaveBalance = 'employees/leave-balance';

  // ───────── ATTENDANCE ─────────
  static const String checkIn = 'attendance/checkin';
  static const String checkOut = 'attendance/checkout';
  static const String attendanceSummary = 'attendance/summary';
  static const String mobileAttendanceConfig = 'attendance/mobile-config';

  // ───────── LEAVE ─────────
  static const String leaveRequests = 'leave-requests';
  static const String leaveRequestsUserAll = 'leave-requests/user/all';
  static const String leaveRequestsManagerAll =
      'leave-requests/manager/requests/all';
  static const String leaveTypes = 'leave-types';

  /// Legacy catalog path — mobile leave balance uses [employeeLeaveBalance].
  static const String leaveBalances = 'leave-balances';

  static String leaveRequestById(String id) => 'leave-requests/$id';
  static String leaveRequestWithdraw(String id) =>
      'leave-requests/$id/withdraw';
  static String leaveRequestStatus(String id) => 'leave-requests/$id/status';

  // ───────── NOTIFICATIONS ─────────
  static const String notifications = 'notifications';
  static const String notificationsMy = 'notifications/my';

  static String notificationMarkRead(String id) => 'notifications/$id/read';

  // ───────── INVENTORY (existing backend) ─────────
  static const String items = 'items'; // done
  static const String inventory = 'inventory';
  static const String inventoryLowStock = 'inventory/low-stock'; //done
  static const String inventoryWarehouseStock =
      'inventory/warehouse-stock'; // done
  static const String warehouses = 'warehouse'; //done
  static const String customers = 'customers'; //  done

  static String customerById(String id) => 'customers/$id';

  // ───────── INVENTORY (new — add below existing block) ─────────
  static const String inventoryDashboardStats = 'inventory/dashboard/stats';
  static const String lookupItems = 'lookups/items'; //done
  static const String lookupWarehouses = 'lookups/warehouses';

  static String itemById(String id) => 'items/$id';
  static const String inventoryReport = 'inventory/report';
  static const String inventoryReportsFinancial = 'inventory/reports/financial';

  // ───────── PRODUCTION (existing backend) ─────────
  static const String workOrders = 'production/work-orders';

  // ───────── HRMS DASHBOARD   ─────────
  static const String getManagerPendingLeaves =
      'leave-requests/manager/pending';
  static const String getstatsAdminOverviews = 'stats/admin-overview';
  static const String getTeamDashboard = 'employees/team-dashboard';
  static const String attendanceCorrectionPending =
      'attendance/corrections/pending';

  // ───────── SALES CRM (/api/sales — requires sales module backend) ─────────
  static const String salesWorkspace = 'sales/workspace';
  static const String salesConfig = 'sales/config';
  static const String salesLeads = 'sales/leads';
  static const String salesQuotes = 'sales/quotes';
  static const String salesVisits = 'sales/visits'; // done
  static const String salesTeam = 'sales/team'; //done
  static const String salesReportsSummary = 'sales/reports/summary';
  static const String salesCustomersMatch =
      'sales/customers/match'; // it is used to verify lead if it is created by same phon number/email
  static const String salesCustomers = 'customers';

  static String salesLeadById(String id) => 'sales/leads/$id'; // done
  static String salesLeadQualify(String id) => 'sales/leads/$id/qualify'; //done
  static String salesLeadFollowUps(String id) =>
      'sales/leads/$id/follow-ups'; //done
  static String salesLeadWon(String id) => 'sales/leads/$id/won'; // done
  static String salesLeadLost(String id) => 'sales/leads/$id/lost'; //done
  static String salesLeadQuotes(String id) => 'sales/leads/$id/quotes'; // done
  static String salesLeadLinkCustomer(String id) =>
      'sales/leads/$id/link-customer'; // but it is part of salesmatchcustomers
  static String salesLeadEnsureCustomer(String id) =>
      'sales/leads/$id/ensure-customer'; //but it is part of salesmatchcustomers
  static String salesLeadRequestWonApproval(String id) =>
      'sales/leads/$id/request-won-approval'; // done
  static String salesLeadApproveWon(String id) =>
      'sales/leads/$id/approve-won'; // done
  static String salesLeadRejectWon(String id) =>
      'sales/leads/$id/reject-won'; // done
  static String salesLeadBills(String id) => 'sales/leads/$id/bills';
  static String salesLeadBillSend(String leadId, String billId) =>
      'sales/leads/$leadId/bills/$billId/send';
  static String salesLeadBillPayment(String leadId, String billId) =>
      'sales/leads/$leadId/bills/$billId/payment';

  static String salesQuoteById(String id) =>
      'sales/quotes/$id'; // updated quotations -> done
  static String salesQuoteApprove(String id) =>
      'sales/quotes/$id/approve'; // used after sometime
  static String salesQuoteReject(String id) =>
      'sales/quotes/$id/reject'; // use after some time
  static String salesQuoteSend(String id) =>
      'sales/quotes/$id/send'; // use after some time in approvals

  static String salesPdfdownload(String id) =>
      'sales/quotes/$id/pdf'; // download pdf //done
  static String salesPdfBillDownload(String id) => 'sales/bills/$id/pdf';

  static String salesActivityComplete(String id) =>
      'sales/activities/$id/complete'; // done
}
