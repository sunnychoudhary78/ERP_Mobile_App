import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerStatefulWidget {
  final String fullName;
  final String jobTitle;
  final String initials;
  final List<LinkSection> sections;
  final String? currentRoute;

  const AppDrawer({
    required this.fullName,
    this.jobTitle = 'Operations Manager',
    required this.initials,
    required this.sections,
    this.currentRoute,
    super.key,
  });

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  late final Map<String, bool> _expandedState;
  late String _selectedRoute;

  static const String _homeRoute = '/home';

  @override
  void initState() {
    super.initState();
    _expandedState = {
      for (final section in widget.sections) section.title: false,
    };
    _selectedRoute = widget.currentRoute ?? _homeRoute;

    for (final section in widget.sections) {
      if (section.links.any((link) => link.route == _selectedRoute)) {
        _expandedState[section.title] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),

            // Navigation Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 12, top: 4),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: AppColors.muted.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  // 1. Home Tile (Selected Card Visual)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: _selectedRoute == _homeRoute
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          Icons.home_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        title: Text(
                          'Home',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedRoute = _homeRoute);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dynamic Sections (HRMS, CRM, Inventory, etc.)
                  for (final section in widget.sections)
                    if (section.links.isNotEmpty)
                      _buildSectionTile(context, section),
                ],
              ),
            ),

            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final String today = _formattedDate(DateTime.now());

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.jobTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View Profile Pill
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Date & Notification Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  today,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 20, color: Colors.white),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
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

  Widget _buildSectionTile(BuildContext context, LinkSection section) {
    final bool isExpanded = _expandedState[section.title] ?? false;
    final String displayTitle = _displayTitle(section.title);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(
              _getSectionIcon(section.title),
              color: AppColors.text,
              size: 22,
            ),
            title: Text(
              displayTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.text,
              ),
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
            onTap: () {
              setState(() {
                _expandedState[section.title] = !isExpanded;
              });
            },
          ),
        ),

        // Expanded Links with Vertical Guide Indicator Line
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 2, bottom: 8),
            child: Column(
              children: section.links.map((link) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      // Sub-item tree line indicator
                      Container(
                        width: 1.5,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedRoute = link.route);
                            Navigator.pop(context);
                            Navigator.pushNamed(context, link.route);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              link.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 16, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMMORTAL ERP  •  V1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cloud Industrial Solution',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getSectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') || t.contains('hrms') || t.contains('leave')) {
      return Icons.badge_outlined;
    } else if (t.contains('crm')) {
      return Icons.groups_outlined;
    } else if (t.contains('inventory') || t.contains('field') || t.contains('stock')) {
      return Icons.assignment_outlined;
    } else if (t.contains('setting')) {
      return Icons.settings_outlined;
    }
    return Icons.folder_outlined;
  }

  String _displayTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') && t.contains('leave')) {
      return 'HRMS';
    }
    return title;
  }

  String _formattedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}