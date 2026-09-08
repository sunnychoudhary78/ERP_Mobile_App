import 'package:erp_app/core/permissions/nav_links.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/home/presentation/screens/home_screen.dart'
    show showLogoutConfirmationDialog;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerStatefulWidget {
  final String fullName;
  final String? jobTitle;
  final String initials;
  final List<LinkSection> sections;
  final String? currentRoute;

  const AppDrawer({
    required this.fullName,
    this.jobTitle,
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
  static const String _profileRoute = '/profile';

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
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                    child: Text(
                      'OVERVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  // 1. Home Tile
                  _buildNavTile(
                    icon: Icons.grid_view_rounded,
                    title: 'Home',
                    route: _homeRoute,
                    onTap: () {
                      setState(() => _selectedRoute = _homeRoute);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 4),

                  // 2. Profile Tile
                  _buildNavTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    route: _profileRoute,
                    onTap: () {
                      setState(() => _selectedRoute = _profileRoute);
                      Navigator.pop(context);
                      Navigator.pushNamed(context, _profileRoute);
                    },
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'MODULES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  // Dynamic Sections (Accordion style)
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
    final profile = ref.watch(authProvider).profile;
    final dynamicJobTitle =
        widget.jobTitle ??
        (profile?.designation != null && profile!.designation!.trim().isNotEmpty
            ? profile.designation!
            : 'Operations Manager');

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, _profileRoute);
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  widget.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dynamicJobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String route,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedRoute == route;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        horizontalTitleGap: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.text,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? AppColors.primary : AppColors.text,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, LinkSection section) {
    final bool isExpanded = _expandedState[section.title] ?? false;
    final String displayTitle = _displayTitle(section.title);

    return Column(
      children: [
        Material(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            dense: true,
            horizontalTitleGap: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(
              _getSectionIcon(section.title),
              color: isExpanded ? AppColors.primary : AppColors.text,
              size: 22,
            ),
            title: Text(
              displayTitle,
              style: TextStyle(
                fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                color: isExpanded ? AppColors.primary : AppColors.text,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isExpanded ? AppColors.primary : AppColors.muted,
                size: 20,
              ),
            ),
            onTap: () {
              setState(() {
                // Single drawer expansion logic
                for (final key in _expandedState.keys) {
                  if (key != section.title) {
                    _expandedState[key] = false;
                  }
                }
                _expandedState[section.title] = !isExpanded;
              });
            },
          ),
        ),

        // Animated expansion container
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 28, top: 4, bottom: 8),
            child: Column(
              children: section.links.map((link) {
                final bool isSelected = _selectedRoute == link.route;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _selectedRoute = link.route);
                            Navigator.pop(context);
                            Navigator.pushNamed(context, link.route);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              link.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.text.withValues(alpha: 0.85),
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
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
            onTap: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMMORTAL ERP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.text.withValues(alpha: 0.6),
                ),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') || t.contains('hrms') || t.contains('leave')) {
      return Icons.badge_outlined;
    } else if (t.contains('crm')) {
      return Icons.groups_outlined;
    } else if (t.contains('inventory') ||
        t.contains('field') ||
        t.contains('stock')) {
      return Icons.inventory_2_outlined;
    } else if (t.contains('tracking')) {
      return Icons.location_on_outlined;
    } else if (t.contains('production')) {
      return Icons.precision_manufacturing_outlined;
    } else if (t.contains('setting')) {
      return Icons.settings_outlined;
    }
    return Icons.folder_open_rounded;
  }

  String _displayTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') && t.contains('leave')) {
      return 'HRMS';
    }
    return title;
  }
}