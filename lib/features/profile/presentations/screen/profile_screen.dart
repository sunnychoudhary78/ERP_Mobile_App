import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/permissions/app_permissions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await ref
          .read(authProvider.notifier)
          .uploadProfilePhoto(File(picked.path));
      if (!mounted) return;
      _showSnack('Profile photo updated');
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final self = ref.watch(selfEmployeeProvider).asData?.value;
    final vehicleType = ref.watch(vehicleTypeProvider).asData?.value;
    final canViewTeam = authState.canAny(AppPermissions.teamDashboard);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('My Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(authProvider.notifier).refreshProfile();
                ref.invalidate(selfEmployeeProvider);
                ref.invalidate(vehicleTypeProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _ProfileHeader(
                    fullName: profile.associatesName ?? 'User',
                    designation: profile.designation,
                    profileUrl: authState.profileUrl,
                    isUploading: _isUploadingPhoto,
                    onTapPhoto: _pickAndUploadPhoto,
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
                        isLast: self?.contactPrimary == null,
                      ),
                      if (self?.contactPrimary != null)
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: self!.contactPrimary,
                          isLast: true,
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
                        value: self?.payrollCode ?? profile.payrollCode,
                      ),
                      _InfoTile(
                        icon: Icons.account_tree_outlined,
                        label: 'Reports to',
                        value: self?.manager?.name,
                      ),
                      // Vehicle type comes from the claim preview (doc 05).
                      // Hidden when unavailable (e.g. 403 / no permission).
                      if (vehicleType != null)
                        _InfoTile(
                          icon: vehicleType == 'four_wheeler'
                              ? Icons.directions_car_outlined
                              : Icons.two_wheeler_outlined,
                          label: 'Vehicle type',
                          value: _vehicleLabel(vehicleType),
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
                  const SizedBox(height: 20),

                  _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      if (canViewTeam)
                        _ActionTile(
                          icon: Icons.groups_outlined,
                          label: 'My team',
                          onTap: () =>
                              Navigator.pushNamed(context, '/my-team'),
                          isLast: false,
                        ),
                      _ActionTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change password',
                        onTap: () =>
                            Navigator.pushNamed(context, '/change-password'),
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  static String _vehicleLabel(String raw) {
    switch (raw) {
      case 'two_wheeler':
        return 'Bike (2W)';
      case 'four_wheeler':
        return 'Car (4W)';
      default:
        return raw.replaceAll('_', ' ');
    }
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
  final bool isUploading;
  final VoidCallback onTapPhoto;

  const _ProfileHeader({
    required this.fullName,
    required this.designation,
    required this.profileUrl,
    required this.isUploading,
    required this.onTapPhoto,
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
          GestureDetector(
            onTap: isUploading ? null : onTapPhoto,
            child: Stack(
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                  ),
                ),
              ],
            ),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
