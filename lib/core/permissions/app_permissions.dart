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
  static const attendanceSummaryView = 'attendance.summary.view';
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
  static const customerManage = 'customer.manage';
  static const salesCustomersView = 'sales_customers.view';

  // --- Inventory ---
  static const dashboardView = 'dashboard.view';
  static const inventoryView = 'inventory.view';
  static const inventoryManage = 'inventory.manage';
  static const productView = 'product.view';
  static const productManage = 'product.manage';
  static const productCategoryView = 'product_category.view';
  static const productCategoryManage = 'product_category.manage';
  static const vendorView = 'vendor.view';
  static const vendorManage = 'vendor.manage';
  static const purchaseOrderView = 'purchase_order.view';
  static const purchaseOrderReceive = 'purchase_order.receive';
  static const purchaseOrderManage = 'purchase_order.manage';
  static const billView = 'bill.view';
  static const billManage = 'bill.manage';
  static const approvalView = 'approval.view';
  static const approvalApprove = 'approval.approve';
  static const approvalReject = 'approval.reject';
  static const bomView = 'bom.view';
  static const bomManage = 'bom.manage';
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

  static const List<String> hrmsDashboard = [attendanceSummaryView];

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

  static const List<String> crmCustomersManage = [
    customerManage,
    salesCrmLeadsManage,
  ];

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

  static const List<String> productAccess = [
    productView,
    productManage,
    inventoryView,
  ];

  static const List<String> productManageAccess = [productManage];

  static const List<String> productStockManageAccess = [
    productManage,
    inventoryManage,
  ];

  static const List<String> productCategories = [
    productCategoryView,
    productCategoryManage,
    productView,
    productManage,
  ];

  static const List<String> productCategoriesManage = [
    productCategoryManage,
    productManage,
  ];

  static const List<String> vendors = [vendorView, vendorManage];

  static const List<String> vendorsManage = [vendorManage];

  static const List<String> purchaseDemand = [purchaseOrderView, approvalView];

  static const List<String> purchaseDemandApprove = [
    approvalApprove,
    approvalView,
  ];

  static const List<String> purchaseDemandReject = [
    approvalReject,
    approvalApprove,
  ];

  static const List<String> purchaseOrdersManage = [
    purchaseOrderManage,
    purchaseOrderReceive,
  ];

  static const List<String> purchaseReceived = [
    purchaseOrderView,
    purchaseOrderReceive,
    purchaseOrderManage,
  ];

  static const List<String> purchaseReceiveAction = [
    purchaseOrderReceive,
    purchaseOrderManage,
  ];

  static const List<String> billsAccess = [
    billView,
    billManage,
    purchaseOrderView,
  ];

  static const List<String> billCreateFromPurchase = [
    billManage,
    purchaseOrderManage,
  ];

  static const List<String> bomAccess = [bomView, bomManage];

  static const List<String> lowStock = [inventoryReportView];

  static const List<String> productionModule = [
    productionPlanningManage,
    productionView,
    productionOrderView,
    productionOrdersView,
    workOrderView,
  ];
}
