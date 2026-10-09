import 'dart:math';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_app/features/inventory/shared/data/models/dashboard_stats_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';

// ═══════════════════════════ Design tokens ═══════════════════════════

const Color _kBg = Color(0xFFF5F7FB);
const Color _kNavy = Color(0xFF0F1B3D);
const Color _kMuted = Color(0xFF6B7487);
const Color _kBorder = Color(0xFFEBEEF5);
const Color _kOrange = Color(0xFFFF7A1A);
const Color _kOrangeSoft = Color(0xFFFFEBD9);

String _unitLabel(String unit) {
  final normalized = unit.trim();
  return normalized.isEmpty ? 'Units' : normalized;
}

class InventorySalesScreen extends ConsumerWidget {
  const InventorySalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final auth = ref.watch(authProvider);

    return PermissionGate(
      anyOf: AppPermissions.inventoryModule,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _kNavy),
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: EdgeInsets.only(
              left: Navigator.of(context).canPop() ? 0 : 16,
            ),
            child: const Text(
              'Inventory Dashboard',
              style: TextStyle(
                color: _kNavy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // actions: [
          //   _AppBarBell(onTap: () {
          //     // TODO: open notifications screen when available
          //   }),
          //   const SizedBox(width: 10),
          //   _AppBarAvatar(initials: _initialsFrom(auth)),
          //   const SizedBox(width: 16),
          // ],
        ),
        body: SafeArea(
          bottom: true,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(financialReportProvider('12'));
              await Future.wait([
                ref.read(dashboardStatsProvider.future),
                ref.read(financialReportProvider('12').future),
              ]);
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

  /// Builds initials (e.g. "SP") from the logged-in user's name.
  /// Uses dynamic access inside try/catch so it works whatever the
  /// user model's field is called; falls back to "U".
  static String _initialsFrom(dynamic auth) {
    String? attempt(String? Function() f) {
      try {
        final v = f();
        return (v == null || v.trim().isEmpty) ? null : v.trim();
      } catch (_) {
        return null;
      }
    }

    final name =
        attempt(() => (auth as dynamic).user?.name?.toString()) ??
        attempt(() => (auth as dynamic).user?.fullName?.toString()) ??
        attempt(() => (auth as dynamic).user?.username?.toString()) ??
        attempt(() => (auth as dynamic).name?.toString());

    if (name == null) return 'U';
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _DashboardBody extends ConsumerWidget {
  final InventoryDashboardStats stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final financialAsync = ref.watch(financialReportProvider('12'));
    final canStock = auth.canAny(AppPermissions.stockLookup);
    final canLowStock = auth.canAny(AppPermissions.lowStock);
    final canInventoryOperations = auth.canAny(
      AppPermissions.inventoryOperations,
    );
    final canPurchaseReceived = auth.canAny(AppPermissions.purchaseReceived);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottomInset + 32,
      ),
      children: [
        financialAsync.when(
          data: (report) => _FinancialSummaryCards(data: report.raw),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _FinancialSummaryError(
            onRetry: () => ref.invalidate(financialReportProvider('12')),
          ),
        ),
        const SizedBox(height: 16),

        // Quick links
        if (canInventoryOperations || canPurchaseReceived) ...[
          _InventoryQuickLinks(
            canInventoryOperations: canInventoryOperations,
            canPurchaseReceived: canPurchaseReceived,
          ),
          const SizedBox(height: 16),
        ],

        // Stock Distribution
        if (stats.topProductsByStock.isNotEmpty) ...[
          _SectionCard(
            title: 'Stock Distribution',
            onTap: canStock
                ? () => Navigator.pushNamed(context, '/stock-lookup')
                : null,
            child: _StockDistributionSection(
              products: stats.topProductsByStock,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Business Overview
        _SectionCard(
          title: 'Business Overview',
          onTap: canInventoryOperations
              ? () => Navigator.pushNamed(context, '/inventory/reports/pl')
              : null,
          child: _BusinessOverviewGrid(stats: stats),
        ),
        const SizedBox(height: 16),

        // Stock Movement
        _SectionCard(
          title: 'Stock Movement',
          trailingText: 'Last 30 days',
          child: _StockMovementSection(
            movementIn: stats.movementIn30d,
            movementOut: stats.movementOut30d,
          ),
        ),
        const SizedBox(height: 16),

        // Top Products
        if (stats.topProductsByStock.isNotEmpty) ...[
          _SectionCard(
            title: 'Top Products',
            child: _TopProductsList(products: stats.topProductsByStock),
          ),
          const SizedBox(height: 16),
        ],

        // Stock & Low Stock cards
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

// ═══════════════════════════ Financial Summary Cards ═══════════════════════════

class _FinCardData {
  final String title;
  final String value;
  final String line1;
  final String line2;
  final Color tintTop;
  final Color tintBottom;
  final Color accent;
  final IconData icon;
  final IconData trailingIcon;

  const _FinCardData({
    required this.title,
    required this.value,
    required this.line1,
    required this.line2,
    required this.tintTop,
    required this.tintBottom,
    required this.accent,
    required this.icon,
    required this.trailingIcon,
  });
}

class _FinancialSummaryCards extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FinancialSummaryCards({required this.data});

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String _money(dynamic value) {
    final amount = value is num ? value : num.tryParse('$value');
    return amount == null ? '—' : _currency.format(amount);
  }

  static String _count(dynamic value) => value?.toString() ?? '0';

  @override
  Widget build(BuildContext context) {
    final net = data['netProfitEstimate'] is num
        ? data['netProfitEstimate'] as num
        : num.tryParse('${data['netProfitEstimate'] ?? ''}') ?? 0;
    final period = data['period']?.toString().trim();
    final periodLabel = period == null || period.isEmpty
        ? 'Last 12 months'
        : period;

    final cards = <_FinCardData>[
      _FinCardData(
        title: 'Spent on purchases',
        value: _money(data['purchaseCost']),
        line1: '${_count(data['purchaseCount'])} received orders',
        line2: periodLabel,
        tintTop: const Color(0xFFFFF1E2),
        tintBottom: const Color(0xFFFFF8F1),
        accent: const Color(0xFFFF7A1A),
        icon: Icons.shopping_cart_outlined,
        trailingIcon: Icons.trending_up_rounded,
      ),
      _FinCardData(
        title: 'Sales (stock out)',
        value: _money(data['stockOutSubtotal']),
        line1: '${_count(data['stockOutBillCount'])} bills · before GST',
        line2: periodLabel,
        tintTop: const Color(0xFFECEEFF),
        tintBottom: const Color(0xFFF5F6FF),
        accent: const Color(0xFF5B4BE0),
        icon: Icons.storefront_rounded,
        trailingIcon: Icons.trending_up_rounded,
      ),
      _FinCardData(
        title: 'Profit estimate',
        value: _money(data['netProfitEstimate']),
        line1: net >= 0 ? 'Earned more than spent' : 'Spent more than earned',
        line2: periodLabel,
        tintTop: const Color(0xFFE3F7EC),
        tintBottom: const Color(0xFFF1FBF6),
        accent: const Color(0xFF16A864),
        icon: Icons.trending_up_rounded,
        trailingIcon: Icons.trending_up_rounded,
      ),
      _FinCardData(
        title: 'Stock value',
        value: _money(data['inventoryValueAtCost']),
        line1: 'At cost',
        line2: 'Wholesale ${_money(data['inventoryValueAtB2b'])}',
        tintTop: const Color(0xFFE6F1FF),
        tintBottom: const Color(0xFFF3F8FF),
        accent: const Color(0xFF2F7BEA),
        icon: Icons.view_in_ar_rounded,
        trailingIcon: Icons.view_in_ar_outlined,
      ),
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 168 * max(1.0, textScale),
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _FinCard(card: cards[index]),
    );
  }
}

class _FinCard extends StatelessWidget {
  final _FinCardData card;

  const _FinCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card.tintTop, card.tintBottom],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: card.accent.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: card.accent.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Icon(card.icon, size: 20, color: card.accent),
              ),
              const Spacer(),
              Icon(card.trailingIcon, size: 20, color: card.accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              card.value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _kNavy,
              ),
            ),
          ),
          const Spacer(),
          Text(
            card.line1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
          const SizedBox(height: 2),
          Text(
            card.line2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _FinancialSummaryError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: const Text('Financial summary unavailable'),
      trailing: IconButton(
        tooltip: 'Retry',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
}

// ═══════════════════════════ Quick Links ═══════════════════════════

class _InventoryQuickLinks extends StatelessWidget {
  final bool canInventoryOperations;
  final bool canPurchaseReceived;

  const _InventoryQuickLinks({
    required this.canInventoryOperations,
    required this.canPurchaseReceived,
  });

  @override
  Widget build(BuildContext context) {
    final links = <({String label, IconData icon, String route})>[
      if (canInventoryOperations)
        (
          label: 'Cost & P/L',
          icon: Icons.bar_chart_rounded,
          route: '/inventory/reports/pl',
        ),
      if (canInventoryOperations)
        (
          label: 'Movement Ledger',
          icon: Icons.description_outlined,
          route: '/inventory/ledger',
        ),
      if (canPurchaseReceived)
        (
          label: 'Purchase Received',
          icon: Icons.local_shipping_outlined,
          route: '/purchase-received',
        ),
      if (canInventoryOperations)
        (
          label: 'Stock OUT Bills',
          icon: Icons.receipt_long_outlined,
          route: '/inventory/stock',
        ),
    ];

    return _SectionCard(
      title: 'Quick links',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final tileWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final l in links)
                SizedBox(
                  width: tileWidth,
                  child: _QuickLinkTile(
                    label: l.label,
                    icon: l.icon,
                    onTap: () => Navigator.pushNamed(context, l.route),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _kOrangeSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: _kOrange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ Base Section Card ═══════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback?
  onTap; // when set, a chevron is shown and header is tappable
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailingText,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A55).withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: _kNavy,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _kMuted,
                    size: 26,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2A55).withValues(alpha: .04),
              blurRadius: 12,
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _kMuted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ Stock Distribution Donut ═══════════════════════════

const List<Color> _kChartColors = [
  Color(0xFF6C5CE7), // purple
  Color(0xFF1FC8BE), // teal
  Color(0xFFFF8A1F), // orange
  Color(0xFFFFC95C), // yellow
  Color(0xFFE84393),
  Color(0xFFFF7675),
];

class _StockDistributionSection extends StatelessWidget {
  final List<TopProduct> products;

  const _StockDistributionSection({required this.products});

  @override
  Widget build(BuildContext context) {
    final topItems = products.take(4).toList();
    final totalStock = topItems.fold<int>(0, (sum, p) => sum + p.currentStock);
    final units = topItems.map((product) => _unitLabel(product.unit)).toSet();
    final totalUnit = units.length == 1 ? units.single : 'Mixed units';

    return Row(
      children: [
        SizedBox(
          height: 130,
          width: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(130, 130),
                painter: _DonutChartPainter(
                  items: topItems,
                  total: totalStock == 0 ? 1 : totalStock,
                  colors: _kChartColors,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 13, color: _kMuted),
                  ),
                  Text(
                    '$totalStock',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                  Text(
                    totalUnit,
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(topItems.length, (index) {
              final item = topItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _kChartColors[index % _kChartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.name} (${item.currentStock} ${_unitLabel(item.unit)})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _kNavy,
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
    const strokeWidth = 24.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Soft background ring (shows when there is no stock)
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      paint..color = const Color(0xFFF0F3F8),
    );

    const gap = 0.04;
    double startAngle = -pi / 2;

    for (int i = 0; i < items.length; i++) {
      final sweepAngle = (items[i].currentStock / total) * 2 * pi;
      if (sweepAngle <= 0) continue;
      paint.color = colors[i % colors.length];
      final drawSweep = items.length > 1
          ? max(0.0, sweepAngle - gap)
          : sweepAngle;
      canvas.drawArc(rect, startAngle + gap / 2, drawSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.total != total || old.items != items;
}

// ═══════════════════════════ Business Overview Grid ═══════════════════════════

class _BusinessOverviewGrid extends StatelessWidget {
  final InventoryDashboardStats stats;

  const _BusinessOverviewGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[
      {
        'title': 'REVENUE',
        'value': '₹${_DashboardBody._fmt(stats.revenue)}',
        'icon': Icons.currency_rupee_rounded,
        'color': const Color(0xFF16A864),
        'trend': Icons.trending_up_rounded,
      },
      {
        'title': 'ORDERS',
        'value': '${stats.ordersCount}',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFF7C4DDB),
        'trend': Icons.trending_up_rounded,
      },
      {
        'title': 'CUSTOMERS',
        'value': '${stats.customersCount}',
        'icon': Icons.people_alt_outlined,
        'color': const Color(0xFF1FA9A3),
      },
      {
        'title': 'VENDORS',
        'value': '${stats.vendorsCount}',
        'icon': Icons.store_mall_directory_outlined,
        'color': const Color(0xFFE67E22),
      },
      {
        'title': 'PURCHASES',
        'value': '${stats.purchasesCount}',
        'sub': '₹${_DashboardBody._fmt(stats.purchasesAmount)}',
        'icon': Icons.shopping_cart_outlined,
        'color': const Color(0xFFE74C3C),
      },
      {
        'title': 'INVOICES',
        'value': '${stats.invoiceSummary.count}',
        'sub': '₹${_DashboardBody._fmt(stats.invoiceSummary.amount)}',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF3498DB),
      },
      {
        'title': 'BILLS',
        'value': '${stats.billSummary.count}',
        'sub': '₹${_DashboardBody._fmt(stats.billSummary.amount)}',
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF9B59B6),
      },
    ];

    final textScaler = MediaQuery.textScalerOf(context);
    final cardHeight = max(124.0, textScaler.scale(112));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: cardHeight,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color color = item['color'] as Color;
        final IconData? trend = item['trend'] as IconData?;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  if (trend != null) Icon(trend, size: 18, color: color),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item['value'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                  ),
                  if (item.containsKey('sub'))
                    Text(
                      item['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                      ),
                    ),
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

    return Row(
      children: [
        Expanded(
          child: _MovementProgress(
            label: 'STOCK IN',
            value: '$movementIn units',
            color: const Color(0xFF16A864),
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
    );
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
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.05, 1.0),
            backgroundColor: const Color(0xFFF0F3F8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
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

  @override
  Widget build(BuildContext context) {
    final topList = products.take(6).toList();
    final maxStock = topList
        .map((p) => p.currentStock)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(topList.length, (index) {
        final product = topList[index];
        final qty = product.currentStock;
        final unit = _unitLabel(product.unit);
        final fraction = (qty / maxStock).clamp(0.05, 1.0);
        final color = _kChartColors[index % _kChartColors.length];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == topList.length - 1 ? 0 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$qty $unit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: const Color(0xFFF0F3F8),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
