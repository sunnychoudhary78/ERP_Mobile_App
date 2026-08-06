import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InventorySalesScreen extends StatelessWidget {
  const InventorySalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Industrial ERP'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined, size: 28),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'CRM & Sales Hub',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time performance and quick actions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 18),

          // Dynamic Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: const [
              _StatTile(
                title: "TODAY'S SALES",
                value: '\$42,500',
                subtext: '+12% vs ytd',
                isPositive: true,
              ),
              _StatTile(
                title: 'NEW LEADS',
                value: '18',
                subtext: '-3% vs ytd',
                isPositive: false,
              ),
              _StatTile(
                title: 'OPEN QUOTES',
                value: '\$128k',
                subtext: '24 Pending',
                isNeutral: true,
              ),
              _StatTile(
                title: 'WIN RATE',
                value: '64%',
                subtext: '+2.1% (30d)',
                isPositive: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sub-links List
          _buildCrmTile(context, 'Leads', 'Manage incoming prospects', Icons.person_add_outlined, '/crm/leads'),
          _buildCrmTile(context, 'Pipeline', 'Track deal stages', Icons.view_kanban_outlined, '/crm/pipeline'),
          _buildCrmTile(context, 'Customers', 'View active accounts', Icons.groups_outlined, '/crm/customers'),
          _buildCrmTile(context, 'Quotations', 'Draft and send quotes', Icons.request_quote_outlined, '/crm/quotes'),
          _buildCrmTile(context, 'Orders', 'Process closed deals', Icons.shopping_cart_outlined, '/work-orders'),
          _buildCrmTile(context, 'Sales Reports', 'Analyze performance', Icons.bar_chart_outlined, '/crm/activities'),
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