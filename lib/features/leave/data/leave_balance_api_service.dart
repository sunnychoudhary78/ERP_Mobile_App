import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveBalanceApiService {
  final ApiService api;

  LeaveBalanceApiService(this.api);

  Future<List<dynamic>> fetchLeaveBalance() async {
    final response = await api.get(ApiEndpoints.employeeLeaveBalance);

    if (response is List) return response;

    if (response is Map && response['data'] is List) {
      return response['data'] as List;
    }

    throw Exception('Unexpected leave balance response');
  }
}
