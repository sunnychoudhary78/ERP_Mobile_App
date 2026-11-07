import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/tracking_providers.dart';

/// Tracking home — big Start / Stop, live status, today's KM and visit count.
class TrackingHomeScreen extends ConsumerStatefulWidget {
  const TrackingHomeScreen({super.key});

  @override
  ConsumerState<TrackingHomeScreen> createState() => _TrackingHomeScreenState();
}

class _TrackingHomeScreenState extends ConsumerState<TrackingHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingControllerProvider.notifier).syncWithServer();
    });
  }

  Future<void> _onStart() async {
    final ok = await ref.read(trackingControllerProvider.notifier).start();
    if (!ok && mounted) {
      final msg = ref.read(trackingControllerProvider).banner ??
          ref.read(trackingControllerProvider).error;
      _snack(msg ?? 'Could not start tracking.');
    }
  }

  Future<void> _onStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop tracking?'),
        content: const Text(
          'Your location will stop being recorded and today\'s distance will '
          'be finalised.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(trackingControllerProvider.notifier).stop();
    if (mounted) {
      _snack(ok ? 'Tracking stopped.' : 'Could not stop tracking.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Field Tracking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () =>
                ref.read(trackingControllerProvider.notifier).syncWithServer(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(trackingControllerProvider.notifier).refreshToday(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _StatusCard(
              state: state,
              onStart: _onStart,
              onStop: _onStop,
            ),
            if (state.banner != null) ...[
              const SizedBox(height: 14),
              _Banner(
                message: state.banner!,
                onDismiss: () =>
                    ref.read(trackingControllerProvider.notifier).clearMessages(),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 14),
              _Banner(
                message: state.error!,
                isError: true,
                onDismiss: () =>
                    ref.read(trackingControllerProvider.notifier).clearMessages(),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    icon: Icons.route_rounded,
                    label: "Today's KM",
                    value: state.todayKm.toStringAsFixed(1),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KpiTile(
                    icon: Icons.location_on_rounded,
                    label: "Today's Visits",
                    value: '${state.todayVisits}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (state.queuedPoints > 0) ...[
              const SizedBox(height: 14),
              _QueueInfo(count: state.queuedPoints),
            ],
            const SizedBox(height: 18),
            _ActionTile(
              icon: Icons.history_rounded,
              title: 'My sessions',
              subtitle: 'Day-wise history and route replay',
              onTap: () => Navigator.pushNamed(
                context,
                '/sales/tracking/sessions',
              ),
            ),
            if (state.openSession != null) ...[
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.map_outlined,
                title: "Today's route",
                subtitle: 'See the points captured so far',
                onTap: () => Navigator.pushNamed(
                  context,
                  '/sales/tracking/session',
                  arguments: state.openSession,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final TrackingState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final live = state.isTracking;
    final session = state.openSession;
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: live
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.78)]
              : [AppColors.primaryDark, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: live
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      live ? 'LIVE' : 'NOT TRACKING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                live ? Icons.wifi_tethering_rounded : Icons.location_off_rounded,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            live ? 'Tracking is on' : 'Start your day',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            live && session?.checkInTime != null
                ? 'Checked in at ${timeFmt.format(session!.checkInTime!)}'
                : 'Your location will be recorded while tracking is on.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isStarting || state.isStopping
                  ? null
                  : (live ? onStop : onStart),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: live ? AppColors.danger : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: state.isStarting || state.isStopping
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      live
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_fill_rounded,
                    ),
              label: Text(
                state.isStarting
                    ? 'Starting…'
                    : state.isStopping
                    ? 'Stopping…'
                    : live
                    ? 'Stop Tracking'
                    : 'Start Tracking',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _QueueInfo extends StatelessWidget {
  const _QueueInfo({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count point${count == 1 ? '' : 's'} queued — will upload '
              'when the network is back.',
              style: TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
