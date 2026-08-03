import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class CrmApprovalsScreen extends ConsumerStatefulWidget {
  const CrmApprovalsScreen({super.key});

  @override
  ConsumerState<CrmApprovalsScreen> createState() => _CrmApprovalsScreenState();
}

class _CrmApprovalsScreenState extends ConsumerState<CrmApprovalsScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'All Approvals',
    'High Priority',
    'Due Today',
    'Accounts',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmApprovalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
          ),
        ],
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (items) {
          final quoteCount = items.where((i) => i.kind != 'won').length;
          final wonCount = items.where((i) => i.kind == 'won').length;

          return RefreshIndicator(
            onRefresh: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Top Stat Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'QUOTE APPROVALS',
                        count: '$quoteCount',
                        subtitle: 'pending review',
                        accentColor: const Color(0xFF1B4F72),
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'WON DEALS',
                        count: '$wonCount',
                        subtitle: 'pending review',
                        accentColor: const Color(0xFF1E8449),
                        icon: Icons.handshake_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 0, height: 20),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search accounts, quotes, or owners...',
                    hintStyle: const TextStyle(color: Color(0xFF95A5A6), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8C8D)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF1B4F72), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilterIndex == index;
                      return ChoiceChip(
                        label: Text(_filters[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilterIndex = index);
                          }
                        },
                        selectedColor: const Color(0xFF1B4F72),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1C2833),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Pending Inbox Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Inbox',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2833),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D6D7E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List of Approval Cards
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No pending CRM approvals.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...items.map((item) => _buildApprovalCard(context, item)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Top Summary Metric Card Widget
  Widget _buildSummaryCard({
    required String title,
    required String count,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(icon, size: 48, color: Colors.grey.shade100),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2833),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D6D7E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern Item Approval Card
  Widget _buildApprovalCard(BuildContext context, dynamic item) {
    final isWon = item.kind == 'won';
    final headerColor = isWon ? const Color(0xFF1E8449) : const Color(0xFF1B4F72);
    final badgeBg = isWon ? Colors.green.shade50 : Colors.red.shade50;
    final badgeText = isWon ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top details: ID & Amount/Value
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWon ? 'DEAL ID' : 'QUOTE ID',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D6D7E),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.id ?? 'QT-88219-X',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isWon ? 'VALUE' : 'AMOUNT',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D6D7E),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.amount ?? '\$42,500.00',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isWon ? const Color(0xFF1E8449) : const Color(0xFF1C2833),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Company Icon & Details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isWon ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isWon ? Icons.handshake : Icons.apartment,
                        color: isWon ? const Color(0xFF1E8449) : const Color(0xFF1B4F72),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C2833),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D6D7E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Owner Avatar & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.ownerName ?? 'David Chen',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C2833),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item.status ?? (isWon ? 'WON TODAY' : 'EXPIRING 2H')).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F4)),

          // Bottom Actions Row (Reject / Approve buttons)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleReject(context, item),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFFC0392B)),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFFC0392B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF2F4F4)),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleApprove(context, item),
                  icon: const Icon(Icons.check, size: 18, color: Color(0xFF1E8449)),
                  label: const Text(
                    'Approve',
                    style: TextStyle(
                      color: Color(0xFF1E8449),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handlers tied to Riverpod State
  Future<void> _handleApprove(BuildContext context, dynamic item) async {
    final notifier = ref.read(salesWorkspaceProvider.notifier);
    try {
      if (item.kind == 'won') {
        await notifier.approveWon(item.id);
      } else {
        await notifier.approveQuote(item.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, dynamic item) async {
    final notifier = ref.read(salesWorkspaceProvider.notifier);
    try {
      if (item.kind == 'won') {
        await notifier.rejectWon(item.id, 'Rejected');
      } else {
        await notifier.rejectQuote(item.id, 'Rejected');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }
}