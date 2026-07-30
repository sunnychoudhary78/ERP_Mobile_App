import 'package:erp_app/features/attendance/models/mobile_config.dart';
import 'package:erp_app/features/attendance/models/attendance_session_model.dart';
class AttendanceState {
  final bool isLoading;
  final bool isSubmitting;
  final AttendanceConfig config;
  final AttendanceSession? todaySession;
  final String? errorMessage;
  final String? successMessage;

  const AttendanceState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.config = const AttendanceConfig(),
    this.todaySession,
    this.errorMessage,
    this.successMessage,
  });

  bool get isPunchedIn => todaySession?.isOpen ?? false;

  AttendanceState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    AttendanceConfig? config,
    AttendanceSession? todaySession,
    bool clearSession = false,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      config: config ?? this.config,
      todaySession: clearSession ? null : (todaySession ?? this.todaySession),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}