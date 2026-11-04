import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `2026-09` → `September 2026`.
String claimMonthLabel(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length < 2) return monthKey.isEmpty ? '—' : monthKey;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return monthKey;
  return '${_months[month - 1]} $year';
}

/// `two_wheeler` → `Bike (2W)`.
String claimVehicleLabel(String? raw) {
  switch (raw) {
    case 'two_wheeler':
      return 'Bike (2W)';
    case 'four_wheeler':
      return 'Car (4W)';
    default:
      return (raw == null || raw.isEmpty) ? '—' : raw.replaceAll('_', ' ');
  }
}

String claimStatusLabel(String status) {
  if (status.isEmpty) return 'Unknown';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}

Color claimStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    case 'disputed':
      return const Color(0xFFE67E22);
    case 'pending':
    default:
      return AppColors.primary;
  }
}

/// Formats an ISO timestamp as `05 Oct 2026, 10:00 AM` (local). Falls back
/// to the raw string when it can't be parsed.
String claimDateTimeLabel(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month - 1]} '
      '${dt.year}, $h:$min $ampm';
}

/// Small pill showing a claim status with a matching colour.
class ClaimStatusChip extends StatelessWidget {
  final String status;

  const ClaimStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = claimStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        claimStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Formats a number without trailing `.0` (e.g. `842.35`, `4`, `3369.4`).
String claimNum(double value, {int decimals = 2}) {
  final fixed = value.toStringAsFixed(decimals);
  if (fixed.contains('.')) {
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return fixed;
}

/// `₹3,369.4` style money label.
String claimMoney(double value) {
  final text = claimNum(value);
  final parts = text.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final grouped = parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
  return '₹$grouped';
}
