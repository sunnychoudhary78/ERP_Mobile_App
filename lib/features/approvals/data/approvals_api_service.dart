import '../../leave/data/leave_approve_api_service.dart';
import '../../leave/data/models/leave_approve_model.dart';
import 'models/approval_inbox_item.dart';

/// Approvals inbox API — leave only for now; CRM later via [crm/approvals].
class ApprovalsApiService {
  final LeaveApproveApiService leaveApproveApi;

  ApprovalsApiService(this.leaveApproveApi);

  Future<List<ApprovalInboxItem>> fetchInbox() async {
    final list = await leaveApproveApi.fetchManagerRequests();

    return list
        .map(
          (e) => ApprovalInboxItem.fromLeave(
            ManagerLeaveRequest.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        )
        .toList();
  }

  Future<void> approveLeave(
    String requestId,
    String? comment,
    List<Map<String, dynamic>> approvedDates,
  ) {
    return leaveApproveApi.approveLeave(requestId, comment, approvedDates);
  }

  Future<void> rejectLeave(String requestId, String? comment) {
    return leaveApproveApi.rejectLeave(requestId, comment);
  }
}
