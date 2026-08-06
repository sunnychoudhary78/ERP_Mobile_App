import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/crm/shared/data/models/sales_quote_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  final List<String> _statuses = [
    'ALL',
    'DRAFT',
    'PENDING',
    'APPROVED',
    'SENT',
    'ACCEPTED',
    'REJECTED',
    'EXPIRED',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // A quote's real-world status can come from either its own `status`
  // field or its `approval.status` (e.g. quote.status stays "draft"
  // while approval.status is "approved"). Approval status wins when set.
  String _effectiveStatus(SalesQuote q) {
    final approvalStatus = q.approval['status']?.toString();
    if (approvalStatus != null && approvalStatus.trim().isNotEmpty) {
      final s = approvalStatus.toUpperCase();
      // Map approval workflow values to the same vocabulary used for
      // quote statuses so the badge/colors/filters all line up.
      switch (s) {
        case 'APPROVED':
        case 'ACCEPTED':
          return 'APPROVED';
        case 'REJECTED':
          return 'REJECTED';
        case 'PENDING':
        case 'REQUESTED':
          return 'PENDING';
      }
    }
    final status = q.status;
    return status.isNotEmpty ? status.toUpperCase() : 'DRAFT';
  }

  // Returns status badge colors based on status string
  (Color bg, Color text) _getStatusColors(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
        return (
          const Color(0xFFE8F1FC),
          AppColors.primary,
        );
      case 'PENDING':
      case 'SENT':
        return (
          AppColors.accent.withOpacity(0.12),
          AppColors.accent,
        );
      case 'REJECTED':
      case 'EXPIRED':
        return (
          AppColors.danger.withOpacity(0.12),
          AppColors.danger,
        );
      case 'DRAFT':
      default:
        return (
          AppColors.muted.withOpacity(0.12),
          AppColors.muted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmQuotesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Quotes',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Navigator.pushNamed(context, '/crm/quotes/form'),
      //   backgroundColor: AppColors.primaryDark,
      //   shape: const CircleBorder(),
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (quotes) {
          // Count metrics per status
          final statusCounts = <String, int>{
            'ALL': quotes.length,
            'DRAFT': 0,
            'PENDING': 0,
            'APPROVED': 0,
            'SENT': 0,
            'ACCEPTED': 0,
            'REJECTED': 0,
            'EXPIRED': 0,
          };

          for (final q in quotes) {
            final statusKey = _effectiveStatus(q);
            if (statusCounts.containsKey(statusKey)) {
              statusCounts[statusKey] = statusCounts[statusKey]! + 1;
            }
          }

          // Filter quotes by search and selected chip
          final filteredQuotes = quotes.where((q) {
            final number = (q.number ?? q.account ?? q.id).toLowerCase();
            final matchesSearch = number.contains(_searchQuery.toLowerCase());
            final matchesStatus = _selectedStatus == 'ALL' ||
                _effectiveStatus(q) == _selectedStatus;
            return matchesSearch && matchesStatus;
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
              

                // Search & Filter Bar Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search quotes...',
                          hintStyle: const TextStyle(color: AppColors.muted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                          contentPadding: EdgeInsets.zero,
                          fillColor: AppColors.card,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_outlined,
                            color: AppColors.text, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      final count = statusCounts[status] ?? 0;
                      final labelText = status == 'ALL' ? 'ALL' : '$status ($count)';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              labelText,
                              style: textTheme.labelMedium?.copyWith(
                                color: isSelected ? Colors.white : AppColors.text,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Quotes List
                if (filteredQuotes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No quotes found.',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...filteredQuotes.map((q) {
                    final effectiveStatus = _effectiveStatus(q);
                    final statusColors = _getStatusColors(effectiveStatus);
                    final displayTitle = q.number ?? q.account ?? q.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Material(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/crm/quotes/detail',
                            arguments: q.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border.withOpacity(0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Icon + Title + Status Badge
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.article_outlined,
                                      size: 22,
                                      color: AppColors.primaryDark,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        displayTitle,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColors.$1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        effectiveStatus,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: statusColors.$2,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Customer / Account Name Subtitle
                                Padding(
                                  padding: const EdgeInsets.only(left: 32.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.business_outlined,
                                        size: 14,
                                        color: AppColors.muted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        q.account ?? 'test', // Account placeholder or field
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: AppColors.surface, height: 1),
                                const SizedBox(height: 14),

                                // Bottom Section: Expiry Date & Amount Summary
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Left: Valid until & Line item count
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: AppColors.muted,
                                            ),
                                            const SizedBox(width: 6),
                                            RichText(
                                              text: TextSpan(
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: AppColors.text,
                                                ),
                                                children: const [
                                                  TextSpan(
                                                    text: 'Valid until: ',
                                                    style: TextStyle(color: AppColors.muted),
                                                  ),
                                                  TextSpan(
                                                    text: '2026-08-27',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Right: Total Amount Block
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.inventory_2_outlined,
                                              size: 14,
                                              color: AppColors.muted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '1 Line Item',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'TOTAL AMOUNT',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          q.amount != null ? '₹${q.amount}' : '₹10,62,000',
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}