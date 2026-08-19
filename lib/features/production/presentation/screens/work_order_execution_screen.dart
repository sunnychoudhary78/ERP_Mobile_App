import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';

class WorkOrderExecutionScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderExecutionScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderExecutionScreen> createState() =>
      _WorkOrderExecutionScreenState();
}

class _WorkOrderExecutionScreenState
    extends ConsumerState<WorkOrderExecutionScreen> {
  final _operatorController = TextEditingController();
  final _machineController = TextEditingController();
  final _noteController = TextEditingController();
  final _outputController = TextEditingController(text: '0');
  final _scrapController = TextEditingController(text: '0');

  // stageCode -> (completed, outputQty controller, scrapQty controller)
  final Map<String, bool> _stageCompleted = {};
  final Map<String, TextEditingController> _stageOutput = {};
  final Map<String, TextEditingController> _stageScrap = {};

  String? _selectedActiveStep;

  bool _initializedFor = false;

  void _initStageControllers(WorkOrder wo) {
    if (_initializedFor) return;
    for (final s in wo.stages) {
      _stageCompleted[s.code] = s.completed;
      _stageOutput[s.code] = TextEditingController(
        text: s.outputQty.toString(),
      );
      _stageScrap[s.code] = TextEditingController(text: s.scrapQty.toString());
    }
    _selectedActiveStep = wo.activeStep;
    _initializedFor = true;
  }

  @override
  void dispose() {
    _operatorController.dispose();
    _machineController.dispose();
    _noteController.dispose();
    _outputController.dispose();
    _scrapController.dispose();
    for (final c in _stageOutput.values) {
      c.dispose();
    }
    for (final c in _stageScrap.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _logExecution() async {
    if (_operatorController.text.trim().isEmpty ||
        _machineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operator aur machine bharo')),
      );
      return;
    }

    final stages = _stageCompleted.keys.map((code) {
      return WorkOrderStage(
        code: code,
        completed: _stageCompleted[code] ?? false,
        outputQty: num.tryParse(_stageOutput[code]?.text ?? '0') ?? 0,
        scrapQty: num.tryParse(_stageScrap[code]?.text ?? '0') ?? 0,
      );
    }).toList();

    final controller = ref.read(workOrderActionsControllerProvider.notifier);
    final ok = await controller.logExecution(
      widget.workOrderId,
      operator: _operatorController.text.trim(),
      machine: _machineController.text.trim(),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'Execution updated',
      outputQty: num.tryParse(_outputController.text) ?? 0,
      scrapQty: num.tryParse(_scrapController.text) ?? 0,
      stages: stages.isNotEmpty ? stages : null,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Execution logged')));
      _noteController.clear();
    } else {
      final err = ref.read(workOrderActionsControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $err')));
    }
  }

  Future<void> _moveStep() async {
    if (_selectedActiveStep == null || _selectedActiveStep!.isEmpty) return;
    final controller = ref.read(workOrderActionsControllerProvider.notifier);
    final ok = await controller.transition(
      widget.workOrderId,
      activeStep: _selectedActiveStep!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Moved to $_selectedActiveStep'
              : 'Failed: ${ref.read(workOrderActionsControllerProvider).error}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(workOrderDetailProvider(widget.workOrderId));
    final actionState = ref.watch(workOrderActionsControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Shop Floor'),
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
          _initStageControllers(wo);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                wo.woNumber?.isNotEmpty == true ? wo.woNumber! : 'WO #${wo.id}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Status: ${wo.status ?? '-'}  ·  Active step: ${wo.activeStep ?? '-'}',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              _Card(
                title: 'Operator & Machine',
                children: [
                  TextField(
                    controller: _operatorController,
                    decoration: const InputDecoration(
                      labelText: 'Operator name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _machineController,
                    decoration: const InputDecoration(
                      labelText: 'Machine / line',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _Card(
                title: 'Output / Scrap (this entry)',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _outputController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Output qty',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _scrapController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Scrap qty',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (e.g. "Started production")',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),

              if (wo.stages.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  title: 'Stages',
                  children: wo.stages.map((s) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _stageCompleted[s.code] ?? false,
                                onChanged: (v) => setState(
                                  () => _stageCompleted[s.code] = v ?? false,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  s.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 44),
                              Expanded(
                                child: TextField(
                                  controller: _stageOutput[s.code],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Output',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _stageScrap[s.code],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Scrap',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _logExecution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Log Execution'),
                ),
              ),

              const SizedBox(height: 20),
              _Card(
                title: 'Move Step',
                children: [
                  Text(
                    'No dedicated /start endpoint — logging execution above '
                    'moves the WO toward IN_PROCESS. Use this to explicitly '
                    'move the active step (e.g. shop-floor → qc → release).',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _selectedActiveStep,
                    decoration: const InputDecoration(
                      labelText: 'Active step',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'demand', child: Text('Demand')),
                      DropdownMenuItem(
                        value: 'shop-floor',
                        child: Text('Shop Floor'),
                      ),
                      DropdownMenuItem(value: 'qc', child: Text('QC')),
                      DropdownMenuItem(
                        value: 'release',
                        child: Text('Release'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedActiveStep = v;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _moveStep,
                      child: const Text('Move Step'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
