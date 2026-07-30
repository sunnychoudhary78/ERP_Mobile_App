import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../network/api_service.dart';
import '../network/dio_client.dart';
import '../network/session_guard.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return DioClient(
    tokenStorage: tokenStorage,
    onSubscriptionExpired: () {
      ref.read(authProvider.notifier).forceSubscriptionExpired();
    },
  );
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return ApiService(dioClient.dio, ref);
});

final sessionGuardProvider = Provider<SessionGuard>((ref) {
  return SessionGuard();
});
