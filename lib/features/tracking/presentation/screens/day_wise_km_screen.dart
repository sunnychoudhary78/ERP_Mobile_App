import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_claim_model.dart';
import '../providers/sales_claim_providers.dart';
import '../widgets/claim_common.dart';

/// Day-wise KM — `GET /api/sales/tracking/my-history`
/// (doc 04 §Day-wise KM). Lets the user check the system distance before
/// agreeing / disputing their claim.
class DayWiseKmScreen extends ConsumerWidget {
  const DayWiseKmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
    final async = ref.watch(claimDistanceHistoryProvider(monthKey));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          monthKey.isEmpty
              ? 'Day-wise KM'
              : 'Day-wise KM · ${claimMonthLabel(monthKey)}',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () =>
                ref.invalidate(claimDistanceHistoryProvider(monthKey)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(claimDistanceHistoryProvider(monthKey)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route_outlined, size: 48, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(
                    'No tracking sessions for this month',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          final total = days.fold<double>(
            0,
            (sum, d) => sum + d.totalDistanceKm,
          );

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(claimDistanceHistoryProvider(monthKey)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    children: [
                      const _HeaderRow(),
                      for (final day in days) _DayRow(day: day),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total distance',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${claimNum(total)} KM',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Date', style: style)),
          Expanded(flex: 3, child: Text('Check-in', style: style)),
          Expanded(flex: 3, child: Text('Check-out', style: style)),
          Expanded(
            flex: 2,
            child: Text('KM', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final ClaimHistoryDay day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _shortDate(day.date),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _shortTime(day.checkIn),
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _shortTime(day.checkOut),
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              claimNum(day.totalDistanceKm),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    final label = claimMonthLabel(
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}',
    ).split(' ').first;
    return '${dt.day.toString().padLeft(2, '0')} ${label.substring(0, 3)}';
  }

  static String _shortTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
