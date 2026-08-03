import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({super.key});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final leadId = ModalRoute.of(context)?.settings.arguments as String?;
    final lead = leadId == null ? null : ref.watch(crmLeadByIdProvider(leadId));
    final ws = ref.watch(salesWorkspaceProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.text),
            onPressed: () {},
          ),
        ],
      ),
      body: ws.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lead == null
              ? Center(
                  child: Text(
                    leadId == null
                        ? 'Pass leadId via Navigator arguments.'
                        : 'Lead not found: $leadId',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Lead Header Card (Title & Lead ID)
                      _buildHeaderCard(
                        title: lead.companyName.isNotEmpty
                            ? lead.companyName
                            : (lead.contactName.isNotEmpty ? lead.contactName : 'Testing Lead'),
                        leadId: leadId ?? 'N/A',
                      ),
                      const SizedBox(height: 16),

                      // 2. Details / Timeline Tab Switcher
                      _buildTabBar(),
                      const SizedBox(height: 20),

                      if (_selectedTabIndex == 0) ...[
                        // 3. Lifecycle Section
                        _buildSectionHeader('LIFECYCLE'),
                        const SizedBox(height: 10),
                        _buildLifecycleStepper(lead.lifecycleStage ?? 'Qualify'),
                        const SizedBox(height: 24),

                        // 4. Lead Information / Snapshot
                        _buildSectionHeader('LEAD INFORMATION'),
                        const SizedBox(height: 10),
                        _buildSnapshotCard(
                          lead.clientType,
                          lead.lifecycleStage ?? '',
                          lead.status,
                          lead.repeatFrequency,
                        ),
                        const SizedBox(height: 16),

                        // 5. Contact Details Card
                        _buildContactCard(lead),
                        const SizedBox(height: 24),

                        // 6. Next Steps Section
                        _buildSectionHeader('NEXT STEPS'),
                        const SizedBox(height: 12),
                        _buildNextStepsActions(),
                      ] else ...[
                        // Timeline Section (built from lead.timeline)
                        _buildTimelineList(lead),
                      ],
                    ],
                  ),
                ),
    );
  }

  // Top Header Card containing Company/Name & Lead ID
  Widget _buildHeaderCard({required String title, required String leadId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  leadId,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Segmented Tab Switcher (Details / Timeline)
  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _selectedTabIndex == 0 ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _selectedTabIndex == 1 ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Label
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 0.8,
      ),
    );
  }

  // Normalizes lifecycle/status strings so backend values (e.g. "follow_up",
  // "In follow-up") match display labels (e.g. "Follow-up") regardless of
  // underscores, hyphens, spaces or casing.
  String _normalizeStage(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // Lifecycle Horizontal Stepper
  Widget _buildLifecycleStepper(String currentStage) {
    final stages = [
      'Lead entered',
      'Client type',
      'Qualify',
      'Follow-up',
      'Quotation',
      'Negotiation',
      'Won / Lost',
    ];

    final normalizedCurrent = _normalizeStage(currentStage);
    final currentIndex =
        stages.indexWhere((s) => _normalizeStage(s) == normalizedCurrent);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(stages.length * 2 - 1, (i) {
          // Even indices are stage chips, odd indices are arrow separators.
          if (i.isOdd) {
            final beforeIndex = i ~/ 2;
            final arrowPassed =
                currentIndex != -1 && beforeIndex < currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: arrowPassed ? AppColors.success : AppColors.border,
              ),
            );
          }

          final index = i ~/ 2;
          final stage = stages[index];
          final isSelected = index == currentIndex;
          final isPassed = currentIndex != -1 && index < currentIndex;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isPassed
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isPassed
                        ? AppColors.success
                        : AppColors.border,
              ),
            ),
            child: Text(
              stage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isPassed
                        ? AppColors.success
                        : AppColors.muted,
              ),
            ),
          );
        }),
      ),
    );
  }

  // Safely reads a field ('at' / 'text' / 'type') off a timeline entry,
  // whether it comes through as a Map<String, dynamic> (raw JSON) or a
  // typed model object with matching getters.
  String _timelineField(dynamic entry, String key) {
    try {
      if (entry is Map) {
        return (entry[key] ?? '').toString();
      }
      switch (key) {
        case 'at':
          return (entry.at ?? '').toString();
        case 'text':
          return (entry.text ?? '').toString();
        case 'type':
          return (entry.type ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  // Timeline Tab Content — renders lead.timeline (newest first) as a
  // vertical dot/line timeline, mirroring the web Timeline tab.
  Widget _buildTimelineList(dynamic lead) {
    final List<dynamic> rawTimeline =
        (lead.timeline as List?)?.toList() ?? const [];

    if (rawTimeline.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No timeline activity yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final sorted = List<dynamic>.from(rawTimeline)
      ..sort((a, b) =>
          _timelineField(b, 'at').compareTo(_timelineField(a, 'at')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sorted.length, (index) {
        final entry = sorted[index];
        final isLast = index == sorted.length - 1;
        final text = _timelineField(entry, 'text');
        final at = _timelineField(entry, 'at');
        final type = _timelineField(entry, 'type').toUpperCase();

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.35),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.isNotEmpty ? text : 'Activity',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          at,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (type.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Formats a raw backend value like "follow_up" or "in_follow_up" into a
  // display label like "FOLLOW UP".
  String _formatSnapshotLabel(String value) {
    if (value.trim().isEmpty) return '';
    return value.replaceAll(RegExp(r'[_\-]+'), ' ').trim().toUpperCase();
  }

  // Snapshot Status Card — pills are derived directly from this lead's own
  // data (clientType, lifecycleStage, status, repeatFrequency), so each
  // lead shows its own snapshot instead of matching against a fixed list.
  Widget _buildSnapshotCard(
    String clientType,
    String lifecycleStage,
    String status,
    String repeatFrequency,
  ) {
    // Each pill: (label, isActive). The current `status` is the live/active
    // state and gets the highlighted style; the rest are plain context tags.
    final pills = <String, bool>{};

    final clientTypeLabel = _formatSnapshotLabel(clientType);
    if (clientTypeLabel.isNotEmpty) pills[clientTypeLabel] = false;

    final lifecycleLabel = _formatSnapshotLabel(lifecycleStage);
    if (lifecycleLabel.isNotEmpty &&
        _normalizeStage(lifecycleLabel) != _normalizeStage(status)) {
      pills[lifecycleLabel] = false;
    }

    final statusLabel = _formatSnapshotLabel(status);
    if (statusLabel.isNotEmpty) pills[statusLabel] = true;

    final repeatLabel = _formatSnapshotLabel(repeatFrequency);
    if (repeatLabel.isNotEmpty) pills[repeatLabel] = false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SNAPSHOT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills.entries.map((pillEntry) {
              final pill = pillEntry.key;
              final isActive = pillEntry.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.accent : Colors.transparent,
                  ),
                ),
                child: Text(
                  pill,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.accent : AppColors.muted,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Contact Information Details Card
  Widget _buildContactCard(dynamic lead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTACT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Owner', lead.ownerName.isNotEmpty ? lead.ownerName : 'Unassigned'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Phone', lead.phone.isNotEmpty ? lead.phone : 'N/A'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Email', lead.email.isNotEmpty ? lead.email : 'N/A'),
          const Divider(height: 24, color: AppColors.surface, thickness: 1.5),
          _buildDetailRow('Address', lead.address?.isNotEmpty == true ? lead.address : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Quick Action Buttons
  Widget _buildNextStepsActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text('Start follow-up', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text('Log follow-up', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text('Create quotation', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text('Close as lost', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: const Text('Assign to rep', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}