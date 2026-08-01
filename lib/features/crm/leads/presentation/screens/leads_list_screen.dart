import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

/// Status -> color mapping for the left accent bar + badge.
/// Now pulled from AppColors so it matches the rest of the app's theme
/// instead of random hardcoded hex values.
class _LeadStatusStyle {
  final Color accent;
  final Color badgeBg;
  final Color badgeText;

  const _LeadStatusStyle(this.accent, this.badgeBg, this.badgeText);

  static _LeadStatusStyle forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return _LeadStatusStyle(
          AppColors.primary,
          AppColors.primary,
          Colors.white,
        );
      case 'contacted':
        return _LeadStatusStyle(
          AppColors.danger,
          AppColors.danger.withOpacity(0.12),
          AppColors.danger,
        );
      case 'proposal':
        return _LeadStatusStyle(
          AppColors.accent,
          AppColors.accent.withOpacity(0.14),
          AppColors.primaryDark,
        );
      case 'negotiation':
        return _LeadStatusStyle(
          AppColors.success,
          AppColors.success.withOpacity(0.12),
          AppColors.success,
        );
      default:
        return _LeadStatusStyle(
          AppColors.muted,
          AppColors.border.withOpacity(0.5),
          AppColors.muted,
        );
    }
  }
}

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'New', 'Contacted', 'Proposal', 'Negotiation'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmLeadsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Leads List',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: AppColors.text,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/crm/leads/form'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (leads) {
          final filtered = leads.where((l) {
            final matchesFilter = _filter == 'All' ||
                l.status.toLowerCase() == _filter.toLowerCase();
            final q = _query.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                l.companyName.toLowerCase().contains(q) ||
                l.contactName.toLowerCase().contains(q);
            return matchesFilter && matchesQuery;
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterChips(
                    filters: _filters,
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'ACTIVE LEADS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No leads found.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final l = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _LeadCard(
                              title: l.companyName.isEmpty
                                  ? l.contactName
                                  : l.companyName,
                              subtitle:
                                  l.companyName.isEmpty ? '' : l.contactName,
                              status: l.status,
                              phone: l.phone,
                              email: l.email,
                              // TODO: hook up real fields once available on the model
                              // dealValue: l.dealValue,
                              // timeAgo: l.updatedAt,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/crm/leads/detail',
                                arguments: l.id,
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Search leads',
            hintStyle: TextStyle(color: AppColors.muted),
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
          style: const TextStyle(color: AppColors.text),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = f == selected;
          return ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (_) => onSelected(f),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.text,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          );
        },
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String phone;
  final String email;
  final VoidCallback onTap;
  final String? dealValue;
  final String? timeAgo;

  const _LeadCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.phone,
    required this.email,
    required this.onTap,
    this.dealValue,
    this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final style = _LeadStatusStyle.forStatus(status);
    final contact = phone.isNotEmpty ? phone : email;
    final contactIcon =
        phone.isNotEmpty ? Icons.call_outlined : Icons.email_outlined;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: style.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.muted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_east,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: style.badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: style.badgeText,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (contact.isNotEmpty) ...[
                              Icon(contactIcon,
                                  size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  contact,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            color: AppColors.border.withOpacity(0.5),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeAgo ?? '—',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            if (dealValue != null)
                              Text(
                                dealValue!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.text,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}