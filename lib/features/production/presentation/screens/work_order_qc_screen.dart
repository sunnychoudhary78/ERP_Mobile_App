import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
/// Screen 4 — QC / Completion.
///
/// Backend notes (from doc):
/// - POST /:id/qc with { hold: true } is QC hold ONLY — not a generic
///   shop-floor pause (there is no shop-floor hold/resume API).
/// - POST /:id/complete may issue materials + post FG and does NOT enforce
///   prior QC — prefer /:id/finish-from-qc when the WO has gone through QC.
class WorkOrderQcScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderQcScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderQcScreen> createState() => _WorkOrderQcScreenState();
}

class _WorkOrderQcScreenState extends ConsumerState<WorkOrderQcScreen> {
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveRemarkIfAny(WorkOrderActionsController controller) async {
    final remark = _remarkController.text.trim();
    if (remark.isEmpty) return;
    await controller.overwriteNotes(widget.workOrderId, notes: remark);
    _remarkController.clear();
  }

  Future<void> _setQcHold(bool hold) async {
    final controller = ref.read(workOrderActionsControllerProvider.notifier);
    final ok = await controller.setQcHold(widget.workOrderId, hold: hold);
    if (ok) await _saveRemarkIfAny(controller);
    _showResult(ok, hold ? 'QC hold set' : 'QC hold released');
  }

  Future<void> _finishFromQc() async {
    final controller = ref.read(workOrderActionsControllerProvider.notifier);
    final ok = await controller.finishFromQc(widget.workOrderId);
    if (ok) await _saveRemarkIfAny(controller);
    _showResult(ok, 'Finished from QC');
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete work order?'),
        content: const Text(
          'This may issue materials and post finished goods. It does NOT '
          'check whether QC has been done. Use "Finish from QC" instead if '
          'this WO should go through QC first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete anyway'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final controller = ref.read(workOrderActionsControllerProvider.notifier);
    final ok = await controller.complete(widget.workOrderId);
    if (ok) await _saveRemarkIfAny(controller);
    _showResult(ok, 'Work order completed');
  }

  void _showResult(bool ok, String successMessage) {
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      final err = ref.read(workOrderActionsControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(workOrderDetailProvider(widget.workOrderId));
    final actionState = ref.watch(workOrderActionsControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('QC / Completion'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            'Failed to load work order\n$err',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        data: (wo) {
          final isQcHold = wo.status?.toUpperCase() == WorkOrderStatus.qcHold;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                wo.woNumber?.isNotEmpty == true
                    ? wo.woNumber!
                    : 'WO #${wo.id}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Current status: ${wo.status ?? '-'}',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QC Hold',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'QC hold only — not a general shop-floor pause.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading || isQcHold
                                ? null
                                : () => _setQcHold(true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: BorderSide(color: AppColors.danger),
                            ),
                            child: const Text('Hold'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading || !isQcHold
                                ? null
                                : () => _setQcHold(false),
                            child: const Text('Release Hold'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remark',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overwrites existing notes (no append-only history API).',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _remarkController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remark (optional, sent with next action)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _finishFromQc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Finish from QC'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _complete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete (skip QC check)'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}