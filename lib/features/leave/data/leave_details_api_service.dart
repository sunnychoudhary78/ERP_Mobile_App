import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveDetailsApiService {
  final ApiService api;

  LeaveDetailsApiService(this.api);

  Future<Map<String, dynamic>> fetchLeaveDetails(String leaveId) async {
    final response = await api.get(ApiEndpoints.leaveRequestById(leaveId));

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);

    throw Exception('Invalid leave details response format');
  }
}
