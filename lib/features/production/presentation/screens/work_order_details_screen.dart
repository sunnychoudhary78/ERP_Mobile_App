import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import 'work_order_execution_screen.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workOrderDetailProvider(workOrderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Work Order Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Failed to load work order\n$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(workOrderDetailProvider(workOrderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (wo) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(workOrderDetailProvider(workOrderId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // 1. Top Header Card
              _HeaderCard(wo: wo),
              const SizedBox(height: 14),

              // 2. Item & Quantity Card
              _CardWrapper(
                children: [
                  _DetailFieldLabel('ITEM'),
                  const SizedBox(height: 4),
                  Text(
                    wo.itemName ?? '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailFieldLabel('QUANTITY'),
                  const SizedBox(height: 4),
                  Text(
                    '${wo.quantity ?? 0} units',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Warehouse & Factory Card
              _CardWrapper(
                children: [
                  _IconLabelRow(
                    icon: Icons.storefront_outlined,
                    label: 'WAREHOUSE',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wo.warehouse ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IconLabelRow(
                    icon: Icons.precision_manufacturing_outlined,
                    label: 'FACTORY',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wo.factoryName ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Production Stages Card
              _CardWrapper(
                children: [
                  const Text(
                    'Production Stages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE0E0E0), height: 1),
                  const SizedBox(height: 12),
                  if (wo.stages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No stages available',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    ...wo.stages.map((stage) => _StageItemCard(stage: stage)),
                ],
              ),
              const SizedBox(height: 14),

              // 5. Execution Logs Card
              _CardWrapper(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Execution Logs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Machine: ${wo.execution?.machine ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((wo.execution?.logs ?? []).isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD0D0D0),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No execution logs yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...wo.execution!.logs
                        .map((log) => _ExecutionLogRow(log: log)),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Order Info Card
              _CardWrapper(
                children: [
                  const Text(
                    'Order Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE0E0E0), height: 1),
                  const SizedBox(height: 12),
                  _IconLabelRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'DUE DATE',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wo.dueDate ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _IconLabelRow(
                    icon: Icons.priority_high_rounded,
                    label: 'PRIORITY',
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAEA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (wo.priority ?? 'HIGH').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _IconLabelRow(
                    icon: Icons.folder_open_outlined,
                    label: 'SOURCE',
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        wo.sourceType ?? 'sales_order',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _IconLabelRow(
                    icon: Icons.person_outline_rounded,
                    label: 'CUSTOMER',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wo.customerName ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
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

class _HeaderCard extends StatelessWidget {
  final WorkOrder wo;

  const _HeaderCard({required this.wo});

  @override
  Widget build(BuildContext context) {
    final woTitle = wo.woNumber?.isNotEmpty == true
        ? wo.woNumber!
        : 'WO-${wo.id.padLeft(5, '0')}';

    return _CardWrapper(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              woTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkOrderExecutionScreen(workOrderId: wo.id),
                  ),
                );
              },
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Start\nProduction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (wo.status ?? 'DEMAND_OPEN').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active Step: ${wo.activeStep ?? 'demand'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StageItemCard extends StatelessWidget {
  final WorkOrderStage stage;

  const _StageItemCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(
            stage.completed ? Icons.check_circle : Icons.check_circle_outlined,
            color: stage.completed ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  stage.completed ? 'Completed' : 'Pending',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Out    Scrap',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${stage.outputQty}           ${stage.scrapQty}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final List<Widget> children;

  const _CardWrapper({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailFieldLabel extends StatelessWidget {
  final String label;

  const _DetailFieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _IconLabelRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconLabelRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black87),
        const SizedBox(width: 6),
        _DetailFieldLabel(label),
      ],
    );
  }
}

class _ExecutionLogRow extends StatelessWidget {
  final ExecutionLog log;

  const _ExecutionLogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.note,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${log.operator} · ${log.timestamp} · Out: ${log.outputQty} Scrap: ${log.scrapQty}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}