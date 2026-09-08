import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:erp_app/features/attendance/provider/attendance_provider.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';

class PunchScreen extends ConsumerStatefulWidget {
  const PunchScreen({super.key});

  @override
  ConsumerState<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends ConsumerState<PunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(attendanceProvider.notifier).refreshStatus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<XFile?> _captureSelfie() async {
    final picker = ImagePicker();
    try {
      return await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1024,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _handlePunch(bool isCurrentlyPunchedIn) async {
    final notifier = ref.read(attendanceProvider.notifier);
    final config = ref.read(attendanceProvider).config;

    final needsSelfie = isCurrentlyPunchedIn
        ? config.requireMobileCheckoutSelfie
        : config.requireMobileCheckinSelfie;

    XFile? selfie;
    if (needsSelfie) {
      selfie = await _captureSelfie();
      if (selfie == null) {
        _showSnack('Selfie is required to continue', isError: true);
        return;
      }
    }

    setState(() => _actionInFlight = true);
    final success = isCurrentlyPunchedIn
        ? await notifier.punchOut(selfie: selfie)
        : await notifier.punchIn(selfie: selfie);
    if (mounted) setState(() => _actionInFlight = false);

    if (!mounted) return;
    final state = ref.read(attendanceProvider);
    if (success && state.successMessage != null) {
      _showSnack(state.successMessage!);
    } else if (!success && state.errorMessage != null) {
      _showSnack(state.errorMessage!, isError: true);
    }
    notifier.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final isPunchedIn = state.isPunchedIn;

    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    final now = DateTime.now();
    final currentTime = DateFormat('hh:mm a').format(now);
    final currentDate = DateFormat('EEEE, MMM d').format(now);

    final checkIn = state.todaySession?.checkInTime;
    final checkOut = state.todaySession?.checkOutTime;

    Duration workedDuration = Duration.zero;
    if (checkIn != null) {
      final endTime = checkOut ?? now;
      workedDuration = endTime.difference(checkIn);
    }

    final workedHours = workedDuration.inHours.toString().padLeft(2, '0');
    final workedMinutes = (workedDuration.inMinutes % 60).toString().padLeft(
      2,
      '0',
    );
    final hoursFormatted = '${workedHours}h ${workedMinutes}m';

    // Work schedule values derived dynamically from state/config
    // final shiftStartTime = state.config.shiftStartTime ?? '09:30 AM';
    // final shiftEndTime = state.config.shiftEndTime ?? '06:30 PM';
    // final targetMinutes = state.config.targetWorkMinutes ?? 540;
    // final targetHours = targetMinutes ~/ 60;
    // final targetMinsRemaining = targetMinutes % 60;
    // final shiftDurationStr = '${targetHours}h ${targetMinsRemaining.toString().padLeft(2, '0')}m';

    // final progressPercentage = (workedDuration.inMinutes / (targetMinutes == 0 ? 1 : targetMinutes)).clamp(0.0, 1.0);
    // final progressDisplay = '${(progressPercentage * 100).toInt()}%';

    final fullName = profile?.associatesName ?? '';
    final userName = fullName.trim().isEmpty
        ? 'there'
        : fullName.trim().split(RegExp(r'\s+')).first;
    final avatarUrl = authState.profileUrl;

    final greetingText = now.hour < 12
        ? 'Good Morning,'
        : now.hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';
    const greetingSubtext = 'Stay consistent, keep going!';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          children: const [
            Text(
              'Attendance',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Track your work hours and attendance',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E293B),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: state.isLoading
                ? null
                : () => ref.read(attendanceProvider.notifier).refreshStatus(),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting Header Banner Card
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Decorative background circles
                        Positioned(
                          right: -20,
                          top: -30,
                          child: Container(
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFDCE9FF),
                            ),
                          ),
                        ),

                        Positioned(
                          right: 55,
                          bottom: -45,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE4EEFF),
                            ),
                          ),
                        ),

                        // Main greeting content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                greetingText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                greetingSubtext,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right-side business illustration
                        Positioned(
                          right: 10,
                          bottom: 8,
                          child: SizedBox(
                            width: 125,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Small analytics card
                                Positioned(
                                  right: 5,
                                  top: 12,
                                  child: Container(
                                    width: 70,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(9),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF3B82F6),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const Text(
                                              'Sales',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Spacer(),

                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFBFDBFE),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 6,
                                              height: 21,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF93C5FD),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 6,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 6,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF60A5FA),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Laptop / workspace illustration
                                Positioned(
                                  left: 5,
                                  bottom: 3,
                                  child: Container(
                                    width: 82,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBD5E1),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF93C5FD),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFDBEAFE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 24,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE0F2FE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Small plant
                                Positioned(
                                  right: 0,
                                  bottom: 2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.eco_rounded,
                                        size: 25,
                                        color: Color(0xFF22C55E),
                                      ),
                                      Container(
                                        width: 18,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Floating notification dot
                                Positioned(
                                  left: 2,
                                  top: 5,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.auto_graph_rounded,
                                      size: 13,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date & Schedule Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentTime,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isPunchedIn
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFF94A3B8))
                                                .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 3,
                                            backgroundColor: isPunchedIn
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPunchedIn
                                                ? 'On Shift'
                                                : 'Off Shift',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isPunchedIn
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 70,
                          color: const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.business_center_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Work Schedule',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Text(
                                    //   '$shiftStartTime - $shiftEndTime',
                                    //   style: const TextStyle(
                                    //     fontSize: 11,
                                    //     color: Color(0xFF64748B),
                                    //   ),
                                    // ),
                                    // Text(
                                    //   '( $shiftDurationStr )',
                                    //   style: const TextStyle(
                                    //     fontSize: 11,
                                    //     color: Color(0xFF64748B),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Circular Punch Button Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isPunchedIn
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPunchedIn
                            ? const Color(0xFFD7F3DF)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main punch button — soft circular neumorphic style
                        Builder(
                          builder: (context) {
                            final bool isDisabled =
                                _actionInFlight ||
                                state.isSubmitting ||
                                state.isLoading;
                            final bool isBusy =
                                _actionInFlight || state.isSubmitting;
                            final Color accent = isPunchedIn
                                ? AppColors.danger
                                : const Color(0xFF16A34A);

                            return Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: isDisabled
                                        ? null
                                        : () => _handlePunch(isPunchedIn),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      opacity: isDisabled ? 0.55 : 1,
                                      child: Container(
                                        width: 132,
                                        height: 132,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFF1F5F9),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              offset: const Offset(-6, -6),
                                              blurRadius: 12,
                                            ),
                                            BoxShadow(
                                              color: const Color(
                                                0xFF94A3B8,
                                              ).withOpacity(0.35),
                                              offset: const Offset(6, 6),
                                              blurRadius: 14,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 94,
                                            height: 94,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF94A3B8,
                                                  ).withOpacity(0.25),
                                                  offset: const Offset(0, 3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: isBusy
                                                  ? SizedBox(
                                                      width: 26,
                                                      height: 26,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: accent,
                                                            strokeWidth: 2.5,
                                                          ),
                                                    )
                                                  : Icon(
                                                      isPunchedIn
                                                          ? Icons.logout_rounded
                                                          : Icons
                                                                .touch_app_rounded,
                                                      size: 38,
                                                      color: accent,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    isPunchedIn ? 'Check Out' : 'Check In',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPunchedIn
                                            ? Icons.info_outline_rounded
                                            : Icons.touch_app_rounded,
                                        size: 13,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isPunchedIn
                                            ? 'Tap to end your work day'
                                            : 'Tap to start your work day',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.access_time_rounded,
                          iconBgColor: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          title: 'Worked',
                          value: hoursFormatted,
                          subtitle: 'Today',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.login_rounded,
                          iconBgColor: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF2563EB),
                          title: 'Check In',
                          value: checkIn != null
                              ? DateFormat('hh:mm a').format(checkIn)
                              : '--:--',
                          subtitle: 'Today',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.logout_rounded,
                          iconBgColor: const Color(0xFFFEE2E2),
                          iconColor: const Color(0xFFEF4444),
                          title: 'Check Out',
                          value: checkOut != null
                              ? DateFormat('hh:mm a').format(checkOut)
                              : '--:--',
                          subtitle: 'Today',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Today's Work Progress Card
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(16),
                  //     border: Border.all(color: const Color(0xFFF1F5F9)),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           const Text(
                  //             "Today's Work Progress",
                  //             style: TextStyle(
                  //               fontSize: 13,
                  //               fontWeight: FontWeight.bold,
                  //               color: Color(0xFF1E293B),
                  //             ),
                  //           ),
                  //           // Text(
                  //           //   progressDisplay,
                  //           //   style: const TextStyle(
                  //           //     fontSize: 13,
                  //           //     fontWeight: FontWeight.bold,
                  //           //     color: Color(0xFF16A34A),
                  //           //   ),
                  //           // ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 4),
                  //       // Text(
                  //       //   '$hoursFormatted / $shiftDurationStr',
                  //       //   style: const TextStyle(
                  //       //     fontSize: 11,
                  //       //     color: Color(0xFF64748B),
                  //       //   ),
                  //       // ),
                  //       const SizedBox(height: 10),
                  //       // ClipRRect(
                  //       //   borderRadius: BorderRadius.circular(4),
                  //       //   child: LinearProgressIndicator(
                  //       //     value: progressPercentage,
                  //       //     minHeight: 6,
                  //       //     backgroundColor: const Color(0xFFE2E8F0),
                  //       //     valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                  //       //   ),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 14),

                  // Today's Activity Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Activity",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            // GestureDetector(
                            //   onTap: () {},
                            //   child: const Text(
                            //     'View All',
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.w600,
                            //       color: Color(0xFF2563EB),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (checkIn == null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'No activity logged today yet.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Your attendance activity will appear here.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _ActivityRowItem(
                            icon: Icons.login_rounded,
                            title: 'Punch In',
                            time: DateFormat('hh:mm a').format(checkIn),
                            iconColor: const Color(0xFF16A34A),
                          ),
                          if (checkOut != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                            _ActivityRowItem(
                              icon: Icons.logout_rounded,
                              title: 'Punch Out',
                              time: DateFormat('hh:mm a').format(checkOut),
                              iconColor: AppColors.danger,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _ActivityRowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color iconColor;

  const _ActivityRowItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
