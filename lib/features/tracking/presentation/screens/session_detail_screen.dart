import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../crm/shared/data/models/sales_visit_model.dart';
import '../../data/models/tracking_model.dart';
import '../providers/tracking_providers.dart';

/// Session detail — own polyline of points + visits on that session.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final TrackingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(sessionPointsProvider(session.id));
    final visitsAsync = ref.watch(sessionVisitsProvider(session.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Session Detail',
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
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(sessionPointsProvider(session.id));
          ref.invalidate(sessionVisitsProvider(session.id));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SummaryCard(session: session),
            const SizedBox(height: 16),
            pointsAsync.when(
              loading: () => const _MapPlaceholder(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _MapPlaceholder(
                child: _Message(
                  icon: Icons.cloud_off_rounded,
                  text: e.toString().replaceFirst('Exception: ', ''),
                ),
              ),
              data: (result) => _RouteMap(
                points: result.points,
                visits: visitsAsync.asData?.value ?? const [],
              ),
            ),
            const SizedBox(height: 16),
            _VisitsSection(
              visits: visitsAsync.asData?.value ?? const [],
              loading: visitsAsync.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final TrackingSession session;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final start = session.checkInTime;
    final end = session.checkOutTime;
    final duration = session.duration;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            start != null ? dateFmt.format(start) : 'Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'Check-in',
                value: start != null ? timeFmt.format(start) : '--',
              ),
              _Stat(
                label: 'Check-out',
                value: end != null ? timeFmt.format(end) : 'Ongoing',
              ),
              _Stat(
                label: 'Duration',
                value: _formatDuration(duration),
              ),
              _Stat(
                label: 'Distance',
                value: '${session.totalDistanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d == Duration.zero) return '--';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.points, required this.visits});

  final List<TrackingPoint> points;
  final List<SalesVisit> visits;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _MapPlaceholder(
        child: _Message(
          icon: Icons.location_off_outlined,
          text: 'No points recorded for this session.',
        ),
      );
    }

    final latLngs = points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);
    final visitsWithCoords =
        visits.where((v) => v.hasCoordinates).toList(growable: false);

    final allPoints = <LatLng>[
      ...latLngs,
      ...visitsWithCoords.map((v) => LatLng(v.latitude!, v.longitude!)),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(allPoints),
              padding: const EdgeInsets.all(40),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.immortal.erp_app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: latLngs,
                  strokeWidth: 4,
                  color: AppColors.primary,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLngs.first,
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.trip_origin_rounded,
                    color: AppColors.success,
                    size: 26,
                  ),
                ),
                Marker(
                  point: latLngs.last,
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.flag_rounded,
                    color: AppColors.danger,
                    size: 26,
                  ),
                ),
                ...visitsWithCoords.map(
                  (v) => Marker(
                    point: LatLng(v.latitude!, v.longitude!),
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitsSection extends StatelessWidget {
  const _VisitsSection({required this.visits, required this.loading});

  final List<SalesVisit> visits;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Visits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (visits.isEmpty && !loading)
            Text(
              'No visits on this session.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            )
          else
            for (final visit in visits) ...[
              Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      visit.clientName.isEmpty ? 'Visit' : visit.clientName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (visit.at != null)
                    Text(
                      _shortTime(visit.at!),
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                ],
              ),
              const Divider(height: 20),
            ],
        ],
      ),
    );
  }

  static String _shortTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return DateFormat('hh:mm a').format(dt);
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 34, color: AppColors.muted),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
