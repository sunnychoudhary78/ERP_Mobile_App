import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/screens/splash_loading_screen.dart';
import '../core/screens/subscription_expired_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _autoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoLoginAttempted) return;
      _autoLoginAttempted = true;

      final auth = ref.read(authProvider);
      if (auth.isInitializing && !auth.isSubscriptionExpired) {
        ref.read(authProvider.notifier).tryAutoLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isInitializing) {
      return const SplashLoadingScreen();
    }

    if (authState.isSubscriptionExpired) {
      return const SubscriptionExpiredScreen();
    }

    if (authState.profile == null) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
