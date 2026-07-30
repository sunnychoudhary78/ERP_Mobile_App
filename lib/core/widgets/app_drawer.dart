import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: iconColor ?? AppColors.muted),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: labelColor ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}

class AppDrawer extends ConsumerWidget {
  final String fullName;
  final String initials;
  final List<LinkSection> sections;

  const AppDrawer({
    required this.fullName,
    required this.initials,
    required this.sections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Profile Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Navigation Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 1. Home
                  DrawerTile(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),

                  // Dynamic Sections (HRMS, CRM, Inventory, etc.)
                  for (final section in sections)
                    // Agar backend se koi section empty milta h, toh wo render nahi hoga
                    if (section.links.isNotEmpty)
                      Theme(
                        // ExpansionTile ke top/bottom borders/dividers remove karne ke liye
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          dense: true,
                          leading: Icon(
                            _getSectionIcon(section.title),
                            size: 20,
                            color: AppColors.muted,
                          ),
                          title: Text(
                            section.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          children: section.links.map((link) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: DrawerTile(
                                icon: link.icon,
                                label: link.label,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, link.route);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Logout Option
            DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              iconColor: Colors.red.shade400,
              labelColor: Colors.red.shade400,
              onTap: () async {
                final confirmed = await showLogoutConfirmationDialog(context);
                if (confirmed == true && context.mounted) {
                  Navigator.pop(context); // close the drawer
                  ref.read(authProvider.notifier).logout();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Section title ke according Icon select karne ke liye helper method
  IconData _getSectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('attendance') || t.contains('hrms') || t.contains('leave')) {
      return Icons.badge_outlined;
    } else if (t.contains('crm')) {
      return Icons.groups_outlined;
    } else if (t.contains('inventory') || t.contains('field') || t.contains('stock')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.folder_outlined;
  }
}