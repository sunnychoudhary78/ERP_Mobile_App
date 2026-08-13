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

                  // Punch Action Card — explicit Punch In / Punch Out buttons.
                  // Both stay tappable regardless of the locally-known state:
                  // if the backend and the app ever disagree (e.g. an open
                  // session already exists), the user can still tap Punch
                  // Out directly instead of being stuck behind a single
                  // toggle button that only shows "Punch In".
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PunchButton(
                                label: 'PUNCH IN',
                                icon: Icons.login_rounded,
                                color: AppColors.primary,
                                emphasized: !isPunchedIn,
                                loading: (_actionInFlight || state.isSubmitting) && !isPunchedIn,
                                onTap: (_actionInFlight || state.isSubmitting || state.isLoading)
                                    ? null
                                    : () => _handlePunch(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PunchButton(
                                label: 'PUNCH OUT',
                                icon: Icons.logout_rounded,
                                color: AppColors.danger,
                                emphasized: isPunchedIn,
                                loading: (_actionInFlight || state.isSubmitting) && isPunchedIn,
                                onTap: (_actionInFlight || state.isSubmitting || state.isLoading)
                                    ? null
                                    : () => _handlePunch(true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPunchedIn ? 'You are on shift — tap Punch Out to clock out' : 'Tap Punch In to clock in',
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

/// A single Punch In / Punch Out action button.
/// [emphasized] renders it as a solid filled button (the action that
/// matches current state); otherwise it's an outlined secondary button.
/// It stays tappable either way — see the note above where it's used.
class _PunchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool emphasized;
  final bool loading;
  final VoidCallback? onTap;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.emphasized,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: emphasized ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: emphasized ? color : color.withOpacity(disabled ? 0.3 : 0.6),
            width: 1.4,
          ),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: emphasized ? Colors.white : color,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Opacity(
                opacity: disabled && !emphasized ? 0.5 : 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: emphasized ? Colors.white : color,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: emphasized ? Colors.white : color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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