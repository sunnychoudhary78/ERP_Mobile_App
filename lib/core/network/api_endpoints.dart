class ApiEndpoints {
  // ───────── AUTH ─────────
  static const String login = 'auth/login';
  static const String permissions = 'auth/permissions';
  static const String changePassword = 'auth/change-password';
  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';
  static const String registerFcmToken = 'auth/register-fcm-token';
  static const String unregisterFcmToken = 'auth/unregister-fcm-token';

  // ───────── USER / EMPLOYEE ─────────
  static const String userDetails = 'auth/me';
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
  static const String items = 'items';
  static const String inventory = 'inventory';
  static const String inventoryLowStock = 'inventory/low-stock';
  static const String inventoryWarehouseStock = 'inventory/warehouse-stock';
  static const String warehouses = 'warehouse';
  static const String customers = 'customers';

  static String customerById(String id) => 'customers/$id';

  // ───────── PRODUCTION (existing backend) ─────────
  static const String workOrders = 'production/work-orders';


  // ───────── SALES CRM (/api/sales — requires sales module backend) ─────────
  static const String salesWorkspace = 'sales/workspace';
  static const String salesConfig = 'sales/config';
  static const String salesLeads = 'sales/leads';
  static const String salesQuotes = 'sales/quotes';
  static const String salesVisits = 'sales/visits';
  static const String salesTeam = 'sales/team';
  static const String salesReportsSummary = 'sales/reports/summary';
  static const String salesCustomersMatch = 'sales/customers/match';
  static const String salesCustomers = 'customers';

  static String salesLeadById(String id) => 'sales/leads/$id';
  static String salesLeadQualify(String id) => 'sales/leads/$id/qualify';
  static String salesLeadFollowUps(String id) => 'sales/leads/$id/follow-ups';
  static String salesLeadWon(String id) => 'sales/leads/$id/won';
  static String salesLeadLost(String id) => 'sales/leads/$id/lost';
  static String salesLeadQuotes(String id) => 'sales/leads/$id/quotes';
  static String salesLeadLinkCustomer(String id) =>
      'sales/leads/$id/link-customer';
  static String salesLeadEnsureCustomer(String id) =>
      'sales/leads/$id/ensure-customer';
  static String salesLeadRequestWonApproval(String id) =>
      'sales/leads/$id/request-won-approval';
  static String salesLeadApproveWon(String id) => 'sales/leads/$id/approve-won';
  static String salesLeadRejectWon(String id) => 'sales/leads/$id/reject-won';
  static String salesLeadBills(String id) => 'sales/leads/$id/bills';
  static String salesLeadBillSend(String leadId, String billId) =>
      'sales/leads/$leadId/bills/$billId/send';
  static String salesLeadBillPayment(String leadId, String billId) =>
      'sales/leads/$leadId/bills/$billId/payment';

  static String salesQuoteById(String id) => 'sales/quotes/$id';
  static String salesQuoteApprove(String id) => 'sales/quotes/$id/approve';
  static String salesQuoteReject(String id) => 'sales/quotes/$id/reject';
  static String salesQuoteSend(String id) => 'sales/quotes/$id/send';

  static String salesActivityComplete(String id) =>
      'sales/activities/$id/complete';

}
