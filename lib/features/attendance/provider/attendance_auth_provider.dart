import 'package:erp_app/core/providers/network_providers.dart';
import 'package:erp_app/features/attendance/data/attendance_api_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AttendanceApiService(api);
});