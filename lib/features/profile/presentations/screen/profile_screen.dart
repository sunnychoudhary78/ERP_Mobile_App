import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('My Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(authProvider.notifier).tryAutoLogin(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _ProfileHeader(
                    fullName: profile.associatesName ?? 'User',
                    designation: profile.designation,
                    profileUrl: authState.profileUrl,
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel('CONTACT'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile.email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel('WORK INFO'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Designation',
                        value: profile.designation,
                      ),
                      _InfoTile(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Payroll code',
                        value: profile.payrollCode,
                      ),
                      _InfoTile(
                        icon: Icons.apartment_outlined,
                        label: 'Department',
                        value: profile.departmentName,
                      ),
                      _InfoTile(
                        icon: profile.active == false
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline,
                        iconColor: profile.active == false
                            ? AppColors.danger
                            : AppColors.success,
                        label: 'Status',
                        value: profile.active == false
                            ? 'Inactive'
                            : 'Active',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel('COMPANY'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'Company',
                        value: profile.companyName,
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: _formatDate(profile.createdAt),
                        isLast: profile.subscriptionEndDate == null,
                      ),
                      if (profile.subscriptionEndDate != null)
                        _InfoTile(
                          icon: Icons.event_available_outlined,
                          label: 'Plan valid till',
                          value: _formatDate(profile.subscriptionEndDate),
                          isLast: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String? designation;
  final String profileUrl;

  const _ProfileHeader({
    required this.fullName,
    required this.designation,
    required this.profileUrl,
  });

  String get _initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            backgroundImage: profileUrl.isNotEmpty
                ? NetworkImage(profileUrl)
                : null,
            child: profileUrl.isEmpty
                ? Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (designation != null && designation!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    designation!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value!.trim().isEmpty)
        ? '—'
        : value!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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