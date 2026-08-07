import 'dart:io';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class VisitCheckInScreen extends ConsumerStatefulWidget {
  const VisitCheckInScreen({super.key});

  @override
  ConsumerState<VisitCheckInScreen> createState() => _VisitCheckInScreenState();
}

class _VisitCheckInScreenState extends ConsumerState<VisitCheckInScreen> {
  final _clientController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _submitting = false;
  bool _fetchingLocation = false;
  String? _message;

  // GPS Data
  double? _latitude;
  double? _longitude;

  // Photo Attachment
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _clientController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Pull-to-Refresh Handler using Riverpod
  Future<void> _handleRefresh() async {
    // Refresh Riverpod provider data
    ref.read(salesWorkspaceProvider.notifier).refresh();
    // Refresh the CRM visits provider
    ref.refresh(crmVisitsProvider);
  }

  /// Fetch GPS Location (Latitude, Longitude) & Reverse Geocode
  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formattedAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        _locationController.text = formattedAddress;
      } else {
        _locationController.text =
            '${position.latitude}, ${position.longitude}';
      }
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
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  /// Image Selection
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
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

  /// Form Submission
  Future<void> _checkIn() async {
    final clientName = _clientController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a client or site name'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      final payload = {
        'clientName': clientName,
        'location': _locationController.text.trim(),
        'notes': _notesController.text.trim(),
        'visitType': 'Field',
        'lat': _latitude,
        'lng': _longitude,
        'photoPath': _selectedPhoto?.path,
      };

      await ref.read(salesWorkspaceProvider.notifier).checkInVisit(payload);
      setState(() => _message = 'Visit checked in successfully');

      _clientController.clear();
      _locationController.clear();
      _notesController.clear();
      setState(() {
        _selectedPhoto = null;
        _latitude = null;
        _longitude = null;
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmVisitsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Visit Check-in'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Dynamic Stat Cards bound directly to provider state
              async.when(
                data: (visits) {
                  final now = DateTime.now();

                  // Count visits that occurred today
                  final todayVisitsCount = visits.where((v) {
                    if (v.at == null) return false;
                    final parsedDate = DateTime.tryParse(v.at!);
                    if (parsedDate == null) return false;
                    return parsedDate.year == now.year &&
                        parsedDate.month == now.month &&
                        parsedDate.day == now.day;
                  }).length;

                  // Unique sales reps active in current visits list
                  final activeRepsCount = visits
                      .map((v) => v.repName)
                      .where((rep) => rep != null && rep.isNotEmpty)
                      .toSet()
                      .length;

                  // List built dynamically based on your CRM data
                  final dynamicStats = [
                    {
                      'title': 'TODAY',
                      'value': todayVisitsCount.toString(),
                      'color': Colors.orange,
                    },
                    {
                      'title': 'TOTAL VISITS',
                      'value': visits.length.toString(),
                      'color': Colors.indigo,
                    },
                    {
                      'title': 'ACTIVE REPS',
                      'value': activeRepsCount.toString(),
                      'color': Colors.teal,
                    },
                  ];

                  return _buildDynamicStatCards(dynamicStats);
                },
                loading: () => _buildDynamicStatCards([
                  {'title': 'TODAY', 'value': '...', 'color': Colors.orange},
                  {
                    'title': 'TOTAL VISITS',
                    'value': '...',
                    'color': Colors.indigo,
                  },
                  {'title': 'ACTIVE REPS', 'value': '...', 'color': Colors.teal},
                ]),
                error: (_, __) => _buildDynamicStatCards([
                  {'title': 'TODAY', 'value': '0', 'color': Colors.orange},
                  {'title': 'TOTAL VISITS', 'value': '0', 'color': Colors.indigo},
                  {'title': 'ACTIVE REPS', 'value': '0', 'color': Colors.teal},
                ]),
              ),

              const SizedBox(height: 16),

              // Record Check-in Form Card
              Card(
                elevation: 0,
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-in at client',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Captures GPS',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),

                      // Manual Client Input (Text Field)
                      RichText(
                        text: const TextSpan(
                          text: 'Client / site ',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientController,
                        decoration: const InputDecoration(
                          hintText: 'Enter client or site name...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Input
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              decoration: const InputDecoration(
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
                                  : const Icon(
                                      Icons.my_location,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes Input
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter visit details...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo Attachment Field
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
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedPhoto != null
                                      ? 'Photo Attached: ${_selectedPhoto!.path.split('/').last}'
                                      : 'Attach Photo / Proof of Visit',
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedPhoto != null)
                                IconButton(
                                  icon: const Icon(
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

                      // Submit Button
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
                          onPressed: _submitting ? null : _checkIn,
                          child: _submitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Record check-in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // History Section
              Card(
                elevation: 0,
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Visits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CrmAsyncBody(
                        async: async,
                        onRetry: () =>
                            ref.read(salesWorkspaceProvider.notifier).refresh(),
                        builder: (visits) => Column(
                          children: [
                            ...visits.map(
                              (v) => Column(
                                children: [
                                  const Divider(color: AppColors.border),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      v.clientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${v.at ?? '—'} · ${v.location}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontally scrollable row that renders dynamic stats lists
  Widget _buildDynamicStatCards(List<Map<String, dynamic>> statsList) {
    if (statsList.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statsList.map((stat) {
          final topColor = (stat['color'] as Color?) ?? AppColors.primary;

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: topColor.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 4, color: topColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat['title'].toString().toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: topColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stat['value'].toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}