import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/crm/activities/presentation/screens/follow_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';


class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  // Web Filter 1: Status (All, Upcoming, Done)
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'Upcoming', 'Done'];

  // Web Filter 2: Type (All types, Calls, Meetings, Emails, Tasks)
  String _selectedType = 'All types';
  final List<String> _typeOptions = [
    'All types',
    'Calls',
    'Meetings',
    'Emails',
    'Tasks',
  ];

  bool _handledDeepLink = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledDeepLink) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final leadId = args is String ? args : null;
    if (leadId == null || leadId.isEmpty) return;
    _handledDeepLink = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lead = ref.read(crmLeadByIdProvider(leadId));
      final name = lead == null
          ? 'Lead'
          : (lead.companyName.isNotEmpty
              ? lead.companyName
              : (lead.contactName.isNotEmpty ? lead.contactName : 'Lead'));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FollowUpScreen(leadId: leadId, leadName: name),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          _showLeadSelectionDialog(context);
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (activities) {
          // Exact filtering matching Web Logic
          final filteredActivities = activities.where((activity) {
            // 1. Status Filter
            final status = activity.status.toString().toLowerCase();
            if (_selectedStatus == 'Upcoming' && status != 'pending' && status != 'upcoming') {
              return false;
            }
            if (_selectedStatus == 'Done' && status != 'completed' && status != 'done') {
              return false;
            }

            // 2. Type Filter
            final type = (activity.type ?? '').toString().toLowerCase();
            if (_selectedType == 'Calls' && !type.contains('phone') && !type.contains('call')) {
              return false;
            }
            if (_selectedType == 'Meetings' && !type.contains('meeting')) {
              return false;
            }
            if (_selectedType == 'Emails' && !type.contains('email')) {
              return false;
            }
            if (_selectedType == 'Tasks' && !type.contains('task')) {
              return false;
            }

            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // WEB FILTERS ROW
                Row(
                  children: [
                    // Filter 1: Status Dropdown (All, Upcoming, Done)
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedStatus,
                        items: _statusOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter 2: Type Dropdown (All types, Calls, Meetings, Emails, Tasks)
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedType,
                        items: _typeOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // LOGGED COUNTER (Matches Web UI Header)
                Text(
                  '${filteredActivities.length} logged',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // ACTIVITIES LIST
                if (filteredActivities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No follow-ups match selected filters.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...filteredActivities.map((item) => _buildActivityCard(context, item)),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  // Web-styled Filter Dropdown Box
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLeadSelectionDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final leadsAsync = ref.watch(crmLeadsProvider);
        return leadsAsync.when(
          data: (leads) {
            if (leads.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No leads available to log follow-ups.'),
                ),
              );
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Lead',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        final name = lead.companyName.isNotEmpty 
                            ? lead.companyName 
                            : lead.contactName;
                        
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              name.isEmpty ? 'Unnamed Lead' : name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              lead.email.isNotEmpty ? lead.email : lead.phone,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.muted,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowUpScreen(
                                    leadId: lead.id,
                                    leadName: name.isEmpty ? 'Unnamed Lead' : name,
                                  ),
                                ),
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
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // Card matching Mobile & Theme Layout
  Widget _buildActivityCard(BuildContext context, dynamic activity) {
    final bool isCompleted =
        activity.status.toString().toLowerCase() == 'completed' ||
            activity.status.toString().toLowerCase() == 'done';
            
    final String type = (activity.type ?? 'Phone').toString().toLowerCase();

    // Type Contextual Icon & Colors
    IconData iconData = Icons.phone_outlined;
    Color iconBgColor = const Color(0xFFD4EFDF);
    Color iconColor = const Color(0xFF1E8449);

    if (type.contains('email')) {
      iconData = Icons.mail_outline;
      iconBgColor = const Color(0xFFFADBD8);
      iconColor = const Color(0xFFC0392B);
    } else if (type.contains('meeting')) {
      iconData = Icons.groups_outlined;
      iconBgColor = const Color(0xFFD6EAF8);
      iconColor = const Color(0xFF2874A6);
    } else if (type.contains('task')) {
      iconData = Icons.check_box_outlined;
      iconBgColor = const Color(0xFFFCF3CF);
      iconColor = const Color(0xFFB7950B);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBgColor,
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.subject.isEmpty ? (activity.type ?? 'Activity') : activity.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.type ?? 'Activity'} · ${activity.related ?? '—'}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activity.status.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${activity.dueAt ?? '—'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (!isCompleted)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                    label: const Text(
                      'Mark Done',
                      style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      try {
                        await ref.read(salesWorkspaceProvider.notifier).completeActivity(activity.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceFirst('Exception: ', '')),
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}