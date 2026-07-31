import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';
import 'models/notification_model.dart';

class NotificationApiService {
  final ApiService api;

  NotificationApiService(this.api);

  Future<List<AppNotification>> fetchMyNotifications() async {
    final response = await api.get(ApiEndpoints.notificationsMy);

    List list;
    if (response is Map && response['data'] is List) {
      list = response['data'] as List;
    } else if (response is List) {
      list = response;
    } else {
      throw Exception('Unexpected notifications response');
    }

    return list
        .map(
          (e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await api.patch(ApiEndpoints.notificationMarkRead(id), {});
  }

  Future<void> deleteNotifications(List<String> ids) async {
    await api.delete(ApiEndpoints.notifications, {'ids': ids});
  }
}
