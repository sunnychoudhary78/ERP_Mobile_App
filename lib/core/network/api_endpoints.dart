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

  // ───────── ATTENDANCE ─────────
  static const String checkIn = 'attendance/checkin';
  static const String checkOut = 'attendance/checkout';
  static const String attendanceSummary = 'attendance/summary';
  static const String mobileAttendanceConfig = 'attendance/mobile-config';

  // ───────── LEAVE ─────────
  static const String leaveRequests = 'leave-requests';
  static const String leaveBalances = 'leave-balances';
  static const String leaveTypes = 'leave-types';

  // ───────── NOTIFICATIONS ─────────
  static const String notifications = 'notifications';

  // ───────── INVENTORY (existing backend) ─────────
  static const String items = 'items';
  static const String inventory = 'inventory';
  static const String inventoryLowStock = 'inventory/low-stock';
  static const String inventoryWarehouseStock = 'inventory/warehouse-stock';
  static const String warehouses = 'warehouse';

  // ───────── PRODUCTION (existing backend) ─────────
  static const String workOrders = 'production/work-orders';

  // ───────── CRM (placeholder — backend module pending) ─────────
  static const String crmLeads = 'crm/leads';
  static const String crmContacts = 'crm/contacts';
  static const String crmCustomers = 'crm/customers';
  static const String crmPipeline = 'crm/pipeline';
  static const String crmActivities = 'crm/activities';
  static const String crmQuotes = 'crm/quotes';
  static const String crmVisits = 'crm/visits';
  static const String crmApprovals = 'crm/approvals';
}
