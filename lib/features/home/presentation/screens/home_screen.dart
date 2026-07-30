import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _links = <_QuickLink>[
    _QuickLink('Punch', '/punch', Icons.fingerprint),
    _QuickLink('Leave balance', '/leave-balance', Icons.beach_access_outlined),
    _QuickLink('Apply leave', '/leave-apply', Icons.event_available_outlined),
    _QuickLink('My leave', '/leave-status', Icons.list_alt_outlined),
    _QuickLink('Approvals', '/approvals', Icons.approval_outlined),
    _QuickLink('Notifications', '/notifications', Icons.notifications_outlined),
    _QuickLink('Leads', '/crm/leads', Icons.leaderboard_outlined),
    _QuickLink('Contacts', '/crm/contacts', Icons.contacts_outlined),
    _QuickLink('Customers', '/crm/customers', Icons.business_outlined),
    _QuickLink('Pipeline', '/crm/pipeline', Icons.view_kanban_outlined),
    _QuickLink('Activities', '/crm/activities', Icons.timeline_outlined),
    _QuickLink('Quotes', '/crm/quotes', Icons.request_quote_outlined),
    _QuickLink('Visits', '/crm/visits', Icons.location_on_outlined),
    _QuickLink('Team tracking', '/crm/tracking', Icons.map_outlined),
    _QuickLink('Stock lookup', '/stock-lookup', Icons.inventory_2_outlined),
    _QuickLink('Work orders', '/work-orders', Icons.precision_manufacturing_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).profile;
    final name = profile?.associatesName?.split(' ').first ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Hi, $name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Must features — stubs ready for juniors to implement one by one.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 16),
          _StatusCard(
            title: 'Today punch',
            value: '—',
            hint: 'Wire attendance summary here',
          ),
          const SizedBox(height: 10),
          _StatusCard(
            title: 'Pending approvals',
            value: '—',
            hint: 'Wire approvals count here',
          ),
          const SizedBox(height: 10),
          _StatusCard(
            title: 'Low stock alerts',
            value: '—',
            hint: 'Wire inventory/low-stock count here',
          ),
          const SizedBox(height: 22),
          Text(
            'Quick links',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ..._links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(context, link.route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(link.icon, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            link.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLink {
  final String label;
  final String route;
  final IconData icon;

  const _QuickLink(this.label, this.route, this.icon);
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
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
                ),
          ),
        ],
      ),
    );
  }
}
