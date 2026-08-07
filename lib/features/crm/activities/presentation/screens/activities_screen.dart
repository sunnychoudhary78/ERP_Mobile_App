// activities_screen.dart
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
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'Upcoming', 'Done'];

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
        title: const Text(
          'Follow-ups',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showLeadSelectionDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Log Follow-up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (activities) {
          final filteredActivities = activities.where((activity) {
            final status = activity.status.toString().toLowerCase();
            if (_selectedStatus == 'Upcoming' && status != 'pending' && status != 'upcoming') {
              return false;
            }
            if (_selectedStatus == 'Done' && status != 'completed' && status != 'done') {
              return false;
            }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // TOP STATUS SEGMENTED TABS (Sleek Native App Design)
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStatus = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // SECONDARY TYPE FILTER CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _typeOptions.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          showCheckmark: false,
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.12),
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // LOGGED COUNTER HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredActivities.length} Activity Logged',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ACTIVITIES LIST
                if (filteredActivities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 48,
                            color: AppColors.muted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No follow-ups match selected filters.',
                            style: TextStyle(color: AppColors.muted, fontSize: 14),
                          ),
                        ],
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

  void _showLeadSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: leads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final lead = leads[index];
                          final name = lead.companyName.isNotEmpty
                              ? lead.companyName
                              : lead.contactName;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'L',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name.isEmpty ? 'Unnamed Lead' : name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                lead.email.isNotEmpty ? lead.email : lead.phone,
                                style: const TextStyle(color: AppColors.muted, fontSize: 14),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
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
            loading: () => const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SizedBox(
              height: 250,
              child: Center(
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, dynamic activity) {
    final bool isCompleted =
        activity.status.toString().toLowerCase() == 'completed' ||
            activity.status.toString().toLowerCase() == 'done';

    final String type = (activity.type ?? 'Phone').toString().toLowerCase();

    IconData iconData = Icons.phone_outlined;
    Color iconBgColor = AppColors.primary.withOpacity(0.1);
    Color iconColor = AppColors.primary;

    if (type.contains('email')) {
      iconData = Icons.email_outlined;
      iconBgColor = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
    } else if (type.contains('meeting')) {
      iconData = Icons.groups_outlined;
      iconBgColor = Colors.blue.withOpacity(0.1);
      iconColor = Colors.blue;
    } else if (type.contains('task')) {
      iconData = Icons.task_alt_outlined;
      iconBgColor = Colors.purple.withOpacity(0.1);
      iconColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activity.type ?? 'Activity'} • ${activity.related ?? '—'}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activity.status.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${activity.dueAt ?? '—'}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ],
                ),
                if (!isCompleted)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Mark Done',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}