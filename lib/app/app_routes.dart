import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/home/presentation/screens/crm_sales_screen.dart';
import 'package:erp_app/features/home/presentation/screens/hrms_screen.dart';
import 'package:erp_app/features/home/presentation/screens/inventory_sales_screen.dart';
import 'package:erp_app/features/home/presentation/screens/production_screen.dart';
import 'package:erp_app/features/home/presentation/screens/tracking_dashboard_screen.dart';
import 'package:erp_app/features/inventory/lowstock/presentations/screen/low_stock_screen.dart';
import 'package:erp_app/features/inventory/stocklookup/presentation/screens/stock_lookup_screen.dart';
import 'package:erp_app/features/profile/presentations/screen/profile_screen.dart';
import 'package:erp_app/features/tracking/presentation/claim_reward_screen.dart';
import 'package:erp_app/features/tracking/presentation/tracking_screen.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';

import '../core/screens/subscription_expired_screen.dart';
import '../features/approvals/presentation/screens/approvals_inbox_screen.dart';
import '../features/attendance/presentation/screens/punch_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/crm/activities/presentation/screens/activities_screen.dart';
import '../features/crm/approvals/presentation/screens/crm_approvals_screen.dart';
import '../features/crm/contacts/presentation/screens/contact_detail_screen.dart';
import '../features/crm/contacts/presentation/screens/contact_form_screen.dart';
import '../features/crm/contacts/presentation/screens/contacts_list_screen.dart';
import '../features/crm/customers/presentation/screens/customer_detail_screen.dart';
import '../features/crm/customers/presentation/screens/customers_list_screen.dart';
import '../features/crm/leads/presentation/screens/lead_detail_screen.dart';
import '../features/crm/leads/presentation/screens/lead_form_screen.dart';
import '../features/crm/leads/presentation/screens/leads_list_screen.dart';
import '../features/crm/pipeline/presentation/screens/pipeline_screen.dart';
import '../features/crm/quotes/presentation/screens/quote_detail_screen.dart';
import '../features/crm/quotes/presentation/screens/quote_form_screen.dart';
import '../features/crm/quotes/presentation/screens/quotes_list_screen.dart';
import '../features/crm/visits/presentation/screens/visit_check_in_screen.dart';
import '../features/crm/visits/presentation/screens/visit_tracking_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';

import '../features/leave/presentation/screens/leave_apply_screen.dart';
import '../features/leave/presentation/screens/leave_balance_screen.dart';
import '../features/leave/presentation/screens/leave_status_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/production/presentation/screens/work_orders_screen.dart';

Widget _gate(List<String> anyOf, Widget child) {
  return PermissionGate(anyOf: anyOf, child: child);
}

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (_) => const LoginScreen(),
    '/home': (_) => const HomeScreen(),
    '/subscription-expired': (_) => const SubscriptionExpiredScreen(),

    // HRMS
    '/punch': (_) => _gate(AppPermissions.punch, const PunchScreen()),
    '/leave-balance': (_) =>
        _gate(AppPermissions.leaveSelf, const LeaveBalanceScreen()),
    '/leave-apply': (_) =>
        _gate(AppPermissions.leaveSelf, const LeaveApplyScreen()),
    '/leave-status': (_) =>
        _gate(AppPermissions.leaveSelf, const LeaveStatusScreen()),
    '/approvals': (_) => const ApprovalsInboxScreen(),
    '/notifications': (_) => const NotificationsScreen(),

    // CRM
    '/crm/leads': (_) => const LeadsListScreen(),
    '/crm/leads/detail': (_) =>
        _gate(AppPermissions.crmLeads, const LeadDetailScreen()),
    '/crm/leads/form': (_) =>
        _gate(AppPermissions.crmLeadsManage, const LeadFormScreen()),
    '/crm/contacts': (_) => const ContactsListScreen(),
    '/crm/contacts/detail': (_) =>
        _gate(AppPermissions.crmCustomers, const ContactDetailScreen()),
    '/crm/contacts/form': (_) =>
        _gate(AppPermissions.crmLeadsManage, const ContactFormScreen()),
    '/crm/customers': (_) => const CustomersListScreen(),
    '/crm/customers/detail': (_) =>
        _gate(AppPermissions.crmCustomers, const CustomerDetailScreen()),
    '/crm/pipeline': (_) =>
        _gate(AppPermissions.crmLeads, const PipelineScreen()),
    '/crm/activities': (_) => const ActivitiesScreen(),
    '/crm/approvals': (_) => const CrmApprovalsScreen(),
    '/crm/quotes': (_) =>
        _gate(AppPermissions.crmQuotes, const QuotesListScreen()),
    '/crm/quotes/detail': (_) =>
        _gate(AppPermissions.crmQuotes, const QuoteDetailScreen()),
    '/crm/quotes/form': (_) =>
        _gate(AppPermissions.crmLeadsManage, const QuoteFormScreen()),
    '/crm/visits': (_) =>
        _gate(AppPermissions.crmVisits, const VisitCheckInScreen()),
    '/crm/tracking': (_) =>
        _gate(AppPermissions.crmVisits, const VisitTrackingScreen()),
    '/crm/crm_sales_screen': (_) =>
        _gate(AppPermissions.crmModule, const CrmSalesScreen()),
    '/crm/hrms_sales_screen': (_) =>
        _gate(AppPermissions.hrmsDashboard, const HrmsScreen()),
    '/crm/inventory_sales_screen': (_) => const InventorySalesScreen(),

    // Inventory / Production
    '/stock-lookup': (_) =>
        _gate(AppPermissions.stockLookup, const StockLookupScreen()),
    '/work-orders': (_) =>
        _gate(AppPermissions.productionModule, const WorkOrdersScreen()),
    '/low-stock': (_) => _gate(AppPermissions.lowStock, const LowStockScreen()),
    '/production_screen': (_) => const ProductionDashboardScreen(),

    // Tracking
    '/tracking-dashboard': (_) => const TrackingDashboardScreen(),
    '/tracking_screen': (_) => const TrackingScreen(),
    '/claim_reward_screen': (_) => const ClaimRewardScreen(),

    // profile
    '/profile': (_) => const ProfileScreen(),
  };
}
