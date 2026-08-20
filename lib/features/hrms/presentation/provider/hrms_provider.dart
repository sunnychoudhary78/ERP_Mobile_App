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
  return ref
      .watch(authProvider)
      .can(AppPermissions.teamDashboardRead);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).can(AppPermissions.statsRead);
});

/// Main dashboard data — refresh by invalidating this provider
/// (e.g. pull-to-refresh, or after a successful punch).
final hrmsDashboardProvider =
    FutureProvider.autoDispose<HrmsHomeModel>((ref) async {
  final auth = ref.watch(authProvider);
  final isManager = auth.can(AppPermissions.teamDashboardRead);
  final isAdmin = auth.can(AppPermissions.statsRead);

  return ref.watch(hrmsRepositoryProvider).loadDashboard(
        isManager: isManager,
        isAdmin: isAdmin,
      );
});
