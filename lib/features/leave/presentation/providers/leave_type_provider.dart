import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/leave_type_api_service.dart';
import '../../data/models/leave_type_model.dart';

final leaveTypeApiProvider = Provider<LeaveTypeApiService>((ref) {
  return LeaveTypeApiService(ref.read(apiServiceProvider));
});

final leaveTypeProvider =
    AsyncNotifierProvider.autoDispose<LeaveTypeNotifier, List<LeaveType>>(
  LeaveTypeNotifier.new,
);

class LeaveTypeNotifier extends AsyncNotifier<List<LeaveType>> {
  @override
  Future<List<LeaveType>> build() async {
    ref.watch(authProvider);

    final types = await ref.read(leaveTypeApiProvider).fetchLeaveTypes();

    return types
        .map((e) => LeaveType.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((t) => t.isActive)
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
