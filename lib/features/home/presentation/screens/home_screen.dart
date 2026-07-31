import 'package:erp_app/core/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
      QuickLink('Contacts', '/crm/contacts', Icons.contacts_outlined),
      QuickLink('Customers', '/crm/customers', Icons.business_outlined),
      QuickLink('Pipeline', '/crm/pipeline', Icons.view_kanban_outlined),
      QuickLink('Activities', '/crm/activities', Icons.timeline_outlined),
      QuickLink('Quotes', '/crm/quotes', Icons.request_quote_outlined),
    ]),
    LinkSection('Field & inventory', [
      QuickLink('Visits', '/crm/visits', Icons.location_on_outlined),
      QuickLink('Team tracking', '/crm/tracking', Icons.map_outlined),
      QuickLink('Stock lookup', '/stock-lookup', Icons.inventory_2_outlined),
      QuickLink('Work orders', '/work-orders', Icons.precision_manufacturing_outlined),
    ]),
  ];

  // Flat list used by the drawer (all links in one place).
  // static List<QuickLink> get _allLinks =>
  //     _sections.expand((s) => s.links).toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
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
        title: const Text('Home'),
        actions: [
          _NotificationBellButton(
            unreadCount: ref.watch(unreadCountProvider),
          ),
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
          // TODO: hook up refresh (attendance / approvals / stock counts)
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Greeting header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $firstName',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here\'s what needs your attention today.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Status cards row
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  const cards = [
                    _StatusCard(
                      title: 'Today punch',
                      value: '—',
                      hint: 'Wire attendance summary here',
                      icon: Icons.fingerprint_rounded,
                    ),
                    _StatusCard(
                      title: 'Pending approvals',
                      value: '—',
                      hint: 'Wire approvals count here',
                      icon: Icons.approval_outlined,
                    ),
                    _StatusCard(
                      title: 'Low stock alerts',
                      value: '—',
                      hint: 'Wire inventory/low-stock count here',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ];
                  return SizedBox(width: 200, child: cards[index]);
                },
              ),
            ),
            const SizedBox(height: 26),

            // Quick links grouped by section, as a grid
            for (final section in _sections) ...[
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.links.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemBuilder: (context, i) {
                  final link = section.links[i];
                  return _QuickLinkTile(link: link);
                },
              ),
              const SizedBox(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bell icon with a small dynamic unread-count badge.
/// The count comes straight from [unreadCountProvider], so it updates
/// automatically (drops to 0, hides itself) the moment the user reads
/// or deletes notifications on the Notifications screen — no manual
/// refresh needed here.
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

class _QuickLinkTile extends StatelessWidget {
  final QuickLink link;

  const _QuickLinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, link.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(link.icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  link.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
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

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Shows a modern, animated "Log out?" confirmation dialog.
/// Returns `true` if the user confirmed, `false`/`null` otherwise.
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
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
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
              decoration: BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Log out?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
                        side: BorderSide(color: AppColors.border, width: 1.4),
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
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.1),
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