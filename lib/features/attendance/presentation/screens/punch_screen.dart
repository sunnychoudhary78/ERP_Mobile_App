import 'package:erp_app/features/attendance/provider/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';


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

    final actionLabel = isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN';
    final buttonBgColor = isPunchedIn ? AppColors.danger : AppColors.primary;

    final now = DateTime.now();
    final currentTime = DateFormat('hh:mm a').format(now);
    final currentDate = DateFormat('EEEE, MMM d').format(now);

    // Dynamic Calculations
    final checkIn = state.todaySession?.checkInTime;
    final checkOut = state.todaySession?.checkOutTime;

    Duration workedDuration = Duration.zero;
    if (checkIn != null) {
      final endTime = checkOut ?? now;
      workedDuration = endTime.difference(checkIn);
    }
    final hoursFormatted =
        '${workedDuration.inHours.toString().padLeft(2, '0')}h ${(workedDuration.inMinutes % 60).toString().padLeft(2, '0')}m';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Punch Attendance',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.text),
            onPressed: () => ref.read(attendanceProvider.notifier).refreshStatus(),
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
                  // Compact Header Clock Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentDate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentTime,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isPunchedIn ? AppColors.success : AppColors.muted).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: isPunchedIn ? AppColors.success : AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPunchedIn ? 'On Shift' : 'Off Shift',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPunchedIn ? AppColors.success : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sleek Punch Action Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: (_actionInFlight || state.isSubmitting || state.isLoading)
                              ? null
                              : () => _handlePunch(isPunchedIn),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: buttonBgColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: buttonBgColor.withOpacity(0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: (_actionInFlight || state.isSubmitting)
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.power_settings_new_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        actionLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPunchedIn ? 'Tap button to clock out' : 'Tap button to clock in',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Compact Stats Summary Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'WORKED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.muted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hoursFormatted,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isPunchedIn ? AppColors.success : AppColors.muted)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPunchedIn ? Icons.login_rounded : Icons.logout_rounded,
                                  color: isPunchedIn ? AppColors.success : AppColors.muted,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PUNCH IN TIME',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.muted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    checkIn != null
                                        ? DateFormat('hh:mm a').format(checkIn)
                                        : '--:--',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Today's Activity Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "TODAY'S LOG",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                checkIn != null
                                    ? (checkOut != null ? '2 entries' : '1 entry')
                                    : '0 entries',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        if (checkIn == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'No activity logged today yet.',
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          )
                        else ...[
                          _ActivityRow(
                            icon: Icons.login_rounded,
                            title: 'Punch In',
                            time: DateFormat('hh:mm a').format(checkIn),
                            iconColor: AppColors.success,
                          ),
                          if (checkOut != null) ...[
                            const Divider(height: 1, indent: 48, color: AppColors.border),
                            _ActivityRow(
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

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color iconColor;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
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
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}