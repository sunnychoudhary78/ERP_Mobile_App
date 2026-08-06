
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
import '../features/inventory/presentation/screens/stock_lookup_screen.dart';
import '../features/leave/presentation/screens/leave_apply_screen.dart';
import '../features/leave/presentation/screens/leave_balance_screen.dart';
import '../features/leave/presentation/screens/leave_status_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/production/presentation/screens/work_orders_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (_) => const LoginScreen(),
    '/home': (_) => const HomeScreen(),
    '/subscription-expired': (_) => const SubscriptionExpiredScreen(),

    // HRMS
    '/punch': (_) => const PunchScreen(),
    '/leave-balance': (_) => const LeaveBalanceScreen(),
    '/leave-apply': (_) => const LeaveApplyScreen(),
    '/leave-status': (_) => const LeaveStatusScreen(),
    '/approvals': (_) => const ApprovalsInboxScreen(),
    '/notifications': (_) => const NotificationsScreen(),

    // CRM
    '/crm/leads': (_) => const LeadsListScreen(),
    '/crm/leads/detail': (_) => const LeadDetailScreen(),
    '/crm/leads/form': (_) => const LeadFormScreen(),
    '/crm/contacts': (_) => const ContactsListScreen(),
    '/crm/contacts/detail': (_) => const ContactDetailScreen(),
    '/crm/contacts/form': (_) => const ContactFormScreen(),
    '/crm/customers': (_) => const CustomersListScreen(),
    '/crm/customers/detail': (_) => const CustomerDetailScreen(),
    '/crm/pipeline': (_) => const PipelineScreen(),
    '/crm/activities': (_) => const ActivitiesScreen(),
    '/crm/approvals': (_) => const CrmApprovalsScreen(),
    '/crm/quotes': (_) => const QuotesListScreen(),
    '/crm/quotes/detail': (_) => const QuoteDetailScreen(),
    '/crm/quotes/form': (_) => const QuoteFormScreen(),
    '/crm/visits': (_) => const VisitCheckInScreen(),
    '/crm/tracking': (_) => const VisitTrackingScreen(),


    // Inventory / Production
    '/stock-lookup': (_) => const StockLookupScreen(),
    '/work-orders': (_) => const WorkOrdersScreen(),
  };
}
