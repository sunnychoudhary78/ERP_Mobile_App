import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../data/leave_apply_api_service.dart';

final leaveApplyApiProvider = Provider<LeaveApplyApiService>((ref) {
  return LeaveApplyApiService(ref.read(apiServiceProvider));
});

enum LeaveApplyStatus { idle, loading, success, error }

class LeaveApplyState {
  final LeaveApplyStatus status;
  final String? message;

  const LeaveApplyState({required this.status, this.message});

  const LeaveApplyState.idle()
      : status = LeaveApplyStatus.idle,
        message = null;
}

final leaveApplyProvider =
    NotifierProvider.autoDispose<LeaveApplyNotifier, LeaveApplyState>(
  LeaveApplyNotifier.new,
);

class LeaveApplyNotifier extends Notifier<LeaveApplyState> {
  @override
  LeaveApplyState build() => const LeaveApplyState.idle();

  Future<void> submitLeave({
    required Map<String, dynamic> data,
    File? document,
  }) async {
    final api = ref.read(leaveApplyApiProvider);

    state = const LeaveApplyState(status: LeaveApplyStatus.loading);

    try {
      await api.sendLeaveRequestWithDocument(data: data, document: document);
      state = const LeaveApplyState(
        status: LeaveApplyStatus.success,
        message: 'Leave applied successfully',
      );
    } catch (e) {
      state = LeaveApplyState(
        status: LeaveApplyStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const LeaveApplyState.idle();
  }
}
