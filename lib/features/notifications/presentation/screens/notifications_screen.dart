import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_provider.dart';

/// Logic wired via [notificationProvider] + [unreadCountProvider].
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(unread > 0 ? 'Notifications ($unread)' : 'Notifications'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(notificationProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logic ready — ${items.length} notification(s).',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'TODO (UI): list + detail.\n'
                'markAsRead(id) · deleteNotification(id)\n'
                'deleteMultipleNotifications(ids)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...items.map(
                (n) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: n.isRead
                      ? null
                      : const Icon(Icons.circle, size: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
