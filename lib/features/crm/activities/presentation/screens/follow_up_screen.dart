// follow_up_screen.dart
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';

class FollowUpScreen extends ConsumerStatefulWidget {
  final String leadId;
  final String leadName;

  const FollowUpScreen({
    super.key,
    required this.leadId,
    required this.leadName,
  });

  @override
  ConsumerState<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends ConsumerState<FollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'Phone';
  String _selectedPriority = 'Medium';
  String _selectedStatus = 'Pending';

  final List<String> _typeOptions = ['Phone', 'Email', 'Meeting', 'Task'];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
  final List<String> _statusOptions = ['Pending', 'Upcoming', 'Done'];

  bool _isSubmitting = false;
  String? _followUpId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitFollowUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final payload = {
        'type': _selectedType,
        'notes': _notesController.text.trim(),
        'dueAt': dateTime.toIso8601String(),
        'priority': _selectedPriority,
        'status': _selectedStatus.toLowerCase(),
        'subject': '${_selectedType} Follow-up - ${widget.leadName}',
        'related': widget.leadName,
      };

      await ref.read(salesWorkspaceProvider.notifier).logFollowUp(
            widget.leadId,
            payload,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up logged successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Log Follow-up'),
        actions: [
          // Match web UI with a "Log another follow-up" style button
          TextButton(
            onPressed: _isSubmitting ? null : _submitFollowUp,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Log Follow-up'),
          ),
          const SizedBox(width: 16),
        ],
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lead info header - matches web "Details" section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lead: ${widget.leadName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                'ID: ${widget.leadId}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Follow-up Details - matches web "Timeline" section
                  const Text(
                    'Follow-up Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type dropdown
                  _buildDropdownField(
                    label: 'Type',
                    value: _selectedType,
                    items: _typeOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                          onTap: () => _selectDate(context),
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Time',
                          value: _selectedTime.format(context),
                          onTap: () => _selectTime(context),
                          icon: Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Priority dropdown
                  _buildDropdownField(
                    label: 'Priority',
                    value: _selectedPriority,
                    items: _priorityOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedPriority = value);
                    },
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Status dropdown
                  _buildDropdownField(
                    label: 'Status',
                    value: _selectedStatus,
                    items: _statusOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedStatus = value);
                    },
                    icon: Icons.circle_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Notes field - matches web "Timeline" requirement area
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Enter follow-up notes...',
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter notes';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action buttons - matches web "Next Steps" section
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFollowUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Log Follow-up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: Icon(icon, color: AppColors.muted, size: 20),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.muted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}