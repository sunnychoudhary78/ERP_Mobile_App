import 'package:erp_app/core/network/api_constants.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/data/models/sales_visit_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

/// Visit detail — `GET /api/sales/visits/:id` (visit + remark thread) and
/// `POST /api/sales/visits/:id/remarks` (doc 02 §Visit detail).
class VisitDetailScreen extends ConsumerStatefulWidget {
  const VisitDetailScreen({super.key});

  @override
  ConsumerState<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends ConsumerState<VisitDetailScreen> {
  final _remarkController = TextEditingController();
  bool _sendingRemark = false;
  String? _visitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visitId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _visitId = args;
    } else if (args is Map) {
      _visitId = args['visitId']?.toString();
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _addRemark() async {
    final text = _remarkController.text.trim();
    if (text.isEmpty || _visitId == null) return;

    setState(() => _sendingRemark = true);
    try {
      await ref.read(salesCrmApiProvider).addVisitRemark(_visitId!, text);
      _remarkController.clear();
      ref.invalidate(visitDetailProvider(_visitId!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingRemark = false);
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _visitId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit detail')),
        body: const Center(child: Text('Missing visit id')),
      );
    }

    final async = ref.watch(visitDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Visit detail')),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(visitDetailProvider(id)),
        builder: (detail) => _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(SalesVisitDetail detail) {
    final visit = detail.visit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (visit.photoUrl != null && visit.photoUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              ApiConstants.fileUrl(visit.photoUrl!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 200,
                color: AppColors.card,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                  size: 40,
                ),
              ),
            ),
          )
        else
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.muted,
              size: 40,
            ),
          ),
        const SizedBox(height: 16),

        _sectionCard(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.clientName.isEmpty
                        ? 'Unnamed client'
                        : visit.clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (visit.type != null) _tag(visit.type!),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.schedule, _formatAt(visit.at)),
            if (visit.repName != null && visit.repName!.isNotEmpty)
              _row(Icons.person_outline, visit.repName!),
            if (visit.location.isNotEmpty)
              _row(Icons.location_on_outlined, visit.address ?? visit.location),
            if (visit.purpose != null && visit.purpose!.isNotEmpty)
              _row(Icons.flag_outlined, visit.purpose!),
            if (visit.contact != null && visit.contact!.isNotEmpty)
              _row(Icons.phone_outlined, visit.contact!),
            if (visit.followUpAt != null)
              _row(Icons.event_available, 'Follow-up: ${visit.followUpAt}'),
            if (visit.rating != null)
              _row(Icons.star_outline, 'Rating: ${visit.rating}/5'),
            if (visit.visitDistanceKm != null)
              _row(
                Icons.route_outlined,
                '${visit.visitDistanceKm} km',
              ),
            if (visit.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(visit.notes),
            ],
          ],
        ),

        if (visit.hasCoordinates) ...[
          const SizedBox(height: 16),
          _sectionCard(
            children: [
              Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        visit.latitude!,
                        visit.longitude!,
                      ),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.immortal.erp_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              visit.latitude!,
                              visit.longitude!,
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              color: AppColors.danger,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _openInMaps(visit.latitude!, visit.longitude!),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in Maps'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        _sectionCard(
          children: [
            Row(
              children: [
                Icon(Icons.comment_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  'Remarks (${detail.remarks.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (detail.remarks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No remarks yet.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...detail.remarks.map(_remarkTile),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _remarkController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add a remark...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: _sendingRemark ? null : _addRemark,
                  icon: _sendingRemark
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _remarkTile(SalesVisitRemark remark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface,
            child: Text(
              (remark.userName?.isNotEmpty == true
                  ? remark.userName!.characters.first
                  : '?'),
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        remark.userName?.isNotEmpty == true
                            ? remark.userName!
                            : 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (remark.createdAt != null)
                      Text(
                        _formatAt(remark.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(remark.remark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppColors.text),
      ),
    );
  }

  String _formatAt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return iso;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }
}
