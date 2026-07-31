import '../../../leave/data/models/leave_approve_model.dart';

/// Discriminator for unified approvals inbox.
/// CRM can be added later without changing leave consumers.
enum ApprovalInboxType { leave }

class ApprovalInboxItem {
  final ApprovalInboxType type;
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final DateTime? createdAt;

  /// Present when [type] == [ApprovalInboxType.leave].
  final ManagerLeaveRequest? leaveRequest;

  const ApprovalInboxItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.createdAt,
    this.leaveRequest,
  });

  factory ApprovalInboxItem.fromLeave(ManagerLeaveRequest leave) {
    final range = leave.startDate == leave.endDate
        ? leave.startDate
        : '${leave.startDate} → ${leave.endDate}';

    return ApprovalInboxItem(
      type: ApprovalInboxType.leave,
      id: leave.id,
      title: leave.employeeName.isEmpty ? 'Leave request' : leave.employeeName,
      subtitle: [
        if (leave.leaveType.isNotEmpty) leave.leaveType,
        range,
      ].where((e) => e.isNotEmpty).join(' · '),
      status: leave.status,
      leaveRequest: leave,
    );
  }
}
