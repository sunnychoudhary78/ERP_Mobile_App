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
      QuickLink(
        'Dashboard',
        '/crm/hrms_sales_screen',
        Icons.fingerprint_rounded,
      ),
      QuickLink('Punch', '/punch', Icons.fingerprint_rounded),
      QuickLink('Leave balance', '/leave-balance', Icons.beach_access_outlined),
      QuickLink('Apply leave', '/leave-apply', Icons.event_available_outlined),
      QuickLink('My leave', '/leave-status', Icons.list_alt_outlined),
      QuickLink('Approvals', '/approvals', Icons.approval_outlined),
    ]),
    LinkSection('CRM', [
      QuickLink(
        'Dashboard',
        '/crm/crm_sales_screen',
        Icons.fingerprint_rounded,
      ),
      QuickLink('Leads', '/crm/leads', Icons.leaderboard_outlined),
      QuickLink('Pipeline', '/crm/pipeline', Icons.view_kanban_outlined),
      QuickLink('Follow-ups', '/crm/activities', Icons.timeline_outlined),
      QuickLink('Approvals', '/crm/approvals', Icons.fact_check_outlined),
      QuickLink('Contacts', '/crm/contacts', Icons.contacts_outlined),
      QuickLink('Customers', '/crm/customers', Icons.business_outlined),
      QuickLink('Quotes', '/crm/quotes', Icons.request_quote_outlined),
    ]),
    LinkSection('Inventory', [
      QuickLink(
        'Dashboard',
        '/crm/inventory_sales_screen',
        Icons.fingerprint_rounded,
      ),
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

  static const double _sectionGap = 24;
  static const double _itemGap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final homeData = ref.watch(homeDataProvider);

    final fullName = profile?.associatesName ?? 'there';
    final firstName = fullName.split(' ').first;
    final designation = (profile?.designation ?? '').trim();
    final initials = fullName.trim().isEmpty
        ? '?'
        : fullName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((e) => e[0].toUpperCase())
              .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
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
        sections: _sections,
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
                // -----------------------------------------------------------
                // TOP WELCOME CARD (Matches Screenshot)
                // -----------------------------------------------------------
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4965), // Deep Slate Teal Accent
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1B4965,
                          ).withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, $firstName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                designation.isNotEmpty
                                    ? designation
                                    : "Here's your operational status.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _sectionGap),

                // -----------------------------------------------------------
                // QUICK ACTIONS (Preserved Layout & Compact Tight Gaps)
                // -----------------------------------------------------------
                const _SectionLabel('QUICK ACTIONS'),
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

                // -----------------------------------------------------------
                // MODULES & SETTINGS LIST TILES
                // -----------------------------------------------------------
                const _SectionLabel('MODULES & SETTINGS'),
                const SizedBox(height: _itemGap),

                _ListCardTile(
                  icon: Icons.person_outline_rounded,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Profile',
                  subtitle: 'Manage your personal details',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(height: 10),

                _ListCardTile(
                  icon: Icons.bar_chart_rounded,
                  iconBgColor: const Color(0xFFFAF5FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'CRM',
                  subtitle: 'Leads, pipeline, and customer info',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrmSalesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _ListCardTile(
                  icon: Icons.badge_outlined,
                  iconBgColor: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFEA580C),
                  title: 'HRMS',
                  subtitle: 'Attendance, leaves, and approvals',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HrmsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _ListCardTile(
                  icon: Icons.inventory_2_outlined,
                  iconBgColor: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Inventory',
                  subtitle: 'Stock lookup and field activities',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventorySalesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
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
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
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

class _ListCardTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListCardTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
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
