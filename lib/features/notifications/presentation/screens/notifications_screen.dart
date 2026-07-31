import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    final count = ids.length;
    _clearSelection();
    await ref
        .read(notificationProvider.notifier)
        .deleteMultipleNotifications(ids);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count notification(s) deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _isSelecting
          ? _buildSelectionAppBar()
          : _buildDefaultAppBar(unread),
      body: async.when(
        loading: () => const _NotificationsLoading(),
        error: (e, _) => _NotificationsError(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.read(notificationProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(notificationProvider.notifier).refresh(),
              child: const _NotificationsEmpty(),
            );
          }

          final groups = _groupByDay(items);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(label: group.label),
                    const SizedBox(height: 8),
                    ...group.items.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          notification: n,
                          isSelected: _selectedIds.contains(n.id),
                          isSelecting: _isSelecting,
                          onTap: () {
                            if (_isSelecting) {
                              _toggleSelect(n.id);
                            } else {
                              if (!n.isRead) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .markAsRead(n.id);
                              }
                              // TODO: navigate to notification detail screen
                            }
                          },
                          onLongPress: () => _toggleSelect(n.id),
                          onDelete: () => ref
                              .read(notificationProvider.notifier)
                              .deleteNotification(n.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(int unread) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: () =>
                ref.read(notificationProvider.notifier).markAsRead(''),
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.text),
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedIds.length} selected',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: _deleteSelected,
          tooltip: 'Delete selected',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  List<_NotificationGroup> _groupByDay(List<dynamic> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, List<dynamic>>{};
    for (final n in items) {
      final DateTime createdAt = n.createdAt;
      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('d MMMM yyyy').format(day);
      }
      map.putIfAbsent(label, () => []).add(n);
    }

    return map.entries
        .map((e) => _NotificationGroup(label: e.key, items: e.value))
        .toList();
  }
}

class _NotificationGroup {
  final String label;
  final List<dynamic> items;
  _NotificationGroup({required this.label, required this.items});
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification; // expects: id, title, body, isRead, createdAt, type (optional)
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.isSelected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  IconData _iconForType(String? type) {
    switch (type) {
      case 'attendance':
        return Icons.fingerprint_rounded;
      case 'leave':
        return Icons.event_available_rounded;
      case 'sales':
        return Icons.trending_up_rounded;
      case 'stock':
        return Icons.inventory_2_rounded;
      case 'work_order':
        return Icons.assignment_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'birthday':
        return Icons.cake_rounded;
      case 'work_anniversary':
        return Icons.military_tech_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  bool _isCelebration(String? type) =>
      type == 'birthday' || type == 'work_anniversary';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead as bool;
    final String title = notification.title as String;
    final String body = notification.body as String;
    final DateTime createdAt = notification.createdAt as DateTime;
    final String? type = (notification.type as String?);
    final String id = notification.id as String;

    return Dismissible(
      key: ValueKey(id),
      direction: isSelecting
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return true;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : (isRead ? AppColors.surface : AppColors.accent.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : AppColors.muted,
                      size: 22,
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _isCelebration(type)
                          ? const Color(0xFFF5A623).withOpacity(0.15)
                          : (isRead
                              ? AppColors.muted.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconForType(type),
                      size: 20,
                      color: _isCelebration(type)
                          ? const Color(0xFFF5A623)
                          : (isRead ? AppColors.muted : AppColors.primary),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14.5,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(createdAt),
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text.withOpacity(0.72),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead && !isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.muted.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You\'re all caught up. New updates about\nattendance, leave, sales and stock will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 34, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}