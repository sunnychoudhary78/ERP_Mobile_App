import 'dart:io';

import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/data/models/sales_lead_model.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';

/// Add visit — `POST /api/sales/visits` (JSON, with `photoUrl`).
///
/// Doc 02 flow: capture client + GPS + photo + purpose, upload the photo via
/// `POST /api/upload`, then send the returned `filePath` as `photoUrl`.
class VisitCheckInScreen extends ConsumerStatefulWidget {
  const VisitCheckInScreen({super.key});

  @override
  ConsumerState<VisitCheckInScreen> createState() => _VisitCheckInScreenState();
}

class _VisitCheckInScreenState extends ConsumerState<VisitCheckInScreen> {
  static const _visitTypes = [
    'check-in',
    'follow-up',
    'meeting',
    'delivery',
  ];

  final _clientController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _purposeController = TextEditingController();
  final _contactController = TextEditingController();

  bool _submitting = false;
  bool _fetchingLocation = false;
  String? _message;
  bool _isError = false;

  // GPS data
  double? _latitude;
  double? _longitude;
  double? _accuracy;

  // Photo
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // Visit meta
  String _visitType = 'check-in';
  bool _isNewVisit = true;
  DateTime? _followUpAt;

  // Optional CRM lead link
  String? _leadId;
  String? _leadName;

  bool _prefilledFromLead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilledFromLead) return;
    _prefilledFromLead = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? leadId;
    String? clientName;
    if (args is String && args.isNotEmpty) {
      leadId = args;
    } else if (args is Map) {
      leadId = args['leadId']?.toString();
      clientName = args['clientName']?.toString();
    }

    if (leadId != null && leadId.isNotEmpty) _leadId = leadId;
    if (clientName != null && clientName.isNotEmpty) {
      _clientController.text = clientName;
      _leadName = clientName;
    }
    // Best-effort GPS prefill on open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
  }

  @override
  void dispose() {
    _clientController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _purposeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _accuracy = position.accuracy;

      if (_accuracy != null && _accuracy! > 80) {
        _snack('GPS accuracy is low (~${_accuracy!.round()} m)', error: true);
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _locationController.text = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      } else {
        _locationController.text =
            '${position.latitude}, ${position.longitude}';
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (e) {
      _snack('Failed to capture photo: $e', error: true);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _followUpAt = picked);
  }

  Future<void> _pickLead() async {
    final leads = ref.read(crmLeadsProvider).value ?? const <SalesLead>[];
    if (leads.isEmpty) {
      _snack('No leads available', error: true);
      return;
    }

    final selected = await showModalBottomSheet<SalesLead>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Link to a lead',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...leads.map(
              (l) => ListTile(
                leading: Icon(Icons.business_outlined, color: AppColors.primary),
                title: Text(
                  l.companyName.isNotEmpty ? l.companyName : l.contactName,
                ),
                subtitle: l.contactName.isNotEmpty
                    ? Text(l.contactName)
                    : null,
                onTap: () => Navigator.pop(ctx, l),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _leadId = selected.dbId ?? selected.id;
        _leadName =
            selected.companyName.isNotEmpty ? selected.companyName : selected.contactName;
        if (_clientController.text.trim().isEmpty) {
          _clientController.text = _leadName!;
        }
      });
    }
  }

  Future<void> _submit() async {
    final clientName = _clientController.text.trim();
    if (clientName.isEmpty) {
      _snack('Please enter a client or site name', error: true);
      return;
    }
    // Doc: the UI must require a photo; ERP accepts a URL.
    if (_selectedPhoto == null) {
      _snack('Please attach a photo of the visit', error: true);
      return;
    }
    if (_latitude == null || _longitude == null) {
      _snack('Capturing GPS…', error: true);
      await _getCurrentLocation();
      if (_latitude == null || _longitude == null) {
        _snack('Unable to capture GPS location', error: true);
        return;
      }
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      // 1. Upload the photo, then send the returned path as photoUrl.
      final photoUrl = await ref
          .read(salesCrmApiProvider)
          .uploadVisitPhoto(_selectedPhoto!);

      final location = _locationController.text.trim();
      final payload = <String, dynamic>{
        'clientName': clientName,
        'type': _visitType,
        'location': location,
        'address': location,
        'visitedAt': DateTime.now().toUtc().toIso8601String(),
        'notes': _notesController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        if (_contactController.text.trim().isNotEmpty)
          'contact': _contactController.text.trim(),
        if (_purposeController.text.trim().isNotEmpty)
          'purpose': _purposeController.text.trim(),
        'photoUrl': photoUrl,
        if (_followUpAt != null)
          'followUpAt': DateFormat('yyyy-MM-dd').format(_followUpAt!),
        'isNewVisit': _isNewVisit,
        if (_leadId != null && _leadId!.isNotEmpty) 'leadId': _leadId,
      };

      // 2. Create the visit.
      await ref.read(salesWorkspaceProvider.notifier).checkInVisit(payload);

      if (!mounted) return;
      _snack('Visit logged successfully');
      Navigator.of(context).maybePop(true);
    } catch (e) {
      setState(() {
        _isError = true;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
      _snack(_message!, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Log visit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Card(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Captures GPS',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_accuracy != null)
                      Text(
                        '±${_accuracy!.round()} m',
                        style: TextStyle(
                          color: _accuracy! > 80
                              ? AppColors.danger
                              : AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                Divider(height: 24, color: AppColors.border),

                if (_leadId != null) ...[
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Linked to lead ${_leadName ?? _leadId}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _leadId = null;
                          _leadName = null;
                        }),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                _label('Client / site', required: true),
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(
                    hintText: 'Enter client or site name...',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickLead,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Link a lead (optional)'),
                  ),
                ),
                const SizedBox(height: 8),

                _label('Visit type'),
                DropdownButtonFormField<String>(
                  initialValue: _visitType,
                  items: _visitTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _visitType = v ?? 'check-in'),
                ),
                const SizedBox(height: 16),

                _label('Location'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.muted,
                          ),
                          hintText: 'City or address',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _fetchingLocation ? null : _getCurrentLocation,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _fetchingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.my_location,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Purpose'),
                TextField(
                  controller: _purposeController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Order follow-up',
                  ),
                ),
                const SizedBox(height: 16),

                _label('Contact'),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Name / phone',
                  ),
                ),
                const SizedBox(height: 16),

                _label('Notes'),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter visit details...',
                  ),
                ),
                const SizedBox(height: 16),

                // New vs follow-up + follow-up date
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isNewVisit,
                  onChanged: (v) => setState(() => _isNewVisit = v),
                  title: Text(
                    _isNewVisit ? 'New visit' : 'Follow-up visit',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _pickFollowUpDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _followUpAt == null
                                ? 'Set follow-up date (optional)'
                                : 'Follow-up: ${DateFormat('dd MMM yyyy').format(_followUpAt!)}',
                            style: TextStyle(color: AppColors.text, fontSize: 14),
                          ),
                        ),
                        if (_followUpAt != null)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            onPressed: () =>
                                setState(() => _followUpAt = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Photo (required)
                _label('Photo of visit', required: true),
                InkWell(
                  onTap: _showPhotoOptions,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedPhoto != null
                                ? 'Photo attached: ${_selectedPhoto!.path.split(Platform.pathSeparator).last}'
                                : 'Attach photo / proof of visit',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedPhoto != null)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            onPressed: () =>
                                setState(() => _selectedPhoto = null),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log visit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (_message != null && _isError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}
