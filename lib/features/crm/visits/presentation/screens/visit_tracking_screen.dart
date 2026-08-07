import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class VisitTrackingScreen extends ConsumerWidget {
  const VisitTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crmVisitsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Visit Tracking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (visits) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              ref.read(salesWorkspaceProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // FIXED: Wrapped in SliverToBoxAdapter
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 2. Team Stats Metric Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTeamStatsSummary(visits),
                ),
              ),

              // 3. Header Title for List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Visits & Logs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAECEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${visits.length} Total',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                    ],
                  ),
                ),
              ),

              // 4. Visits List
              visits.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 48,
                              color: AppColors.muted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No active visits recorded.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final visit = visits[index];
                          return _buildVisitCard(visit, index);
                        }, childCount: visits.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Metric cards row
  /// Stats metric card overview section
  Widget _buildTeamStatsSummary(List dynamicVisits) {
    // Count visits that have a time logged ('at' is not null) as completed
    final completedCount = dynamicVisits.where((v) => v.at != null).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: 'ACTIVE REPS',
            value: '${dynamicVisits.where((v) => v.repName != null).length}',
            icon: Icons.people_outline,
            isHighlighted: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            title: 'VISITS TODAY',
            value: '${dynamicVisits.length}',
            icon: Icons.location_on_outlined,
            isHighlighted: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            title: 'COMPLETED',
            value: '$completedCount',
            icon: Icons.check_circle_outline,
            isHighlighted: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required bool isHighlighted,
  }) {
    final bgColor = isHighlighted ? AppColors.primary : AppColors.card;
    final textColor = isHighlighted ? Colors.white : AppColors.text;
    final mutedTextColor = isHighlighted ? Colors.white70 : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? null
            : Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Visit card item styled according to the layout design
  Widget _buildVisitCard(dynamic visit, int index) {
    // Dynamic border color based on item state/index
    final statusColor = index % 2 == 1 ? AppColors.danger : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left status color strip
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building / Store Icon
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFF2F4F4),
                        child: Icon(
                          index % 2 == 1
                              ? Icons.storefront_outlined
                              : Icons.domain_outlined,
                          color: AppColors.text,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    visit.clientName ?? 'Unnamed Client',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (visit.at != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F4F5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.border.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${visit.at}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  visit.repName ?? 'Unassigned',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    visit.location ?? 'No location',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
