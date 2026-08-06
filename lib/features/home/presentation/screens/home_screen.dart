import 'package:erp_app/features/home/presentation/screens/crm_sales_screen.dart';
import 'package:erp_app/features/home/presentation/screens/hrms_screen.dart';
import 'package:erp_app/features/home/presentation/screens/inventory_sales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _sections = <LinkSection>[
    LinkSection('Attendance & leave', [
      QuickLink('Punch', '/punch', Icons.fingerprint_rounded),
      QuickLink('Leave balance', '/leave-balance', Icons.beach_access_outlined),
      QuickLink('Apply leave', '/leave-apply', Icons.event_available_outlined),
      QuickLink('My leave', '/leave-status', Icons.list_alt_outlined),
      QuickLink('Approvals', '/approvals', Icons.approval_outlined),
    ]),
    LinkSection('CRM', [
      QuickLink('Leads', '/crm/leads', Icons.leaderboard_outlined),
      QuickLink('Pipeline', '/crm/pipeline', Icons.view_kanban_outlined),
      QuickLink('Follow-ups', '/crm/activities', Icons.timeline_outlined),
      QuickLink('Approvals', '/crm/approvals', Icons.fact_check_outlined),
      QuickLink('Contacts', '/crm/contacts', Icons.contacts_outlined),
      QuickLink('Customers', '/crm/customers', Icons.business_outlined),
      QuickLink('Quotes', '/crm/quotes', Icons.request_quote_outlined),
    ]),
    LinkSection('Field & inventory', [
      QuickLink('Visits', '/crm/visits', Icons.location_on_outlined),
      QuickLink('Team tracking', '/crm/tracking', Icons.map_outlined),
      QuickLink('Stock lookup', '/stock-lookup', Icons.inventory_2_outlined),
      QuickLink(
        'Work orders',
        '/work-orders',
        Icons.precision_manufacturing_outlined,
      ),
    ]),
  ];

  static const double _sectionGap = 20;
  static const double _itemGap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final homeData = ref.watch(homeDataProvider);

    final fullName = profile?.associatesName ?? 'there';
    final firstName = fullName.split(' ').first;
    final initials = fullName.trim().isEmpty
        ? '?'
        : fullName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((e) => e[0].toUpperCase())
              .join();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppDrawer(
        fullName: fullName,
        initials: initials,
        sections: _sections,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(homeDataProvider.future);
        },
        child: homeData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Greeting Banner with integrated Quick Stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primaryDark.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $firstName',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Here's your operational status.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionGap),

              // Quick Actions Grid (4-Column Layout)
              _SectionLabel('QUICK ACTIONS'),
              const SizedBox(height: _itemGap),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _QuickActionButton(
                    icon: Icons.fingerprint_rounded,
                    label: 'Punch',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/punch'),
                  ),
                  _QuickActionButton(
                    icon: Icons.event_available_outlined,
                    label: 'Apply Leave',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/leave-apply'),
                  ),
                  _QuickActionButton(
                    icon: Icons.leaderboard_outlined,
                    label: 'Leads',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/crm/leads'),
                  ),
                  _QuickActionButton(
                    icon: Icons.location_on_outlined,
                    label: 'Visits',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/crm/visits'),
                  ),
                ],
              ),
              const SizedBox(height: _sectionGap),

              // Pulse Metrics Horizontal Cards
              _SectionLabel('METRICS & STATS'),
              const SizedBox(height: _itemGap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _PulseMetricCard(
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        title: 'Punch status',
                        value: data.punchTime,
                        badgeText: data.punchBadgeText,
                        badgeColor: data.isLoggedIn
                            ? AppColors.success
                            : AppColors.danger,
                        onTap: () => Navigator.pushNamed(context, '/punch'),
                      ),
                    ),
                    const SizedBox(width: _itemGap),
                    Expanded(
                      child: _PulseMetricCard(
                        icon: Icons.pending_actions_rounded,
                        iconColor: AppColors.danger,
                        title: 'Pending',
                        value: data.pendingCount,
                        badgeText: data.pendingBadgeText,
                        badgeColor: AppColors.danger,
                        onTap: () => Navigator.pushNamed(context, '/approvals'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _itemGap),

              // Next Activity / Follow-Up Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, data.followUpRoute),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'NEXT SCHEDULED TASK',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.nextFollowUpTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: data.nextFollowUpTime.isEmpty
                      ? const Icon(Icons.chevron_right, color: AppColors.muted)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data.nextFollowUpTime,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: _sectionGap),

              // Modules Section (2-Column Grid Layout)
              // Module Hub Header
              _SectionLabel('MODULE HUB'),
              const SizedBox(height: _itemGap),

              // Horizontal 2-Column Row (like Contacts / Customers in image)
              Row(
                children: [
                  Expanded(
                    child: _ModuleCompactTile(
                      title: 'CRM & Sales',
                      icon: Icons.bar_chart_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrmSalesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModuleCompactTile(
                      title: 'HRMS',
                      icon: Icons.badge_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HrmsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Full Width Tile (like Follow-ups in image)
              _ModuleCompactTile(
                title: 'Operations',
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventorySalesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _PulseMetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeColor,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badgeText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCompactTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCompactTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
          ),
          if (hasUnread)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LinkSection {
  final String title;
  final List<QuickLink> links;

  const LinkSection(this.title, this.links);
}

class QuickLink {
  final String label;
  final String route;
  final IconData icon;

  const QuickLink(this.label, this.route, this.icon);
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

class HomeDashboardData {
  final String punchTime;
  final String punchBadgeText;
  final bool isLoggedIn;
  final String pendingCount;
  final String pendingBadgeText;
  final String nextFollowUpTitle;
  final String nextFollowUpTime;
  final String followUpRoute;

  const HomeDashboardData({
    required this.punchTime,
    required this.punchBadgeText,
    required this.isLoggedIn,
    required this.pendingCount,
    required this.pendingBadgeText,
    required this.nextFollowUpTitle,
    required this.nextFollowUpTime,
    required this.followUpRoute,
  });
}

final homeDataProvider = FutureProvider.autoDispose<HomeDashboardData>((
  ref,
) async {
  return const HomeDashboardData(
    punchTime: '-',
    punchBadgeText: 'LOGGED IN',
    isLoggedIn: true,
    pendingCount: '-',
    pendingBadgeText: '',
    nextFollowUpTitle: 'No follow-ups scheduled',
    nextFollowUpTime: '',
    followUpRoute: '/crm/activities',
  );
});
