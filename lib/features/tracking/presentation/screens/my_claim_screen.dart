import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_claim_model.dart';
import '../providers/sales_claim_providers.dart';
import '../widgets/claim_common.dart';

/// My claim — `GET /api/sales/claims/my/preview` + `POST .../my/submit`
/// (doc 04 §My claim / §Submit).
class MyClaimScreen extends ConsumerStatefulWidget {
  const MyClaimScreen({super.key});

  @override
  ConsumerState<MyClaimScreen> createState() => _MyClaimScreenState();
}

class _MyClaimScreenState extends ConsumerState<MyClaimScreen> {
  final _userKmController = TextEditingController();
  final _remarksController = TextEditingController();
  final _advanceController = TextEditingController();

  bool _agree = true;
  bool _submitting = false;
  final List<ExtraExpense> _extras = [];

  @override
  void dispose() {
    _userKmController.dispose();
    _remarksController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  double get _extrasTotal =>
      _extras.fold<double>(0, (sum, e) => sum + e.amount);

  Future<void> _addExtra() async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add extra expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Toll, Parking…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final label = labelController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              if (label.isEmpty || amount == null || amount <= 0) return;
              setState(() => _extras.add(
                ExtraExpense(label: label, amount: amount),
              ));
              Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    labelController.dispose();
    amountController.dispose();
    if (result == true) setState(() {});
  }

  Future<void> _submit(ClaimPreview preview) async {
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0;

    if (!_agree) {
      final km = double.tryParse(_userKmController.text.trim());
      if (km == null || km <= 0) {
        _snack('Enter your corrected KM', isError: true);
        return;
      }
      if (_remarksController.text.trim().isEmpty) {
        _snack('Remarks are required when you disagree', isError: true);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final claim = await ref
          .read(claimPreviewProvider.notifier)
          .submit(
            action: _agree ? 'agree' : 'disagree',
            userDistanceKm: _agree
                ? null
                : double.tryParse(_userKmController.text.trim()),
            extraExpenses: _extras,
            advancePaymentAmount: advance,
            remarks: _remarksController.text.trim(),
          );
      _snack('Claim submitted · ${claimStatusLabel(claim.status)}');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(claimPreviewProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My claim'),
        actions: [
          IconButton(
            tooltip: 'Claim history',
            icon: Icon(Icons.history_rounded, color: AppColors.text),
            onPressed: () => Navigator.pushNamed(context, '/claims/history'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.read(claimPreviewProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.read(claimPreviewProvider.notifier).refresh(),
        ),
        data: (preview) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(claimPreviewProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _MonthHeader(monthKey: preview.monthKey),
              const SizedBox(height: 16),
              _SummaryCard(preview: preview),
              const SizedBox(height: 16),
              if (preview.existing != null)
                _ExistingClaimCard(claim: preview.existing!)
              else
                _buildSubmissionForm(preview),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionForm(ClaimPreview preview) {
    final rate = preview.ratePerKm;
    final userKm = double.tryParse(_userKmController.text.trim()) ?? 0;
    final baseKm = _agree ? preview.systemDistanceKm : userKm;
    final amount = baseKm * rate;
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0;
    final net = amount + _extrasTotal - advance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Do you agree with the system distance?',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Agree',
                      selected: _agree,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => setState(() => _agree = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Disagree',
                      selected: !_agree,
                      icon: Icons.cancel_outlined,
                      onTap: () => setState(() => _agree = false),
                    ),
                  ),
                ],
              ),
              if (!_agree) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _userKmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Your distance (KM)',
                    hintText: 'e.g. 910.5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (required)',
                    hintText: 'Odometer shows 910 km. GPS missed 20 Sep.',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Extra expenses (optional)',
          trailing: TextButton.icon(
            onPressed: _addExtra,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
          child: _extras.isEmpty
              ? Text(
                  'No extra expenses added.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                )
              : Column(
                  children: [
                    for (int i = 0; i < _extras.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(_extras[i].label)),
                            Text(claimMoney(_extras[i].amount)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.muted,
                              ),
                              onPressed: () =>
                                  setState(() => _extras.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Advance payment',
          child: TextField(
            controller: _advanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Advance amount (₹)',
              hintText: 'Subtracted from net amount',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NetSummaryCard(
          baseKm: baseKm,
          rate: rate,
          amount: amount,
          extras: _extrasTotal,
          advance: advance,
          net: net,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : () => _submit(preview),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Submitting…' : 'Submit claim'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can submit only once per month.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String monthKey;
  const _MonthHeader({required this.monthKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance claim',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            claimMonthLabel(monthKey),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ClaimPreview preview;
  const _SummaryCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'System summary',
      child: Column(
        children: [
          _row('Vehicle type', claimVehicleLabel(preview.vehicleType)),
          _row('Rate per KM', claimMoney(preview.ratePerKm)),
          _row('System distance', '${claimNum(preview.systemDistanceKm)} KM'),
          _row('Amount', claimMoney(preview.amount), emphasize: true),
          if (preview.settings != null) ...[
            const Divider(height: 24),
            _row('Claim window', preview.settings!.windowLabel),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.pushNamed(
                context,
                '/claims/day-wise',
                arguments: preview.monthKey,
              ),
              icon: const Icon(Icons.calendar_view_day_rounded, size: 18),
              label: const Text('View day-wise KM'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 16 : 14,
              color: emphasize ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingClaimCard extends StatelessWidget {
  final SalesClaim claim;
  const _ExistingClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Submitted claim',
      trailing: ClaimStatusChip(status: claim.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Month', claimMonthLabel(claim.monthKey)),
          _row(
            'System distance',
            '${claimNum(claim.systemDistanceKm)} KM',
          ),
          if (claim.userDistanceKm != null)
            _row('Your distance', '${claimNum(claim.userDistanceKm!)} KM'),
          _row('Rate per KM', claimMoney(claim.ratePerKm)),
          _row('Amount', claimMoney(claim.amount)),
          if (claim.extraExpenseAmount > 0)
            _row('Extra expenses', claimMoney(claim.extraExpenseAmount)),
          if (claim.advancePaymentAmount > 0)
            _row('Advance', '- ${claimMoney(claim.advancePaymentAmount)}'),
          const Divider(height: 24),
          _row('Net amount', claimMoney(claim.netAmount), emphasize: true),
          if (claim.remarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelBlock('Remarks', claim.remarks),
          ],
          if (claim.reviewRemarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _labelBlock('Review remarks', claim.reviewRemarks),
          ],
          if (claim.approvedDistanceKm != null) ...[
            const SizedBox(height: 10),
            _labelBlock(
              'Approved distance',
              '${claimNum(claim.approvedDistanceKm!)} KM',
            ),
          ],
          if (claim.isRejected) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This claim was rejected and cannot be resubmitted here. '
                      'Please contact your manager on the web portal.',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 16 : 14,
              color: emphasize ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _NetSummaryCard extends StatelessWidget {
  final double baseKm;
  final double rate;
  final double amount;
  final double extras;
  final double advance;
  final double net;

  const _NetSummaryCard({
    required this.baseKm,
    required this.rate,
    required this.amount,
    required this.extras,
    required this.advance,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estimated net',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Text(
                claimMoney(net),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${claimNum(baseKm)} KM × ${claimMoney(rate)}'
            '${extras > 0 ? ' + ${claimMoney(extras)} extras' : ''}'
            '${advance > 0 ? ' − ${claimMoney(advance)} advance' : ''}',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.text,
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
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
