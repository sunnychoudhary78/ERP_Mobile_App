import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/production_service_provider.dart';
import 'package:erp_app/features/production/presentation/screens/work_orders_screen.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: adjust these import paths to match your actual folder structure.

/// Visual language for this screen (matches the reference "Vuexy" card
/// dashboard): white rounded cards on a soft grey scaffold, each stat
/// carries a colored icon "badge" (soft tint background, solid icon),
/// generous corner radius, very light shadow — no borders, no gradients.
class _KpiSpec {
  final String label;
  final int Function(ProductionSummary) value;
  final IconData icon;
  final Color color;
  final String? status; // lifecycleStatus to filter the list by on tap

  const _KpiSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.status,
  });
}

const _kpis = <_KpiSpec>[
  _KpiSpec(
    label: 'Open Demand',
    value: _demandOpen,
    icon: Icons.inbox_rounded,
    color: Color(0xFF7367F0), // purple
    status: 'DEMAND_OPEN',
  ),
  _KpiSpec(
    label: 'Planned',
    value: _planned,
    icon: Icons.event_note_rounded,
    color: Color(0xFF00CFE8), // cyan
    status: 'PLANNED',
  ),
  _KpiSpec(
    label: 'Material Shortage',
    value: _shortage,
    icon: Icons.warning_rounded,
    color: Color(0xFFFF9F43), // amber
    status: 'SHORTAGE',
  ),
  _KpiSpec(
    label: 'Released',
    value: _released,
    icon: Icons.send_rounded,
    color: Color(0xFF28C76F), // green
    status: 'RELEASED',
  ),
  _KpiSpec(
    label: 'In Production',
    value: _inProduction,
    icon: Icons.precision_manufacturing_rounded,
    color: Color(0xFF28C76F), // green
    status: 'IN_PROCESS',
  ),
  _KpiSpec(
    label: 'QC Hold',
    value: _qcHold,
    icon: Icons.pause_circle_filled_rounded,
    color: Color(0xFFEA5455), // red
    status: 'QC_HOLD',
  ),
  _KpiSpec(
    label: 'Completed',
    value: _completed,
    icon: Icons.check_circle_rounded,
    color: Color(0xFF82868B), // grey
    status: 'COMPLETED',
  ),
  _KpiSpec(
    label: 'Pending Approvals',
    value: _pendingApprovals,
    icon: Icons.hourglass_top_rounded,
    color: Color(0xFFFF9F43), // amber
    status: null,
  ),
];

int _demandOpen(ProductionSummary s) => s.demandOpen;
int _planned(ProductionSummary s) => s.planned;
int _shortage(ProductionSummary s) => s.shortage;
int _released(ProductionSummary s) => s.released;
int _inProduction(ProductionSummary s) => s.inProduction;
int _qcHold(ProductionSummary s) => s.qcHold;
int _completed(ProductionSummary s) => s.completed;
int _pendingApprovals(ProductionSummary s) => s.pendingApprovals;

class ProductionDashboardScreen extends ConsumerStatefulWidget {
  const ProductionDashboardScreen({super.key});

  @override
  ConsumerState<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState
    extends ConsumerState<ProductionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productionSummaryProvider.notifier).fetch();
    });
  }

  Future<void> _onRefresh() {
    return ref.read(productionSummaryProvider.notifier).fetch(force: true);
  }

  void _openList({String? status}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // ADAPT: wire `status` into WorkOrdersScreen's actual filter param.
        builder: (_) => WorkOrdersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productionSummaryProvider);
    final s = state.summary;
    const bg = Color(0xFFF8F7FA); // Vuexy-style soft grey scaffold

    return PermissionGate(
      anyOf: AppPermissions.productionModule,
      child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Production Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: bg,
        foregroundColor: const Color(0xFF3D3B54),
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: state.isLoading && state.fetchedAt == null
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.fetchedAt == null
                ? _ErrorState(message: state.error!, onRetry: _onRefresh)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "Couldn't refresh — showing last loaded data.",
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      _HeroCard(
                        total: s.total,
                        openApprox: s.openApprox,
                        onTap: () => _openList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By stage',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kpis.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                        itemBuilder: (context, i) {
                          final k = _kpis[i];
                          return _IconStatCard(
                            spec: k,
                            value: k.value(s),
                            onTap: () => _openList(status: k.status),
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

/// Top hero card — total work orders. Rounded, soft-tinted, no border,
/// mirrors the reference's top "Statistics" banner but scoped to data we
/// actually have (no fake revenue/growth numbers).
class _HeroCard extends StatelessWidget {
  final int total;
  final int openApprox;
  final VoidCallback onTap;

  const _HeroCard({
    required this.total,
    required this.openApprox,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7367F0).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Color(0xFF7367F0),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3D3B54),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total work orders  ·  ~$openApprox open',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// Reference-style icon-badge stat card: colored rounded-square icon on
/// top, big number, muted label below.
class _IconStatCard extends StatelessWidget {
  final _KpiSpec spec;
  final int value;
  final VoidCallback onTap;

  const _IconStatCard({
    required this.spec,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: spec.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(spec.icon, color: spec.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D3B54),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              "Couldn't load the dashboard.\n$message",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}