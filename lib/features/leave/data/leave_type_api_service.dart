import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveTypeApiService {
  final ApiService api;

  LeaveTypeApiService(this.api);

  Future<List<dynamic>> fetchLeaveTypes() async {
    final response = await api.get(ApiEndpoints.leaveTypes);

    if (response is List) return response;

    if (response is Map && response['data'] is List) {
      return response['data'] as List;
    }

    throw Exception('Unexpected leave types response');
  }
}
