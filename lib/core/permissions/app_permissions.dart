/// Exact permission name strings used for mobile UI gating.
/// Match frontend menu keys for HRMS / Inventory / Production, and
/// the Mobile Permissions API Guide for CRM.
///
/// HRMS groups include both new (frontend) and legacy (seeded role pack /
/// route middleware) names so UI stays correct while roles migrate.
abstract final class AppPermissions {
  // --- HRMS (new + legacy) ---
  static const attendanceRead = 'attendance.read';
  static const attendanceMark = 'attendance.mark';
  static const attendanceView = 'attendance.view';
  static const leaveRequestRead = 'leave.request.read';
  static const leaveView = 'leave.view';
  static const leaveRequestApprove = 'leave.request.approve';
  static const leaveApprove = 'leave.approve';
  static const teamDashboardRead = 'team.dashboard.read';
  static const teamDashboardView = 'team.dashboard.view';
  static const statsRead = 'stats.read';
  static const statsView = 'stats.view';

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
  static const productionPlanningManage = 'production_planning.manage';
  static const productionView = 'production.view';
  static const productionOrderView = 'production_order.view';
  static const productionOrdersView = 'production_orders.view';
  static const workOrderView = 'work_order.view';

  // --- ANY-of groups for module / feature surfaces ---

  static const List<String> punch = [
    attendanceMark,
    attendanceRead,
    attendanceView,
  ];

  static const List<String> leaveSelf = [leaveRequestRead, leaveView];

  static const List<String> leaveApprovals = [
    leaveRequestApprove,
    leaveApprove,
  ];

  static const List<String> teamDashboard = [
    teamDashboardRead,
    teamDashboardView,
  ];

  static const List<String> stats = [statsRead, statsView];

  static const List<String> hrmsModule = [
    ...punch,
    ...leaveSelf,
    ...leaveApprovals,
    ...teamDashboard,
    ...stats,
  ];

  static const List<String> crmModule = [
    salesCrmLeadsView,
    salesCrmLeadsManage,
  ];

  static const List<String> crmLeads = [salesCrmLeadsView, salesCrmLeadsManage];

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
    productionPlanningManage,
    productionView,
    productionOrderView,
    productionOrdersView,
    workOrderView,
  ];
}
