import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/permissions/nav_links.dart';
import 'package:erp_app/features/home/presentation/screens/crm_sales_screen.dart';
import 'package:erp_app/features/home/presentation/screens/hrms_screen.dart';
import 'package:erp_app/features/home/presentation/screens/inventory_sales_screen.dart';
import 'package:erp_app/features/home/presentation/screens/production_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

export 'package:erp_app/core/permissions/nav_links.dart'
    show LinkSection, QuickLink;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _sections = <LinkSection>[
    LinkSection('Attendance & leave', [
      QuickLink(
        'Dashboard',
        '/crm/hrms_sales_screen',
        Icons.fingerprint_rounded,
        anyOf: AppPermissions.hrmsModule,
      ),
      QuickLink(
        'Punch',
        '/punch',
        Icons.fingerprint_rounded,
        anyOf: AppPermissions.punch,
      ),
      QuickLink(
        'Leave balance',
        '/leave-balance',
        Icons.beach_access_outlined,
        anyOf: AppPermissions.leaveSelf,
      ),
      QuickLink(
        'Apply leave',
        '/leave-apply',
        Icons.event_available_outlined,
        anyOf: AppPermissions.leaveSelf,
      ),
      QuickLink(
        'My leave',
        '/leave-status',
        Icons.list_alt_outlined,
        anyOf: AppPermissions.leaveSelf,
      ),
      QuickLink(
        'Approvals',
        '/approvals',
        Icons.approval_outlined,
        anyOf: AppPermissions.leaveApprovals,
      ),
    ]),
    LinkSection('CRM', [
      QuickLink(
        'Dashboard',
        '/crm/crm_sales_screen',
        Icons.fingerprint_rounded,
        anyOf: AppPermissions.crmModule,
      ),
      QuickLink(
        'Leads',
        '/crm/leads',
        Icons.leaderboard_outlined,
        anyOf: AppPermissions.crmLeads,
      ),
      QuickLink(
        'Pipeline',
        '/crm/pipeline',
        Icons.view_kanban_outlined,
        anyOf: AppPermissions.crmLeads,
      ),
      QuickLink(
        'Follow-ups',
        '/crm/activities',
        Icons.timeline_outlined,
        anyOf: AppPermissions.crmActivities,
      ),
      QuickLink(
        'Approvals',
        '/crm/approvals',
        Icons.fact_check_outlined,
        anyOf: AppPermissions.crmApprovals,
      ),
      QuickLink(
        'Contacts',
        '/crm/contacts',
        Icons.contacts_outlined,
        anyOf: AppPermissions.crmCustomers,
      ),
      QuickLink(
        'Customers',
        '/crm/customers',
        Icons.business_outlined,
        anyOf: AppPermissions.crmCustomers,
      ),
      QuickLink(
        'Quotes',
        '/crm/quotes',
        Icons.request_quote_outlined,
        anyOf: AppPermissions.crmQuotes,
      ),
      QuickLink(
        'Visits',
        '/crm/visits',
        Icons.location_on_outlined,
        anyOf: AppPermissions.crmVisits,
      ),
      QuickLink(
        'Team tracking',
        '/crm/tracking',
        Icons.map_outlined,
        anyOf: AppPermissions.crmVisits,
      ),
    ]),
    LinkSection('Inventory', [
      QuickLink(
        'Dashboard',
        '/crm/inventory_sales_screen',
        Icons.fingerprint_rounded,
        anyOf: AppPermissions.inventoryModule,
      ),
      QuickLink(
        'Stock lookup',
        '/stock-lookup',
        Icons.inventory_2_outlined,
        anyOf: AppPermissions.stockLookup,
      ),
      QuickLink(
        'Low stock',
        '/low-stock',
        Icons.warning_amber_outlined,
        anyOf: AppPermissions.lowStock,
      ),
    ]),
    LinkSection('Production', [
      QuickLink(
        'Dashboard',
        '/production_screen',
        Icons.fingerprint_rounded,
        anyOf: AppPermissions.productionModule,
      ),
      QuickLink(
        'Orders',
        '/work-orders',
        Icons.precision_manufacturing_outlined,
        anyOf: AppPermissions.productionModule,
      ),
    ]),

    // LinkSection('Tracking', [
    //   QuickLink(
    //     'Dashboard',
    //     '/tracking-dashboard',
    //     Icons.map_outlined,
    //     anyOf: AppPermissions.productionModule,
    //   ),

    //   QuickLink(
    //     'Live Tracking',
    //     '/tracking_screen',
    //     Icons.my_location_rounded,
    //     anyOf: AppPermissions.productionModule,
    //   ),
    // ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final homeData = ref.watch(homeDataProvider);
    final drawerSections = filterLinkSections(_sections, authState);

    final fullName = profile?.associatesName ?? 'there';
    final firstName = fullName.split(' ').first;
    final designation = (profile?.designation ?? 'Employee').trim();
    final initials = fullName.trim().isEmpty
        ? '?'
        : fullName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((e) => e[0].toUpperCase())
              .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Overview of your business',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          _NotificationBellButton(unreadCount: ref.watch(unreadCountProvider)),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed == true && context.mounted) {
                ref.read(authProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF1E293B)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppDrawer(
        fullName: fullName,
        initials: initials,
        sections: drawerSections,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(homeDataProvider.future);
        },
        child: homeData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. WELCOME CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4F72), Color(0xFF154360)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  firstName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    designation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. METRICS ROW
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       _MetricCard(
                //         title: 'Total Employees',
                //         value: data.totalEmployees,
                //         growth: data.totalEmployeesGrowth,
                //         icon: Icons.people_outline,
                //         iconBg: const Color(0xFFEFF6FF),
                //         iconColor: const Color(0xFF3B82F6),
                //       ),
                //       const SizedBox(width: 12),
                //       _MetricCard(
                //         title: 'Leads',
                //         value: data.leadsCount,
                //         growth: data.leadsGrowth,
                //         icon: Icons.bar_chart_outlined,
                //         iconBg: const Color(0xFFFAF5FF),
                //         iconColor: const Color(0xFFA855F7),
                //       ),
                //       const SizedBox(width: 12),
                //       _MetricCard(
                //         title: 'Low Stock Items',
                //         value: data.lowStockCount,
                //         growth: data.lowStockGrowth,
                //         icon: Icons.inventory_2_outlined,
                //         iconBg: const Color(0xFFF0FDF4),
                //         iconColor: const Color(0xFF22C55E),
                //       ),
                //       const SizedBox(width: 12),
                //       _MetricCard(
                //         title: 'Production Orders',
                //         value: data.productionOrdersCount,
                //         growth: data.productionOrdersGrowth,
                //         icon: Icons.assessment_outlined,
                //         iconBg: const Color(0xFFFFF7ED),
                //         iconColor: const Color(0xFFF97316),
                //       ),
                //     ],
                //   ),
                // ),
                //const SizedBox(height: 24),

                // 3. QUICK ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    // TextButton(
                    //   onPressed: () {},
                    //   child: const Text('View All'),
                    // ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: [
                    if (authState.canAny(AppPermissions.punch))
                      _QuickActionTile(
                        icon: Icons.access_time,
                        title: 'Punch In',
                        subtitle: 'Mark attendance',
                        iconColor: const Color(0xFF3B82F6),
                        onTap: () => Navigator.pushNamed(context, '/punch'),
                      ),
                    if (authState.canAny(AppPermissions.crmLeads))
                      _QuickActionTile(
                        icon: Icons.person,
                        title: 'View Lead',
                        subtitle: 'View lead',
                        iconColor: const Color(0xFFA855F7),
                        onTap: () => Navigator.pushNamed(context, '/crm/leads'),
                      ),
                    if (authState.canAny(AppPermissions.stockLookup))
                      _QuickActionTile(
                        icon: Icons.search,
                        title: 'Stock Lookup',
                        subtitle: 'Check inventory',
                        iconColor: const Color(0xFF22C55E),
                        onTap: () =>
                            Navigator.pushNamed(context, '/stock-lookup'),
                      ),
                    if (authState.canAny(AppPermissions.productionModule))
                      _QuickActionTile(
                        icon: Icons.show_chart,
                        title: 'Production',
                        subtitle: 'See order',
                        iconColor: const Color(0xFFF97316),
                        onTap: () =>
                            Navigator.pushNamed(context, '/work-orders'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. MODULES SECTION
                const Text(
                  'Modules',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    // Only build cards for modules the user actually has
                    // permission to see — no permission check, no blank
                    // gap left behind in the grid.
                    final modules = <_ModuleCard>[
                      if (authState.canAny(AppPermissions.crmModule))
                        _ModuleCard(
                          title: 'CRM',
                          description:
                              'Manage leads, pipeline and customer relationships',
                          icon: Icons.person_outline_rounded,
                          decorativeIcon: Icons.groups_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CrmSalesScreen(),
                            ),
                          ),
                        ),
                      if (authState.canAny(AppPermissions.hrmsModule))
                        _ModuleCard(
                          title: 'HRMS',
                          description:
                              'Attendance, leaves, approvals and employee management',
                          icon: Icons.person_outline_rounded,
                          decorativeIcon: Icons.calendar_month_rounded,
                          accentColor: const Color(0xFFF97316),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HrmsScreen(),
                            ),
                          ),
                        ),
                      if (authState.canAny(AppPermissions.inventoryModule))
                        _ModuleCard(
                          title: 'Inventory',
                          description:
                              'Stock lookup, transfers and field activities',
                          icon: Icons.inventory_2_rounded,
                          decorativeIcon: Icons.inventory_2_rounded,
                          accentColor: const Color(0xFF22C55E),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventorySalesScreen(),
                            ),
                          ),
                        ),
                      if (authState.canAny(AppPermissions.productionModule))
                        _ModuleCard(
                          title: 'Production',
                          description:
                              'Production orders, planning and tracking',
                          icon: Icons.precision_manufacturing_rounded,
                          decorativeIcon: Icons.factory_rounded,
                          accentColor: const Color(0xFF3B82F6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductionDashboardScreen(),
                            ),
                          ),
                        ),
                    ];

                    if (modules.isEmpty) return const SizedBox.shrink();

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: modules,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 5. TODAY'S SUMMARY FOOTER CARD
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(16),
                //     border: Border.all(color: const Color(0xFFE2E8F0)),
                //   ),
                //   child: Column(
                //     children: [
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           const Text(
                //             "Today's Summary",
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               fontSize: 14,
                //               color: Color(0xFF0F172A),
                //             ),
                //           ),
                //           Row(
                //             children: [
                //               Text(
                //                 data.summaryDate,
                //                 style: const TextStyle(
                //                   color: Color(0xFF64748B),
                //                   fontSize: 12,
                //                 ),
                //               ),
                //               const SizedBox(width: 4),
                //               const Icon(Icons.calendar_today_outlined,
                //                   size: 14, color: Color(0xFF64748B)),
                //             ],
                //           )
                //         ],
                //       ),
                //       const SizedBox(height: 16),
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceAround,
                //         children: [
                //           _SummaryItem(
                //             icon: Icons.check_circle_outline,
                //             iconColor: const Color(0xFF3B82F6),
                //             title: 'Attendance',
                //             value: data.attendancePercentage,
                //             subtitle: 'Present',
                //           ),
                //           _SummaryItem(
                //             icon: Icons.access_time,
                //             iconColor: const Color(0xFFA855F7),
                //             title: 'Leaves',
                //             value: data.pendingLeaves,
                //             subtitle: 'Pending',
                //           ),
                //           _SummaryItem(
                //             icon: Icons.widgets_outlined,
                //             iconColor: const Color(0xFF22C55E),
                //             title: 'Low Stock',
                //             value: data.lowStockItemsCount,
                //             subtitle: 'Items',
                //           ),
                //           _SummaryItem(
                //             icon: Icons.show_chart,
                //             iconColor: const Color(0xFFF97316),
                //             title: 'Production',
                //             value: data.productionOrdersTotal,
                //             subtitle: 'Orders',
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String growth;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                growth,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'vs last month',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final IconData decorativeIcon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.decorativeIcon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Faint decorative icon watermark, bleeding off the
              // bottom-right corner of the card.
              Positioned(
                right: -18,
                bottom: -14,
                child: Icon(
                  decorativeIcon,
                  size: 96,
                  color: accentColor.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 44),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;

  const _NotificationBellButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.pushNamed(context, '/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            hasUnread
                ? Icons.notifications_rounded
                : Icons.notifications_outlined,
            color: const Color(0xFF1E293B),
            size: 24,
          ),
          if (hasUnread)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF8FAFC),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool?> showLogoutConfirmationDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Logout confirmation',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _LogoutDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Log out?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll need to sign in again to access your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Yes, logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Data model dynamically backfilling card details
class HomeDashboardData {
  final String totalEmployees;
  final String totalEmployeesGrowth;
  final String leadsCount;
  final String leadsGrowth;
  final String lowStockCount;
  final String lowStockGrowth;
  final String productionOrdersCount;
  final String productionOrdersGrowth;

  final String summaryDate;
  final String attendancePercentage;
  final String pendingLeaves;
  final String lowStockItemsCount;
  final String productionOrdersTotal;

  const HomeDashboardData({
    required this.totalEmployees,
    required this.totalEmployeesGrowth,
    required this.leadsCount,
    required this.leadsGrowth,
    required this.lowStockCount,
    required this.lowStockGrowth,
    required this.productionOrdersCount,
    required this.productionOrdersGrowth,
    required this.summaryDate,
    required this.attendancePercentage,
    required this.pendingLeaves,
    required this.lowStockItemsCount,
    required this.productionOrdersTotal,
  });
}

final homeDataProvider = FutureProvider.autoDispose<HomeDashboardData>((
  ref,
) async {
  return const HomeDashboardData(
    totalEmployees: '124',
    totalEmployeesGrowth: '↑ 8%',
    leadsCount: '132',
    leadsGrowth: '↑ 12%',
    lowStockCount: '18',
    lowStockGrowth: '↑ 5%',
    productionOrdersCount: '32',
    productionOrdersGrowth: '↑ 7%',
    summaryDate: '23 Aug, 2026',
    attendancePercentage: '89%',
    pendingLeaves: '6',
    lowStockItemsCount: '18',
    productionOrdersTotal: '32',
  );
});
