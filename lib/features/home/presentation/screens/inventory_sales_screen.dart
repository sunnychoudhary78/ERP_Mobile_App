import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';


class InventorySalesScreen extends ConsumerWidget {
  const InventorySalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 18),

          // Dynamic Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              // Live data — replaces nothing, appended
              statsAsync.when(
                data: (stats) => _StatTile(
                  title: 'LOW STOCK',
                  value: '${stats.lowStockCount}',
                  subtext: '${stats.itemsCount} items tracked',
                  isNeutral: stats.lowStockCount == 0,
                  isPositive: false,
                  onTap: () => Navigator.pushNamed(context, '/low-stock'),
                ),
                loading: () => const _StatTile(
                  title: 'LOW STOCK',
                  value: '—',
                  subtext: 'Loading...',
                  isNeutral: true,
                ),
                error: (e, _) => _StatTile(
                  title: 'LOW STOCK',
                  value: '—',
                  subtext: 'Unavailable',
                  isNeutral: true,
                  onTap: () => ref.invalidate(dashboardStatsProvider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sub-links List
          _buildCrmTile(context, 'Stock', 'Manage incoming prospects', Icons.person_add_outlined, '/stock-lookup'),
          _buildCrmTile(context, 'Low Stock', 'Items below reorder level', Icons.warning_amber_outlined, '/low-stock'),
        ],
      ),
    );
  }

  Widget _buildCrmTile(BuildContext context, String title, String subtitle, IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, route),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final bool isPositive;
  final bool isNeutral;
  final VoidCallback? onTap;

  const _StatTile({
    required this.title,
    required this.value,
    required this.subtext,
    this.isPositive = true,
    this.isNeutral = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color subColor = isNeutral
        ? AppColors.muted
        : (isPositive ? AppColors.success : AppColors.danger);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}