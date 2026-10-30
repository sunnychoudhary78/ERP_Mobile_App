import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/employee_self_model.dart';
import '../../data/models/team_member_model.dart';
import 'auth_api_providers.dart';

/// Self employee record — `GET /api/employees/single` (doc 05).
/// Provides manager, department, payroll code, contact.
final selfEmployeeProvider =
    FutureProvider.autoDispose<EmployeeSelf>((ref) async {
  return ref.watch(authApiServiceProvider).fetchSelfEmployee();
});

/// Vehicle type (2W/4W) — `GET /api/sales/claims/my/preview`.
/// Null when the user lacks claims permission (403) — the UI omits the row.
final vehicleTypeProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.watch(authApiServiceProvider).fetchVehicleType();
});

/// My team (managers only) — `GET /api/employees/team-dashboard`.
final myTeamProvider = FutureProvider.autoDispose<List<TeamMember>>((
  ref,
) async {
  return ref.watch(authApiServiceProvider).fetchMyTeam();
});
