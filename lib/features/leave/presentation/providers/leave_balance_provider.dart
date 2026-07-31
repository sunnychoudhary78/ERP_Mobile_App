import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/leave_balance_api_service.dart';
import '../../data/models/leave_balance_model.dart';

final leaveBalanceApiProvider = Provider<LeaveBalanceApiService>((ref) {
  return LeaveBalanceApiService(ref.read(apiServiceProvider));
});

final leaveBalanceProvider =
    AsyncNotifierProvider.autoDispose<LeaveBalanceNotifier, List<LeaveBalance>>(
  LeaveBalanceNotifier.new,
);

class LeaveBalanceNotifier extends AsyncNotifier<List<LeaveBalance>> {
  @override
  Future<List<LeaveBalance>> build() async {
    ref.watch(authProvider);

    final balances = await ref.read(leaveBalanceApiProvider).fetchLeaveBalance();

    return balances
        .map((e) => LeaveBalance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
