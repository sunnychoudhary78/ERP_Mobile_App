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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 12,
                      top: 4,
                    ),
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
    // Watch profile to dynamically retrieve designation/job title
    final profile = ref.watch(authProvider).profile;
    final dynamicJobTitle =
        widget.jobTitle ??
        (profile?.designation != null && profile!.designation!.trim().isNotEmpty
            ? profile.designation!
            : 'Operations Manager');

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
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
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
                      dynamicJobTitle,
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

        // Expanded links
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 2, bottom: 8),
            child: Column(
              children: section.links.map((link) {
                final bool isSelected = _selectedRoute == link.route;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vertical guide line
                      Container(
                        width: 1.5,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _selectedRoute = link.route;
                            });

                            Navigator.pop(context);
                            Navigator.pushNamed(context, link.route);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.border.withValues(alpha: 0.30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              link.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                style: TextStyle(fontSize: 11, color: AppColors.muted),
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
    } else if (t.contains('inventory') ||
        t.contains('field') ||
        t.contains('stock')) {
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

}
