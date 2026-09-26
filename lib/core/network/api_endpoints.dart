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
  static const String attendance = 'attendance';
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

  static const String nextProductCode = 'items/next-product-code';

  static String itemStock(String id) => 'items/$id/stock';

  static String itemCostHistory(String id) => 'items/$id/cost-history';

  /// category
  static const String categories = 'categories';

  static String categoryById(String id) => 'categories/$id';
  // Lookup Product Categories
  static const String lookupProductCategories = 'lookups/product-categories';

  // Vendors
  static const String vendors = 'vendors';

  static String vendorById(String id) => 'vendors/$id';

  static const String importVendors = 'vendors/import';
  static const String lookupVendors = 'lookups/vendors';

  // Purschase Demands
  static const String purchaseDemands = 'purchase-demands';

  static String raisePurchases(String workOrderId) =>
      'purchase-demands/$workOrderId/raise-purchases';

  // Purchase Orders
  static const String purchases = 'purchase';

  static const String importPurchases = 'purchase/import';
  static const String importItems = 'items/import';

  // Purchase Recived

  static String purchaseReceive(String id) => 'purchase/$id/receive';

  static String purchaseReject(String id) => 'purchase/$id/reject';

  // Vendor Payments
  static const String vendorPayments = 'vendor-payments';

  static const String vendorCredits = 'vendor-credits';

  // BOM
  static const String boms = 'bom';
  // sales Crm
  static const String inventorySalesAuto = '/inventory/sales/auto';

  static String bomById(String id) => 'bom/$id';
  static const String bills = 'bills';

  static const String billFromPurchase = 'accounts/bills/from-purchase';

  static const String paymentsReceived = 'accounts/payments-received';

  // STOCK IN/OUT
  static const String stockIn = 'inventory/stock-in';

  static const String stockOut = 'inventory/stock-out';

  static const String stockOutWarehouseStock =
      'inventory/stock-out/warehouse-stock';

  static const String stockOutBills = 'inventory/stock-out/bills';

  static String stockOutBillById(String id) => 'inventory/stock-out/bills/$id';

  // STOCK TRANSFER
  static const String stockTransfer = 'inventory/stock-transfer';

  // Movement Ledger

  static const String inventoryTransactions = 'inventory/transactions';

  // LOT API

  static const String lots = 'lot';

  static String lotById(String id) => 'lot/$id';

  static String lotSummary(String id) => 'lot/$id/summary';

  static String lotProcessings(String id) => 'lot/$id/processings';

  static String lotStartProcessing(String id) => 'lot/$id/start-processing';

  static String lotSendForSelling(String id) => 'lot/$id/send-for-selling';

  static String lotProcessingComplete(String processingId) =>
      'lot/processing/$processingId/complete';

  static const String allocateDirectStock = 'inventory/direct-stock/allocate';
  // Documents
  static const String documents = 'documents';

  // Approvals
  static const String approvalList = 'approvals/list';

  static const String approvalApprove = 'approvals/approve';

  static const String approvalReject = 'approvals/reject';

  static const String approvalForward = 'approvals/forward';

  static const String myApprovalRequests = 'approvals/my-requests';

  static const String myPendingApprovals = 'approvals/my-pending';

  static const String myResubmitApproval = 'approvals/my-resubmit';

  static const String myUpdateApproval = 'approvals/my-update';

  // ───────── PRODUCTION (existing backend) ─────────
  static const String workOrders = 'production/work-orders';
  static const String workOrdersSummary = 'production/work-orders/summary';

  static String workOrderById(String id) => 'production/work-orders/$id';

  static String workOrderExecution(String id) =>
      'production/work-orders/$id/execution';

  static String workOrderQc(String id) => 'production/work-orders/$id/qc';

  static String workOrderTransition(String id) =>
      'production/work-orders/$id/transition';

  static String workOrderComplete(String id) =>
      'production/work-orders/$id/complete';

  static String workOrderFinishFromQc(String id) =>
      'production/work-orders/$id/finish-from-qc';
  static String workOrderNotesPatch(String id) => 'production/work-orders/$id';

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
      'sales/quotes/$id/approve'; // used alreadyy
  static String salesQuoteReject(String id) =>
      'sales/quotes/$id/reject'; // done
  static String salesQuoteSend(String id) => 'sales/quotes/$id/send'; // done
  static String salesPdfdownload(String id) =>
      'sales/quotes/$id/pdf'; // download pdf //done
  static String salesPdfBillDownload(String id) => 'sales/bills/$id/pdf';

  static String salesActivityComplete(String id) =>
      'sales/activities/$id/complete'; // done
}
