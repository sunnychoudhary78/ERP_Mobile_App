import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_claim_model.dart';
import '../providers/sales_claim_providers.dart';
import '../widgets/claim_common.dart';

/// Team claim requests — manager review (doc 04 §Manager review).
///
/// - List:   `GET  /api/sales/claims` (reporting tree, `status` filter)
/// - Review: `POST /api/sales/claims/:id/review` (`approve` / `reject`)
///
/// Only reachable when the user holds `sales_distance_claims.review`
/// (route is gated on `salesCanReviewClaims`).
class TeamClaimRequestsScreen extends ConsumerStatefulWidget {
  const TeamClaimRequestsScreen({super.key});

  @override
  ConsumerState<TeamClaimRequestsScreen> createState() =>
      _TeamClaimRequestsScreenState();
}

class _TeamClaimRequestsScreenState
    extends ConsumerState<TeamClaimRequestsScreen> {
  // Managers mostly act on Pending / Disputed claims — default to Pending.
  static const _filters = <String?>[
    'Pending',
    'Disputed',
    'Approved',
    'Rejected',
    null,
  ];

  String? _selected = 'Pending';
  String? _busyId;

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

  Future<void> _review(SalesClaim claim, {required String action}) async {
    final approvedController = TextEditingController(
      text: claimNum(claim.userDistanceKm ?? claim.systemDistanceKm),
    );
    final remarksController = TextEditingController();
    final isApprove = action == 'approve';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve claim' : 'Reject claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${claim.userName.isEmpty ? 'Team member' : claim.userName} · '
              '${claimMonthLabel(claim.monthKey)}',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (isApprove) ...[
              TextField(
                controller: approvedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Approved distance (KM)',
                  hintText: 'Overrides the claimed distance',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isApprove ? 'Remarks (optional)' : 'Reason (required)',
                hintText: isApprove
                    ? 'Approved as claimed'
                    : 'Distance does not match odometer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.danger,
            ),
            onPressed: () {
              if (!isApprove && remarksController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      approvedController.dispose();
      remarksController.dispose();
      return;
    }

    final approvedKm = double.tryParse(approvedController.text.trim());
    final remarks = remarksController.text.trim();
    approvedController.dispose();
    remarksController.dispose();

    setState(() => _busyId = claim.id);
    try {
      final updated = await ref
          .read(teamClaimsProvider.notifier)
          .review(
            claim.id,
            action: action,
            approvedDistanceKm: isApprove ? approvedKm : null,
            remarks: remarks,
          );
      _snack('Claim ${claimStatusLabel(updated.status).toLowerCase()}');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamClaimsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Team claim requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.read(teamClaimsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final value = _filters[i];
                final selected = _selected == value;
                return ChoiceChip(
                  label: Text(value ?? 'All'),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selected = value);
                    ref.read(teamClaimsProvider.notifier).setStatus(value);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.read(teamClaimsProvider.notifier).refresh(),
              ),
              data: (claims) {
                if (claims.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(teamClaimsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: claims.length,
                    itemBuilder: (_, i) {
                      final claim = claims[i];
                      final actionable = claim.isPending || claim.isDisputed;
                      return _RequestCard(
                        claim: claim,
                        busy: _busyId == claim.id,
                        onApprove: actionable
                            ? () => _review(claim, action: 'approve')
                            : null,
                        onReject: actionable
                            ? () => _review(claim, action: 'reject')
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SalesClaim claim;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.claim,
    required this.busy,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.userName.isEmpty ? 'Team member' : claim.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claimMonthLabel(claim.monthKey),
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ClaimStatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 12),
          _row('Vehicle', claimVehicleLabel(claim.vehicleType)),
          _row(
            'System / claimed',
            claim.userDistanceKm != null
                ? '${claimNum(claim.systemDistanceKm)} / '
                      '${claimNum(claim.userDistanceKm!)} KM'
                : '${claimNum(claim.systemDistanceKm)} KM',
          ),
          _row(
            'Rate · Amount',
            '${claimMoney(claim.ratePerKm)} · ${claimMoney(claim.amount)}',
          ),
          if (claim.extraExpenseAmount > 0 || claim.advancePaymentAmount > 0)
            _row(
              'Extras · Advance',
              '${claimMoney(claim.extraExpenseAmount)} · '
                  '${claimMoney(claim.advancePaymentAmount)}',
            ),
          const Divider(height: 20),
          Row(
            children: [
              Text(
                'Net amount',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                claimMoney(claim.netAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (claim.remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _labelBlock('Remarks', claim.remarks),
          ],
          if (onApprove != null && onReject != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (claim.reviewRemarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _labelBlock('Review remarks', claim.reviewRemarks),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('No claim requests', style: TextStyle(color: AppColors.muted)),
        ],
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
