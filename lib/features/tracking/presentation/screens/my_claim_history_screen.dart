import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_claim_model.dart';
import '../providers/sales_claim_providers.dart';
import '../widgets/claim_common.dart';

/// My claim history — `GET /api/sales/claims?mine=1` (doc 04 §My claims list).
class MyClaimHistoryScreen extends ConsumerStatefulWidget {
  const MyClaimHistoryScreen({super.key});

  @override
  ConsumerState<MyClaimHistoryScreen> createState() =>
      _MyClaimHistoryScreenState();
}

class _MyClaimHistoryScreenState extends ConsumerState<MyClaimHistoryScreen> {
  static const _filters = <String?>[
    null,
    'Pending',
    'Disputed',
    'Approved',
    'Rejected',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myClaimsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My claim history'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.read(myClaimsProvider.notifier).refresh(),
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
                    ref.read(myClaimsProvider.notifier).setStatus(value);
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
                onRetry: () => ref.read(myClaimsProvider.notifier).refresh(),
              ),
              data: (claims) {
                if (claims.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(myClaimsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: claims.length,
                    itemBuilder: (_, i) => _ClaimCard(claim: claims[i]),
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

class _ClaimCard extends StatelessWidget {
  final SalesClaim claim;
  const _ClaimCard({required this.claim});

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
                child: Text(
                  claimMonthLabel(claim.monthKey),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ClaimStatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 10),
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
          if (claim.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Submitted ${claimDateTimeLabel(claim.createdAt)}',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('No claims yet', style: TextStyle(color: AppColors.muted)),
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
