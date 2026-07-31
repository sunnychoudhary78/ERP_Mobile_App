import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------
/// DrawerTile — tap hote hi background turant highlight ho jata h
/// (InkWell ka splash/highlight color explicitly set kiya h taaki
/// press instantly visible ho), aur "selected" state persistent
/// pill-background dikhata h. Dot indicator hata diya gaya h.
/// ---------------------------------------------------------------------
class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;

  const DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconColor,
    this.labelColor,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppColors.primary;
    final Color resolvedIconColor =
        selected ? activeColor : (iconColor ?? AppColors.muted);
    final Color resolvedLabelColor =
        selected ? activeColor : (labelColor ?? const Color(0xFF1F2933));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          // Splash/highlight color explicit rakha h taaki tap karte hi
          // background turant aur clearly dikhe (press feedback).
          splashColor: activeColor.withValues(alpha: 0.14),
          highlightColor: activeColor.withValues(alpha: 0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(color: activeColor.withValues(alpha: 0.18))
                  : null,
            ),
            child: Row(
              children: [
                // Icon ko soft rounded container ke andar rakha h — clean/modern look
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? activeColor.withValues(alpha: 0.16)
                        : const Color(0xFFF3F5F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: resolvedIconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      color: resolvedLabelColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends ConsumerStatefulWidget {
  final String fullName;
  final String initials;
  final List<LinkSection> sections;

  /// Optional — current route ka naam pass karo taaki us tile/link ko
  /// highlight kiya ja sake. Agar pass nahi kiya toh default "Home" highlight hoga.
  final String? currentRoute;

  const AppDrawer({
    required this.fullName,
    required this.initials,
    required this.sections,
    this.currentRoute,
    super.key,
  });

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  // Har section expanded/collapsed state track karne ke liye
  late final Map<String, bool> _expandedState;

  // Local selection state — tap karte hi turant highlight ho jaye,
  // parent se currentRoute update hone ka wait nahi karna padta.
  late String _selectedRoute;

  static const String _homeRoute = '/home';

  @override
  void initState() {
    super.initState();
    _expandedState = {
      for (final section in widget.sections) section.title: false,
    };
    _selectedRoute = widget.currentRoute ?? _homeRoute;

    // Jis section ke andar active link hai use by-default expanded rakho —
    // isse drawer khulte hi khaali nahi lagta, seedha context dikhta hai.
    for (final section in widget.sections) {
      if (section.links.any((link) => link.route == _selectedRoute)) {
        _expandedState[section.title] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F8FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),

            // Navigation Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 8),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.muted.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  // 1. Home
                  DrawerTile(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _selectedRoute == _homeRoute,
                    onTap: () {
                      setState(() => _selectedRoute = _homeRoute);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 6),
                  _sectionDivider(),
                  const SizedBox(height: 4),

                  // Dynamic Sections (HRMS, CRM, Inventory, etc.)
                  for (final section in widget.sections)
                    // Agar backend se koi section empty milta h, toh wo render nahi hoga
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

  // -----------------------------------------------------------------
  // Header — gradient background, avatar with clean ring, name +
  // aaj ki date wala chip (page khaali na lage isliye thoda context)
  // -----------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final String today = _formattedDate(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Aaj ki date wala info strip — header ko khaali lagne se rokta h
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  today,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.notifications_none_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Divider(height: 1, color: Color(0xFFE7E9EC)),
    );
  }

  // -----------------------------------------------------------------
  // Section tile — custom expandable (ExpansionTile ki jagah), taaki
  // rotation/animation aur highlight fully control ho sake. Link count
  // badge add kiya h taaki list zyada "filled" aur informative lage.
  // -----------------------------------------------------------------
  Widget _buildSectionTile(BuildContext context, LinkSection section) {
    final bool isExpanded = _expandedState[section.title] ?? false;
    final bool sectionHasActiveLink = section.links.any(
      (link) => link.route == _selectedRoute,
    );
    // Header khud ek route pe navigate nahi karta (sirf expand/collapse
    // karta h), isliye "expanded" hone par bhi usko highlight treat karo —
    // isse Home tile jaisa hi turant "maine ye click kiya" feedback milta h.
    final bool isHeaderActive = sectionHasActiveLink || isExpanded;
    final String displayTitle = _displayTitle(section.title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashColor: AppColors.primary.withValues(alpha: 0.12),
              highlightColor: AppColors.primary.withValues(alpha: 0.08),
              onTap: () {
                setState(() {
                  _expandedState[section.title] = !isExpanded;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isHeaderActive
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHeaderActive
                        ? AppColors.primary.withValues(alpha: 0.22)
                        : const Color(0xFFEDEFF2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHeaderActive
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getSectionIcon(section.title),
                        size: 18,
                        color: isHeaderActive
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: TextStyle(
                          fontWeight:
                              isHeaderActive ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          color: isHeaderActive
                              ? AppColors.primary
                              : const Color(0xFF1F2933),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Section ke andar kitne links h — ek chhota count badge
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${section.links.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isHeaderActive
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 14, top: 6, bottom: 4),
              child: Column(
                children: section.links.map((link) {
                  final bool isSelected = link.route == _selectedRoute;
                  return DrawerTile(
                    icon: link.icon,
                    label: link.label,
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedRoute = link.route);
                      Navigator.pop(context);
                      Navigator.pushNamed(context, link.route);
                    },
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Footer — logout + app version, clean aur minimal
  // -----------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionDivider(),
        const SizedBox(height: 4),
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
        const SizedBox(height: 6),
        Text(
          'Immortal ERP  •  v1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.muted.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
      ],
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

  // Backend se aane wale section title ko display ke liye friendly naam
  // dene ka helper — e.g. "Attendance & Leave" ko "HRMS" dikhana h.
  // NOTE: Ye sirf UI label change karta h, backend/route data same rehta h.
  // Agar tum backend/parent screen me hi title "HRMS" bhejna start kar do,
  // toh ye override apne aap redundant ho jayega — waha karna zyada clean h.
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
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}