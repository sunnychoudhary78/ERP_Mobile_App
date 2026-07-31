import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveStatusApiService {
  final ApiService api;

  LeaveStatusApiService(this.api);

  Future<List<dynamic>> fetchLeaveStatus() async {
    final response = await api.get(ApiEndpoints.leaveRequestsUserAll);

    if (response is Map && response['data'] is List) {
      return response['data'] as List;
    }

    if (response is List) return response;

    throw Exception('Unexpected leave status response');
  }

  Future<void> revokeLeave({
    required String requestId,
    String reason = 'Leave withdrawn by user',
  }) async {
    await api.patch(
      ApiEndpoints.leaveRequestWithdraw(requestId),
      {'reason': reason},
    );
  }
}
