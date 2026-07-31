import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../leave/data/leave_approve_api_service.dart';
import '../../data/approvals_api_service.dart';
import '../../data/models/approval_inbox_item.dart';

final approvalsApiProvider = Provider<ApprovalsApiService>((ref) {
  final leaveApi = LeaveApproveApiService(ref.read(apiServiceProvider));
  return ApprovalsApiService(leaveApi);
});

final approvalsInboxProvider = AsyncNotifierProvider.autoDispose<
    ApprovalsInboxNotifier, List<ApprovalInboxItem>>(
  ApprovalsInboxNotifier.new,
);

class ApprovalsInboxNotifier
    extends AsyncNotifier<List<ApprovalInboxItem>> {
  @override
  Future<List<ApprovalInboxItem>> build() async {
    ref.watch(authProvider);
    return ref.read(approvalsApiProvider).fetchInbox();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Approve a leave inbox item. [dates] defaults to the request's dates.
  Future<void> approveLeave(
    ApprovalInboxItem item, {
    String? comment,
    List<Map<String, dynamic>>? dates,
  }) async {
    if (item.type != ApprovalInboxType.leave || item.leaveRequest == null) {
      throw Exception('Only leave approvals are supported currently');
    }

    final leave = item.leaveRequest!;
    final approvedDates = dates ?? leave.requestedDates;

    await ref.read(approvalsApiProvider).approveLeave(
          item.id,
          comment,
          approvedDates,
        );
    await refresh();
  }

  Future<void> rejectLeave(
    ApprovalInboxItem item, {
    String? comment,
  }) async {
    if (item.type != ApprovalInboxType.leave) {
      throw Exception('Only leave approvals are supported currently');
    }

    await ref.read(approvalsApiProvider).rejectLeave(item.id, comment);
    await refresh();
  }

  List<ApprovalInboxItem> get pending =>
      (state.value ?? const [])
          .where((e) => e.status.toLowerCase() == 'pending')
          .toList();
}
