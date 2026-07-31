import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/approvals_inbox_provider.dart';

class ApprovalsInboxScreen extends ConsumerStatefulWidget {
  const ApprovalsInboxScreen({super.key});

  @override
  ConsumerState<ApprovalsInboxScreen> createState() => _ApprovalsInboxScreenState();
}

class _ApprovalsInboxScreenState extends ConsumerState<ApprovalsInboxScreen> {
  int _selectedTabIndex = 0; // 0 for Pending, 1 for History

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(approvalsInboxProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
             const Text(
                    'Approvals Inbox',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
            const SizedBox(width: 12),
            // Text(
            //   'Immortal ERP',
            //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         fontWeight: FontWeight.bold,
            //         color: const Color(0xFF0F172A),
            //       ),
            // ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
        //     onPressed: () {},
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.read(approvalsInboxProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          return RefreshIndicator(
            onRefresh: () => ref.read(approvalsInboxProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Bar (Pending / History)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabItem(
                          label: 'Pending (${items.length})',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildTabItem(
                          label: 'History',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Items List
                  if (_selectedTabIndex == 0) ...[
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: Text('No pending approvals')),
                      )
                    else
                      ...items.map((item) => ApprovalCard(item: item)),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text('History is empty')),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.text :AppColors.text,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            height: 3,
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class ApprovalCard extends ConsumerWidget {
  final dynamic item; // Replace 'dynamic' with your model class (e.g. ApprovalItem)

  const ApprovalCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic styling based on approval item type
    final typeStr = (item.type?.toString() ?? 'LEAVE REQUEST').toUpperCase();
    
    Color stripeColor = const Color(0xFF3B82F6); // Default blue
    Color badgeBgColor = const Color(0xFFDBEAFE);
    Color badgeTextColor = const Color(0xFF1E40AF);

    if (typeStr.contains('QUOTE')) {
      stripeColor = const Color(0xFFF59E0B);
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFF92400E);
    } else if (typeStr.contains('LEAD')) {
      stripeColor = const Color(0xFF10B981);
      badgeBgColor = const Color(0xFFD1FAE5);
      badgeTextColor = const Color(0xFF065F46);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Color strip on left edge
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: stripeColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Badge & Comment Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.typeTag ?? 'LEAVE REQUEST',
                        style: TextStyle(
                          color: badgeTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black54),
                      onPressed: () => _showCommentDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Title / Name
                Text(
                  item.title ?? 'Marcus Aurelius',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / Description Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.subtitle ?? 'Oct 24 - Oct 28 (5 Days)',
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (item.details != null || item.comment != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${item.details ?? item.comment ?? 'Family emergency - needing immediate coverage.'}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // TODO: Wire approve logic
                          // ref.read(approvalsInboxProvider.notifier).approveLeave(item, comment: 'Approved');
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFF0F172A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // TODO: Wire reject logic
                          // ref.read(approvalsInboxProvider.notifier).rejectLeave(item, comment: 'Rejected');
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your comment here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform action with controller.text
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}