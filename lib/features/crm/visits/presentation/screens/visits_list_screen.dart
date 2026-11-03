import 'package:erp_app/core/network/api_constants.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/data/models/sales_visit_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

enum _VisitRange { today, week, all }

/// My visits — `GET /api/sales/visits` scoped to the logged-in user, with a
/// client-name search and today / this week filters (doc 02 §List visits).
class VisitsListScreen extends ConsumerStatefulWidget {
  const VisitsListScreen({super.key});

  @override
  ConsumerState<VisitsListScreen> createState() => _VisitsListScreenState();
}

class _VisitsListScreenState extends ConsumerState<VisitsListScreen> {
  final _searchController = TextEditingController();
  _VisitRange _range = _VisitRange.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  (DateTime?, DateTime?) _rangeBounds(_VisitRange range) {
    final now = DateTime.now();
    switch (range) {
      case _VisitRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case _VisitRange.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        return (start, start.add(const Duration(days: 7)));
      case _VisitRange.all:
        return (null, null);
    }
  }

  void _applyRange(_VisitRange range) {
    setState(() => _range = range);
    final (from, to) = _rangeBounds(range);
    ref.read(myVisitsProvider.notifier).setRange(from: from, to: to);
  }

  List<SalesVisit> _filter(List<SalesVisit> visits) {
    if (_query.trim().isEmpty) return visits;
    final q = _query.trim().toLowerCase();
    return visits
        .where((v) => v.clientName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myVisitsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My visits'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.read(myVisitsProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/crm/visits/add');
          if (created == true) {
            ref.read(myVisitsProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log visit', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by client name...',
                    prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip('Today', _VisitRange.today),
                    const SizedBox(width: 8),
                    _chip('This week', _VisitRange.week),
                    const SizedBox(width: 8),
                    _chip('All', _VisitRange.all),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CrmAsyncBody(
              async: async,
              onRetry: () => ref.read(myVisitsProvider.notifier).refresh(),
              builder: (visits) {
                final filtered = _filter(visits);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No visits found',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(myVisitsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _visitCard(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _VisitRange value) {
    final selected = _range == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _applyRange(value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.text,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _visitCard(SalesVisit visit) {
    DateTime? time;
    if (visit.at != null) time = DateTime.tryParse(visit.at!)?.toLocal();
    final timeLabel = time == null
        ? (visit.at ?? '—')
        : DateFormat('dd MMM, hh:mm a').format(time);

    return Card(
      elevation: 0,
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/crm/visits/detail',
            arguments: visit.refId,
          );
          if (mounted) {
            ref.read(myVisitsProvider.notifier).refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: visit.photoUrl != null && visit.photoUrl!.isNotEmpty
                      ? Image.network(
                          ApiConstants.fileUrl(visit.photoUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.clientName.isEmpty
                                ? 'Unnamed client'
                                : visit.clientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (visit.type != null)
                          _tag(visit.type!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    if (visit.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visit.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (visit.followUpAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Follow-up ${visit.followUpAt}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      color: AppColors.surface,
      child: Icon(Icons.storefront_outlined, color: AppColors.muted),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppColors.text),
      ),
    );
  }
}
