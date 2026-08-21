/// Exact permission name strings used for mobile UI gating.
/// Match frontend menu keys for HRMS / Inventory / Production, and
/// the Mobile Permissions API Guide for CRM.
abstract final class AppPermissions {
  // --- HRMS ---
  static const attendanceRead = 'attendance.read';
  static const attendanceMark = 'attendance.mark';
  static const leaveRequestRead = 'leave.request.read';
  static const leaveRequestApprove = 'leave.request.approve';
  static const teamDashboardRead = 'team.dashboard.read';
  static const statsRead = 'stats.read';

  // --- CRM (mobile guide) ---
  static const salesCrmLeadsView = 'sales_crm_leads.view';
  static const salesCrmLeadsManage = 'sales_crm_leads.manage';
  static const salesCrmActivitiesManage = 'sales_crm_activities.manage';
  static const salesApprovalsManage = 'sales_approvals.manage';
  static const salesVisitsManage = 'sales_visits.manage';
  static const customerView = 'customer.view';
  static const salesCustomersView = 'sales_customers.view';

  // --- Inventory ---
  static const dashboardView = 'dashboard.view';
  static const inventoryView = 'inventory.view';
  static const productView = 'product.view';
  static const productManage = 'product.manage';
  static const bomView = 'bom.view';
  static const inventoryReportView = 'inventory_report.view';

  // --- Production ---
  static const productionView = 'production.view';
  static const productionOrderView = 'production_order.view';

  // --- ANY-of groups for module / feature surfaces ---

  static const List<String> hrmsModule = [
    attendanceRead,
    attendanceMark,
    leaveRequestRead,
    teamDashboardRead,
    statsRead,
  ];

  // Punch in/out is controlled by attendance.mark on the backend
  // (both manager and employee roles carry this). attendance.read
  // is kept as a fallback for any role that only has read access
  // but should still see the punch card.
  static const List<String> punch = [attendanceMark, attendanceRead];

  static const List<String> leaveSelf = [leaveRequestRead];

  static const List<String> leaveApprovals = [leaveRequestApprove];

  static const List<String> crmModule = [
    salesCrmLeadsView,
    salesCrmLeadsManage,
  ];

  static const List<String> crmLeads = [
    salesCrmLeadsView,
    salesCrmLeadsManage,
  ];

  static const List<String> crmLeadsManage = [salesCrmLeadsManage];

  static const List<String> crmActivities = [salesCrmActivitiesManage];

  static const List<String> crmApprovals = [salesApprovalsManage];

  static const List<String> crmVisits = [salesVisitsManage];

  static const List<String> crmCustomers = [customerView, salesCustomersView];

  static const List<String> crmQuotes = [
    salesCrmLeadsView,
    salesApprovalsManage,
  ];

  static const List<String> inventoryModule = [dashboardView, inventoryView];

  static const List<String> stockLookup = [
    productView,
    inventoryView,
    productManage,
    bomView,
  ];

  static const List<String> lowStock = [inventoryReportView];

  static const List<String> productionModule = [
    productionView,
    productionOrderView,
    inventoryView,
    dashboardView,
  ];
}