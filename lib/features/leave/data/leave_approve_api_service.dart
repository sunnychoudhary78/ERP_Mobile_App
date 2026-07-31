import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveApproveApiService {
  final ApiService api;

  LeaveApproveApiService(this.api);

  Future<List<dynamic>> fetchManagerRequests() async {
    final res = await api.get(ApiEndpoints.leaveRequestsManagerAll);

    if (res is Map && res['data'] is List) {
      return res['data'] as List;
    }

    if (res is List) return res;

    throw Exception('Invalid manager request response format');
  }

  Future<void> approveLeave(
    String requestId,
    String? comment,
    List<Map<String, dynamic>> approvedDates,
  ) async {
    await api.patch(
      ApiEndpoints.leaveRequestStatus(requestId),
      {
        'approvedDatesInput': approvedDates,
        'action': 'approve',
        'comment': comment ?? '',
      },
    );
  }

  Future<void> rejectLeave(String requestId, String? comment) async {
    await api.patch(
      ApiEndpoints.leaveRequestStatus(requestId),
      {
        'action': 'reject',
        'comment': comment ?? '',
      },
    );
  }
}
