import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../../data/notification_api_service.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.read(apiServiceProvider));
});

final notificationProvider = AsyncNotifierProvider.autoDispose<
    NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

class NotificationNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    ref.watch(authProvider);
    return ref.read(notificationApiServiceProvider).fetchMyNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> markAsRead(String id) async {
    final api = ref.read(notificationApiServiceProvider);
    final currentList = state.value ?? const [];

    state = AsyncData([
      for (final n in currentList)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);

    try {
      await api.markAsRead(id);
    } catch (_) {
      state = AsyncData(currentList);
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    final api = ref.read(notificationApiServiceProvider);
    final currentList = state.value ?? const [];

    state = AsyncData(currentList.where((n) => n.id != id).toList());

    try {
      await api.deleteNotifications([id]);
    } catch (_) {
      state = AsyncData(currentList);
      rethrow;
    }
  }

  Future<void> deleteMultipleNotifications(List<String> ids) async {
    final api = ref.read(notificationApiServiceProvider);
    final currentList = state.value ?? const [];

    state = AsyncData(
      currentList.where((n) => !ids.contains(n.id)).toList(),
    );

    try {
      await api.deleteNotifications(ids);
    } catch (_) {
      state = AsyncData(currentList);
      rethrow;
    }
  }
}

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationProvider);

  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
