import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/sales_entitlement.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../main.dart' show navigatorKey;
import '../providers/tracking_providers.dart';

/// Wraps the whole app so an active tracking session shows a small bar at the
/// bottom of every screen (doc 01 — "always visible while session is open").
///
/// Also the single place that restores a session on app start: if the server
/// still has an open session for today, tracking resumes without a second
/// check-in.
class ActiveTrackingOverlay extends ConsumerStatefulWidget {
  const ActiveTrackingOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ActiveTrackingOverlay> createState() =>
      _ActiveTrackingOverlayState();
}

class _ActiveTrackingOverlayState extends ConsumerState<ActiveTrackingOverlay> {
  bool _synced = false;

  void _syncIfNeeded() {
    if (_synced) return;
    final auth = ref.read(authProvider);
    if (auth.profile == null || !auth.canTrack) return;
    _synced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingControllerProvider.notifier).syncWithServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.profile == null || !auth.canTrack) {
      return widget.child;
    }

    _syncIfNeeded();
    final state = ref.watch(trackingControllerProvider);

    if (!state.isTracking || state.openSession == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          right: 12,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: _ActiveBar(
              km: state.todayKm,
              queued: state.queuedPoints,
              onOpen: () =>
                  navigatorKey.currentState?.pushNamed('/sales/tracking'),
              onStop: () =>
                  ref.read(trackingControllerProvider.notifier).stop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveBar extends StatelessWidget {
  const _ActiveBar({
    required this.km,
    required this.queued,
    required this.onOpen,
    required this.onStop,
  });

  final double km;
  final int queued;
  final VoidCallback onOpen;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tracking live',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                queued > 0 ? '${km.toStringAsFixed(1)} km · $queued' : '${km.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
