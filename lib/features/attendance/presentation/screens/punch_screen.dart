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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
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
    final workedMinutes = (workedDuration.inMinutes % 60).toString().padLeft(2, '0');
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
      backgroundColor: const Color(0xFFF8FAF7),
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
                                  const Text('👋', style: TextStyle(fontSize: 18)),
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
                        Positioned(
                          right: 12,
                          bottom: 0,
                          top: 0,
                          child: avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_pin,
                                  size: 80,
                                  color: Color(0xFF3B82F6),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPunchedIn ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 3,
                                            backgroundColor: isPunchedIn ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPunchedIn ? 'On Shift' : 'Off Shift',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isPunchedIn ? const Color(0xFF16A34A) : const Color(0xFF64748B),
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
                        Container(width: 1, height: 70, color: const Color(0xFFF1F5F9)),
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
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FAF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2F3E8)),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF16A34A).withOpacity(0.06),
                                ),
                              ),
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF16A34A).withOpacity(0.12),
                                ),
                              ),
                              GestureDetector(
                                onTap: (_actionInFlight || state.isSubmitting || state.isLoading)
                                    ? null
                                    : () => _handlePunch(isPunchedIn),
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPunchedIn ? AppColors.danger : const Color(0xFF16A34A),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPunchedIn ? AppColors.danger : const Color(0xFF16A34A)).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: (_actionInFlight || state.isSubmitting)
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isPunchedIn ? Icons.logout_rounded : Icons.login_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPunchedIn ? 'Tap to end your work day' : 'Tap to start your work day',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            // Text(
                            //   state.locationText ?? 'Office location will be recorded',
                            //   style: const TextStyle(
                            //     fontSize: 12,
                            //     color: Color(0xFF64748B),
                            //   ),
                            // ),
                          ],
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
                          value: checkIn != null ? DateFormat('hh:mm a').format(checkIn) : '--:--',
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
                          value: checkOut != null ? DateFormat('hh:mm a').format(checkOut) : '--:--',
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
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
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
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
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
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
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