import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class CrmMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accentColor;
  final String? badge;

  const CrmMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accentColor,
    this.badge,
  });
}

final crmMenuItemsProvider = Provider<List<CrmMenuItem>>((ref) {
  return const [
    CrmMenuItem(
      title: 'Leads',
      subtitle: 'Manage incoming prospects',
      icon: Icons.leaderboard_outlined,
      route: '/crm/leads',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Pipeline',
      subtitle: 'Track deal stages',
      icon: Icons.view_kanban_outlined,
      route: '/crm/pipeline',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Follow-ups',
      subtitle: 'Activities & timeline',
      icon: Icons.timeline_outlined,
      route: '/crm/activities',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Approvals',
      subtitle: 'Pending requests',
      icon: Icons.fact_check_outlined,
      route: '/crm/approvals',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Contacts',
      subtitle: 'Manage clients & leads',
      icon: Icons.contacts_outlined,
      route: '/crm/contacts',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Customers',
      subtitle: 'Active accounts overview',
      icon: Icons.business_outlined,
      route: '/crm/customers',
      accentColor: AppColors.primary,
    ),
    CrmMenuItem(
      title: 'Quotes',
      subtitle: 'Draft & send proposals',
      icon: Icons.request_quote_outlined,
      route: '/crm/quotes',
      accentColor: AppColors.primary,
    ),
  ];
});

// --- SCREEN IMPLEMENTATION ---
class CrmSalesScreen extends ConsumerWidget {
  const CrmSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(crmMenuItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Sales CRM'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(crmMenuItemsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Modern Module Grid for required modules
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _CrmGridCard(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODULE GRID CARD UI ---
class _CrmGridCard extends StatelessWidget {
  final CrmMenuItem item;

  const _CrmGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, item.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.accentColor, size: 22),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          color: item.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- STATS TILE UI ---
class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final bool isPositive;
  final bool isNeutral;

  const _StatTile({
    required this.title,
    required this.value,
    required this.subtext,
    this.isPositive = true,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    Color subColor = isNeutral
        ? AppColors.muted
        : (isPositive ? AppColors.success : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (!isNeutral)
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: subColor,
                ),
              if (!isNeutral) const SizedBox(width: 4),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
