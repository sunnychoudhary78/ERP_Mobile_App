import 'package:erp_app/features/hrms/data/hrms_api_services.dart';
import 'package:erp_app/features/hrms/data/model/hrms_model.dart';
import 'package:erp_app/features/hrms/presentation/repositry/hrms_repoistry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_app/core/providers/network_providers.dart';
/// Assumes `network_providers.dart` exposes `apiServiceProvider` that
/// returns your existing `ApiService` (Dio + CryptoHelper + auth
/// interceptors already wired). If the actual provider is named
/// differently, just change the reference below — everything else
/// stays the same since HrmsApiService only depends on ApiService's
/// public get() method.
final hrmsApiServiceProvider = Provider<HrmsApiService>((ref) {
  return HrmsApiService(ref.watch(apiServiceProvider));
});

final hrmsRepositoryProvider = Provider<HrmsRepository>((ref) {
  return HrmsRepository(ref.watch(hrmsApiServiceProvider));
});

/// Permissions — drives which dashboard sections render.
final hrmsPermissionsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(hrmsApiServiceProvider).getPermissions();
});

final isManagerProvider = Provider<bool>((ref) {
  final perms = ref.watch(hrmsPermissionsProvider).asData?.value ?? {};
  return perms.contains('team.dashboard.view');
});

final isAdminProvider = Provider<bool>((ref) {
  final perms = ref.watch(hrmsPermissionsProvider).asData?.value ?? {};
  return perms.contains('stats.view');
});

/// Main dashboard data — refresh by invalidating this provider
/// (e.g. pull-to-refresh, or after a successful punch).
final hrmsDashboardProvider =
    FutureProvider.autoDispose<HrmsHomeModel>((ref) async {
  // Wait for permissions first so we know whether to fan out into
  // manager/admin calls.
  final perms = await ref.watch(hrmsPermissionsProvider.future);
  final isManager = perms.contains('team.dashboard.view');
  final isAdmin = perms.contains('stats.view');

  return ref.watch(hrmsRepositoryProvider).loadDashboard(
        isManager: isManager,
        isAdmin: isAdmin,
      );
});