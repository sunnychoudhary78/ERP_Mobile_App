import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/network_providers.dart';
import '../../data/auth_api_service.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthApiService(api);
});
