import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/leave_status_api_service.dart';
import '../../data/models/leave_status_model.dart';

final leaveStatusApiProvider = Provider<LeaveStatusApiService>((ref) {
  return LeaveStatusApiService(ref.read(apiServiceProvider));
});

final leaveStatusProvider =
    AsyncNotifierProvider.autoDispose<LeaveStatusNotifier, List<LeaveStatus>>(
  LeaveStatusNotifier.new,
);

class LeaveStatusNotifier extends AsyncNotifier<List<LeaveStatus>> {
  @override
  Future<List<LeaveStatus>> build() async {
    ref.watch(authProvider);

    final list = await ref.read(leaveStatusApiProvider).fetchLeaveStatus();

    return list
        .map((e) => LeaveStatus.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> revokeLeave(String id) async {
    await ref.read(leaveStatusApiProvider).revokeLeave(requestId: id);
    await refresh();
  }
}
