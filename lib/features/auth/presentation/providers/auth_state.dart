import '../../data/models/user_details_model.dart';
import '../../data/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final User? authUser;
  final UserDetails? profile;
  final String profileUrl;
  final String companyLogoUrl;
  final bool isSubscriptionExpired;
  final List<String> permissions;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isInitializing = true,
    this.authUser,
    this.profile,
    this.profileUrl = '',
    this.companyLogoUrl = '',
    this.permissions = const [],
    this.isSubscriptionExpired = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    User? authUser,
    UserDetails? profile,
    String? profileUrl,
    String? companyLogoUrl,
    bool? isSubscriptionExpired,
    List<String>? permissions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      authUser: authUser ?? this.authUser,
      profile: profile ?? this.profile,
      profileUrl: profileUrl ?? this.profileUrl,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      permissions: permissions ?? this.permissions,
      isSubscriptionExpired:
          isSubscriptionExpired ?? this.isSubscriptionExpired,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
