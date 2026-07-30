import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../main.dart';
import '../../data/auth_api_service.dart';
import '../../data/models/user_details_model.dart';
import 'auth_api_providers.dart';
import 'auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthApiService _authApi;
  late final TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _authApi = ref.read(authApiServiceProvider);
    _tokenStorage = ref.read(tokenStorageProvider);
    return const AuthState();
  }

  Future<void> tryAutoLogin() async {
    final jwt = await _tokenStorage.getJwt();

    if (jwt == null || jwt.isEmpty) {
      state = const AuthState(isLoading: false, isInitializing: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true, isSubscriptionExpired: false);

      final profileJson = await _authApi.fetchProfile();

      if (_isSubscriptionExpired(profileJson)) {
        await _tokenStorage.clear();
        forceSubscriptionExpired();
        return;
      }

      final profile = UserDetails.fromJson(profileJson);
      final permissions = await _authApi.fetchPermissions();

      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        profile: profile,
        permissions: permissions,
        profileUrl: profile.profilePicture != null
            ? ApiConstants.imageBaseUrl + profile.profilePicture!
            : '',
        companyLogoUrl: profile.companyLogoFilename != null
            ? ApiConstants.companyLogoBaseUrl + profile.companyLogoFilename!
            : '',
        clearError: true,
      );

      await _registerFcmIfAvailable();
    } catch (e) {
      if (e.toString().contains('SUBSCRIPTION_EXPIRED')) {
        state = const AuthState(
          isLoading: false,
          isInitializing: false,
          isSubscriptionExpired: true,
        );
        forceSubscriptionExpired();
        return;
      }

      await _tokenStorage.clear();
      state = const AuthState(isLoading: false, isInitializing: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      isSubscriptionExpired: false,
      clearError: true,
    );

    try {
      final userModel = await _authApi.login(email, password);
      await _tokenStorage.saveJwt(userModel.token);

      final profileJson = await _authApi.fetchProfile();

      if (_isSubscriptionExpired(profileJson)) {
        forceSubscriptionExpired();
        return;
      }

      final profile = UserDetails.fromJson(profileJson);
      final permissions = await _authApi.fetchPermissions();

      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        isSubscriptionExpired: false,
        authUser: userModel.user,
        profile: profile,
        permissions: permissions,
        profileUrl: profile.profilePicture != null
            ? ApiConstants.imageBaseUrl + profile.profilePicture!
            : '',
        companyLogoUrl: profile.companyLogoFilename != null
            ? ApiConstants.companyLogoBaseUrl + profile.companyLogoFilename!
            : '',
        clearError: true,
      );

      await _registerFcmIfAvailable();

      Future.microtask(() {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      });
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        errorMessage: message.contains('SUBSCRIPTION_EXPIRED')
            ? null
            : (message.isEmpty
                  ? 'Unable to login. Please try again.'
                  : message),
      );

      if (e.toString().contains('SUBSCRIPTION_EXPIRED')) {
        forceSubscriptionExpired();
      }
    }
  }

  bool _isSubscriptionExpired(Map<String, dynamic> profileJson) {
    try {
      final endDateStr = profileJson['company']?['subscription_end_date'];
      if (endDateStr == null) return false;
      final endDate = DateTime.parse(endDateStr).toLocal();
      return DateTime.now().isAfter(endDate);
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final jwt = await _tokenStorage.getJwt();
    final fcmToken = await _tokenStorage.getFcm();

    if (jwt != null &&
        jwt.isNotEmpty &&
        fcmToken != null &&
        fcmToken.isNotEmpty) {
      try {
        await _authApi.unregisterFcmToken(fcmToken: fcmToken);
      } catch (_) {}
    }

    await _tokenStorage.clear();
    state = const AuthState(isInitializing: false);

    Future.microtask(() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    });

    Root.restartApp();
  }

  void forceSubscriptionExpired() {
    state = state.copyWith(
      isInitializing: false,
      isSubscriptionExpired: true,
      isLoading: false,
    );

    Future.microtask(() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/subscription-expired',
        (route) => false,
      );
    });
  }



  void resetSubscriptionExpired() {
    state = state.copyWith(isSubscriptionExpired: false, isInitializing: false);

    Future.microtask(() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    });
  }

  Future<void> _registerFcmIfAvailable() async {
    final fcmToken = await _tokenStorage.getFcm();
    if (fcmToken == null || fcmToken.isEmpty) return;

    try {
      await _authApi.registerFcmToken(
        fcmToken: fcmToken,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (_) {}
  }

  Future<void> registerFcmTokenIfNeeded() async {
    await _registerFcmIfAvailable();
  }


  

  Future<void> forgotPassword(String email) async {
    await _authApi.forgotPassword(email);
  }
}
