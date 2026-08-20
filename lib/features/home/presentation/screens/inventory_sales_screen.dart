import 'dart:math';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';

class InventorySalesScreen extends ConsumerWidget {
  const InventorySalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return PermissionGate(
      anyOf: AppPermissions.inventoryModule,
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: const Text(
          'Inventory Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // SafeArea added here to respect system gesture bars
      body: SafeArea(
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            await ref.read(dashboardStatsProvider.future);
          },
          child: statsAsync.when(
            data: (stats) => _DashboardBody(stats: stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 120),
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(dashboardStatsProvider),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final InventoryDashboardStats stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final canStock = auth.canAny(AppPermissions.stockLookup);
    final canLowStock = auth.canAny(AppPermissions.lowStock);
    // Dynamic bottom padding ensures bottom cards never collide with system navigation bar
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 32, // Extra safety margin added
      ),
      children: [
        // 1. Stock Distribution Card
        if (stats.topProductsByStock.isNotEmpty) ...[
          _SectionCard(
            title: 'Stock Distribution',
            child: _StockDistributionSection(
              products: stats.topProductsByStock,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Business Overview Section
        _SectionCard(
          title: 'Business Overview',
          child: _BusinessOverviewGrid(stats: stats),
        ),
        const SizedBox(height: 16),

        // 3. Stock Movement Card
        _SectionCard(
          title: 'Stock Movement',
          trailingText: 'Last 30 days',
          child: _StockMovementSection(
            movementIn: stats.movementIn30d,
            movementOut: stats.movementOut30d,
          ),
        ),
        const SizedBox(height: 16),

        // 4. Top Products Card
        if (stats.topProductsByStock.isNotEmpty) ...[
          _SectionCard(
            title: 'Top Products',
            child: _TopProductsList(products: stats.topProductsByStock),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Stock & Low Stock Grid Cards
        if (canStock || canLowStock)
          Row(
            children: [
              if (canStock)
                const Expanded(
                  child: _QuickLinkGridCard(
                    title: 'Stock',
                    subtitle: 'Search items & warehouse stock',
                    icon: Icons.inventory_2_rounded,
                    iconBgColor: Color(0xFFEEECFD),
                    iconColor: Color(0xFF6C5CE7),
                    route: '/stock-lookup',
                  ),
                ),
              if (canStock && canLowStock) const SizedBox(width: 12),
              if (canLowStock)
                const Expanded(
                  child: _QuickLinkGridCard(
                    title: 'Low Stock',
                    subtitle: 'Items below reorder level',
                    icon: Icons.warning_rounded,
                    iconBgColor: Color(0xFFFFF3E0),
                    iconColor: Color(0xFFFF9800),
                    route: '/low-stock',
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _fmt(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd <= 3) continue;
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
    }
    return buf.toString();
  }
}

// ═══════════════════════════ Base Section Card ═══════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingText;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailingText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════ Quick Link Grid Tile ═══════════════════════════

class _QuickLinkGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String route;

  const _QuickLinkGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFF2F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ Stock Distribution Donut ═══════════════════════════

class _StockDistributionSection extends StatelessWidget {
  final List<TopProduct> products;

  const _StockDistributionSection({required this.products});

  static const List<Color> _chartColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFF00B894),
    Color(0xFFFDCB6E),
    Color(0xFFE84393),
    Color(0xFFFF7675),
  ];

  @override
  Widget build(BuildContext context) {
    final topItems = products.take(4).toList();
    final totalStock = topItems.fold<int>(0, (sum, p) => sum + p.currentStock);

    return Row(
      children: [
        SizedBox(
          height: 110,
          width: 110,
          child: CustomPaint(
            painter: _DonutChartPainter(
              items: topItems,
              total: totalStock == 0 ? 1 : totalStock,
              colors: _chartColors,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(topItems.length, (index) {
              final item = topItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _chartColors[index % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.name} (${item.currentStock})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<TopProduct> items;
  final int total;
  final List<Color> colors;

  _DonutChartPainter({
    required this.items,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (int i = 0; i < items.length; i++) {
      final sweepAngle = (items[i].currentStock / total) * 2 * pi;
      paint.color = colors[i % colors.length];

      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════ Business Overview Grid ═══════════════════════════

class _BusinessOverviewGrid extends StatelessWidget {
  final InventoryDashboardStats stats;

  const _BusinessOverviewGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Structured data with icons and custom accent colors
    final items = [
      {
        'title': 'REVENUE',
        'value': '₹${_DashboardBody._fmt(stats.revenue)}',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF2ECC71),
      },
      {
        'title': 'ORDERS',
        'value': '${stats.ordersCount}',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFF6C5CE7),
      },
      {
        'title': 'CUSTOMERS',
        'value': '${stats.customersCount}',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF00CEC9),
      },
      {
        'title': 'VENDORS',
        'value': '${stats.vendorsCount}',
        'icon': Icons.store_rounded,
        'color': const Color(0xFFE67E22),
      },
      {
        'title': 'PURCHASES',
        'value': '${stats.purchasesCount}',
        'sub': '₹${_DashboardBody._fmt(stats.purchasesAmount)}',
        'icon': Icons.shopping_cart_rounded,
        'color': const Color(0xFFE74C3C),
      },
      {
        'title': 'INVOICES',
        'value': '${stats.invoiceSummary.count}',
        'sub': '₹${_DashboardBody._fmt(stats.invoiceSummary.amount)}',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF3498DB),
      },
      {
        'title': 'BILLS',
        'value': '${stats.billSummary.count}',
        'sub': '₹${_DashboardBody._fmt(stats.billSummary.amount)}',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF9B59B6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 Columns make cards wide and readable
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.1, // Adjusts height/length of boxes properly
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color itemColor = item['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDF1F7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(item['icon'] as IconData, size: 16, color: itemColor),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (item.containsKey('sub')) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════ Stock Movement Section ═══════════════════════════

class _StockMovementSection extends StatelessWidget {
  final int movementIn;
  final int movementOut;

  const _StockMovementSection({
    required this.movementIn,
    required this.movementOut,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = max(movementIn, movementOut) == 0
        ? 1
        : max(movementIn, movementOut);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MovementProgress(
                label: 'STOCK IN',
                value: '$movementIn units',
                color: const Color(0xFF2ECC71),
                progress: movementIn / maxVal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MovementProgress(
                label: 'STOCK OUT',
                value: '$movementOut units',
                color: const Color(0xFFE74C3C),
                progress: movementOut / maxVal,
              ),
            ),
            ],
          ),
      ],
    );
  }

  static String _fmt(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd <= 3) continue;
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buf.write(',');
    }
    return buf.toString();
  }
}

class _MovementProgress extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _MovementProgress({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.05, 1.0),
            backgroundColor: const Color(0xFFF0F3F8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════ Top Products List Section ═══════════════════════════

class _TopProductsList extends StatelessWidget {
  final List<TopProduct> products;

  const _TopProductsList({required this.products});

  static const List<Color> _lineColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFF00B894),
    Color(0xFFFDCB6E),
    Color(0xFFE84393),
    Color(0xFFA29BFE),
  ];

  @override
  Widget build(BuildContext context) {
    final topList = products.take(6).toList();
    final maxStock = topList
        .map((p) => p.currentStock)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(topList.length, (index) {
        final product = topList[index];
        final fraction = (product.currentStock / maxStock).clamp(0.05, 1.0);
        final color = _lineColors[index % _lineColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${product.currentStock} units',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: const Color(0xFFF0F3F8),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
