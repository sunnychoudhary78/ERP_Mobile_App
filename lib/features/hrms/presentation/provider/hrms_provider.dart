import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/providers/network_providers.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/hrms/data/hrms_api_services.dart';
import 'package:erp_app/features/hrms/data/model/hrms_model.dart';
import 'package:erp_app/features/hrms/presentation/repositry/hrms_repoistry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hrmsApiServiceProvider = Provider<HrmsApiService>((ref) {
  return HrmsApiService(ref.watch(apiServiceProvider));
});

final hrmsRepositoryProvider = Provider<HrmsRepository>((ref) {
  return HrmsRepository(ref.watch(hrmsApiServiceProvider));
});

/// Single source of truth: auth session permissions (no duplicate fetch).
final hrmsPermissionsProvider = Provider<Set<String>>((ref) {
  return ref.watch(authProvider).permissions.toSet();
});

final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).canAny(AppPermissions.teamDashboard);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).canAny(AppPermissions.stats);
});

/// Main dashboard data — refresh by invalidating this provider
/// (e.g. pull-to-refresh, or after a successful punch).
final hrmsDashboardProvider =
    FutureProvider.autoDispose<HrmsHomeModel>((ref) async {
  final auth = ref.watch(authProvider);
  final isManager = auth.canAny(AppPermissions.teamDashboard);
  final isAdmin = auth.canAny(AppPermissions.stats);
  final canApproveLeaves = auth.canAny(AppPermissions.leaveApprovals);

  return ref.watch(hrmsRepositoryProvider).loadDashboard(
        isManager: isManager,
        isAdmin: isAdmin,
        canApproveLeaves: canApproveLeaves,
      );
});
