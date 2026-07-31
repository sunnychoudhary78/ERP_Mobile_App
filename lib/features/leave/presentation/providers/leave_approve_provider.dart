import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/leave_approve_api_service.dart';
import '../../data/models/leave_approve_model.dart';

final leaveApproveApiProvider = Provider<LeaveApproveApiService>((ref) {
  return LeaveApproveApiService(ref.read(apiServiceProvider));
});

final leaveApproveProvider = AsyncNotifierProvider.autoDispose<
    LeaveApproveNotifier, List<ManagerLeaveRequest>>(
  LeaveApproveNotifier.new,
);

class LeaveApproveNotifier extends AsyncNotifier<List<ManagerLeaveRequest>> {
  @override
  Future<List<ManagerLeaveRequest>> build() async {
    ref.watch(authProvider);

    final list =
        await ref.read(leaveApproveApiProvider).fetchManagerRequests();

    return list
        .map(
          (e) =>
              ManagerLeaveRequest.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> approve(
    String id,
    String? comment,
    List<Map<String, dynamic>> dates,
  ) async {
    await ref.read(leaveApproveApiProvider).approveLeave(id, comment, dates);
    await refresh();
  }

  Future<void> reject(String id, String? comment) async {
    await ref.read(leaveApproveApiProvider).rejectLeave(id, comment);
    await refresh();
  }
}
