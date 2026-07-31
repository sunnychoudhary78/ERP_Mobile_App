import 'dart:io';

import 'package:erp_app/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/leave_apply_provider.dart';
import '../providers/leave_balance_provider.dart';


class LeaveApplyScreen extends ConsumerStatefulWidget {
  const LeaveApplyScreen({super.key});

  @override
  ConsumerState<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends ConsumerState<LeaveApplyScreen> {
  dynamic _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  File? _selectedDocument;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Calculate total days
  double get _calculatedDays {
    if (_isHalfDay) return 0.5;
    if (_startDate == null || _endDate == null) return 0;

    final difference = _endDate!.difference(_startDate!).inDays + 1;
    return difference > 0 ? difference.toDouble() : 0;
  }

  // Pick Document / Proof
  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocument = File(result.files.single.path!);
      });
    }
  }

  // Open Date Picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Handle Form Submission
  void _handleSubmit() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Start Date and End Date.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final data = {
      'leaveTypeId': _selectedLeaveType?.id ?? _selectedLeaveType.toString(),
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
      'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
      'isHalfDay': _isHalfDay,
      'reason': _reasonController.text.trim(),
    };

    // Correctly matching submitLeave signature
    ref.read(leaveApplyProvider.notifier).submitLeave(
          data: data,
          document: _selectedDocument,
        );
  }

  @override
  Widget build(BuildContext context) {
    final applyState = ref.watch(leaveApplyProvider);
    final balances = ref.watch(leaveBalanceProvider);

    // Listen to leave apply state changes for alerts/snackbars
    ref.listen<LeaveApplyState>(leaveApplyProvider, (previous, next) {
      if (next.status == LeaveApplyStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Leave applied successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(leaveApplyProvider.notifier).reset();
      } else if (next.status == LeaveApplyStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Failed to apply leave'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final isLoading = applyState.status == LeaveApplyStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Apply for Leave',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEAVE TYPE DROPDOWN
            _buildSectionLabel('LEAVE TYPE'),
            balances.when(
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Loading balances…', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              error: (e, _) => Text('Error loading balances: $e', style: const TextStyle(color: AppColors.danger)),
              data: (list) {
                if (list.isNotEmpty && _selectedLeaveType == null) {
                  _selectedLeaveType = list.first;
                }
                return DropdownButtonFormField<dynamic>(
                  value: _selectedLeaveType,
                  decoration: _inputDecoration(),
                  dropdownColor: AppColors.card,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
                  items: list.map((item) {
                    final name = item.name ?? 'Unknown';
                    final balance = item.available?? 0;
                    return DropdownMenuItem<dynamic>(
                      value: item,
                      child: Text(
                        '$name (Balance: $balance)',
                        style: const TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLeaveType = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // START DATE & END DATE
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('START DATE'),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        borderRadius: BorderRadius.circular(14),
                        child: IgnorePointer(
                          child: TextFormField(
                            decoration: _inputDecoration(
                              hintText: _startDate != null
                                  ? DateFormat('MM/dd/yyyy').format(_startDate!)
                                  : 'mm/dd/yyyy',
                              hintStyle: TextStyle(
                                color: _startDate != null ? AppColors.text : AppColors.muted,
                                fontSize: 14,
                              ),
                              suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.muted, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('END DATE'),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        borderRadius: BorderRadius.circular(14),
                        child: IgnorePointer(
                          child: TextFormField(
                            decoration: _inputDecoration(
                              hintText: _endDate != null
                                  ? DateFormat('MM/dd/yyyy').format(_endDate!)
                                  : 'mm/dd/yyyy',
                              hintStyle: TextStyle(
                                color: _endDate != null ? AppColors.text : AppColors.muted,
                                fontSize: 14,
                              ),
                              suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.muted, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // IS HALF DAY TOGGLE CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: _cardBoxDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'IS HALF DAY?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: _isHalfDay,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() {
                        _isHalfDay = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // REASON FOR LEAVE
            _buildSectionLabel('REASON FOR LEAVE'),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.text),
              decoration: _inputDecoration(
                hintText: 'Enter detailed reason for leave request...',
              ),
            ),
            const SizedBox(height: 20),

            // ATTACH DOCUMENT / PROOF
            _buildSectionLabel('ATTACH DOCUMENT / PROOF'),
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedDocument != null ? Icons.check : Icons.file_upload_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDocument != null
                          ? _selectedDocument!.path.split('/').last
                          : 'Tap to upload',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDocument != null
                          ? 'Tap to change file'
                          : 'PDF, JPG, PNG (Max 5MB)',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ESTIMATED DURATION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATED DURATION',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${_calculatedDays == 0.5 ? "0.5" : _calculatedDays.toInt()} Days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, color: Colors.white70),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _handleSubmit,
                icon: isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_outlined, size: 18),
                label: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Leave Request',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    );
  }

  InputDecoration _inputDecoration({String? hintText, TextStyle? hintStyle, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle ?? const TextStyle(color: AppColors.muted, fontSize: 14),
      filled: true,
      fillColor: AppColors.card,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}