import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key});

  // Helper method to extract initials from the lead's name
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadId = ModalRoute.of(context)?.settings.arguments as String?;
    final lead = leadId == null ? null : ref.watch(crmLeadByIdProvider(leadId));
    final ws = ref.watch(salesWorkspaceProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ws.isLoading
            ? const Center(child: CircularProgressIndicator())
            : lead == null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildBackButton(context),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          leadId == null
                              ? 'Pass leadId via Navigator arguments.'
                              : 'Lead not found: $leadId',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Bar Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBackButton(context),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert, color: AppColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Avatar Widget (Letters) with Stage Badge
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(
                                    lead.contactName.isNotEmpty
                                        ? lead.contactName
                                        : lead.companyName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  lead.lifecycleStage ?? lead.status ?? 'New',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name & Company
                        Text(
                          lead.contactName.isNotEmpty
                              ? lead.contactName
                              : 'Unnamed Lead',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.companyName.isNotEmpty
                              ? lead.companyName
                              : 'No Company',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Estimated Value Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'ESTIMATED VALUE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${lead.value ?? 0}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Action Buttons (Call / Email)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: Icons.phone,
                              backgroundColor: const Color(0xFF2563EB),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              icon: Icons.email,
                              backgroundColor: const Color(0xFF059669),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Contact Information Header
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CONTACT INFORMATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.muted,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contact Details List
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: lead.email.isNotEmpty ? lead.email : 'N/A',
                          subtitle: 'Email',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Icons.smartphone_outlined,
                          title: lead.phone.isNotEmpty ? lead.phone : 'N/A',
                          subtitle: 'Phone',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          title: lead.ownerName.isNotEmpty
                              ? lead.ownerName
                              : 'Unassigned',
                          subtitle: 'Owner',
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.text,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: const EdgeInsets.all(16),
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.muted, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}