import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../data/leave_details_api_service.dart';
import '../../data/models/leave_details_model.dart';

final leaveDetailsApiProvider = Provider<LeaveDetailsApiService>((ref) {
  return LeaveDetailsApiService(ref.read(apiServiceProvider));
});

final leaveDetailsProvider =
    FutureProvider.autoDispose.family<LeaveDetails, String>((ref, leaveId) async {
  final json =
      await ref.read(leaveDetailsApiProvider).fetchLeaveDetails(leaveId);
  return LeaveDetails.fromJson(json);
});
