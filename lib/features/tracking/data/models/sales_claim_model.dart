// Models for the Expense & Claim (distance claim) module — doc 04.
//
// Base path: `/api/sales/claims`. A salesperson submits one claim per month
// for the previous calendar month; a manager with `sales_distance_claims.review`
// approves or rejects the team's claims.

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

/// One `{ label, amount }` extra expense line on a claim.
class ExtraExpense {
  final String label;
  final double amount;

  const ExtraExpense({required this.label, required this.amount});

  factory ExtraExpense.fromJson(Map<String, dynamic> json) => ExtraExpense(
    label: json['label']?.toString() ?? '',
    amount: _toDouble(json['amount']),
  );

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};
}

/// Company-wide claim settings returned inside the preview.
/// The app shows the values read-only — rates/dates are never edited here.
class ClaimSettings {
  final double twoWheelerRate;
  final double fourWheelerRate;
  final int fromDay;
  final int toDay;
  final int toMonthOffset;
  final List<int> allowedDaysOfMonth;
  final String status;

  const ClaimSettings({
    this.twoWheelerRate = 0,
    this.fourWheelerRate = 0,
    this.fromDay = 1,
    this.toDay = 0,
    this.toMonthOffset = 0,
    this.allowedDaysOfMonth = const [],
    this.status = '',
  });

  factory ClaimSettings.fromJson(Map<String, dynamic> json) {
    final rawDays = json['allowedDaysOfMonth'];
    return ClaimSettings(
      twoWheelerRate: _toDouble(json['twoWheelerRate']),
      fourWheelerRate: _toDouble(json['fourWheelerRate']),
      fromDay: _toInt(json['fromDay'], fallback: 1),
      toDay: _toInt(json['toDay']),
      toMonthOffset: _toInt(json['toMonthOffset']),
      allowedDaysOfMonth: rawDays is List
          ? rawDays.map((e) => _toInt(e)).toList()
          : const [],
      status: json['status']?.toString() ?? '',
    );
  }

  bool get isActive => status.isEmpty || status.toLowerCase() == 'active';

  /// Human window text, e.g. `Every month · day 1 → 10`.
  String get windowLabel {
    if (allowedDaysOfMonth.isNotEmpty) {
      return 'Allowed dates: ${allowedDaysOfMonth.join(', ')}';
    }
    return 'Allowed window: day $fromDay → $toDay';
  }
}

/// A distance claim (`data.claim` on submit, items in the claims list).
class SalesClaim {
  final String id;
  final String userId;
  final String userName;
  final String monthKey;
  final double systemDistanceKm;
  final double? userDistanceKm;
  final String? vehicleType;
  final double ratePerKm;
  final double amount;
  final List<ExtraExpense> extraExpenses;
  final double extraExpenseAmount;
  final double advancePaymentAmount;
  final double netAmount;
  final String status;
  final String remarks;
  final String? reviewedAt;
  final double? approvedDistanceKm;
  final String reviewRemarks;
  final String? createdAt;

  const SalesClaim({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.monthKey = '',
    this.systemDistanceKm = 0,
    this.userDistanceKm,
    this.vehicleType,
    this.ratePerKm = 0,
    this.amount = 0,
    this.extraExpenses = const [],
    this.extraExpenseAmount = 0,
    this.advancePaymentAmount = 0,
    this.netAmount = 0,
    this.status = '',
    this.remarks = '',
    this.reviewedAt,
    this.approvedDistanceKm,
    this.reviewRemarks = '',
    this.createdAt,
  });

  factory SalesClaim.fromJson(Map<String, dynamic> json) {
    final rawExtras = json['extraExpenses'];
    final extras = rawExtras is List
        ? rawExtras
              .whereType<Map>()
              .map((e) => ExtraExpense.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <ExtraExpense>[];

    return SalesClaim(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      monthKey: json['monthKey']?.toString() ?? '',
      systemDistanceKm: _toDouble(json['systemDistanceKm']),
      userDistanceKm: _toDoubleOrNull(json['userDistanceKm']),
      vehicleType: json['vehicleType']?.toString(),
      ratePerKm: _toDouble(json['ratePerKm']),
      amount: _toDouble(json['amount']),
      extraExpenses: extras,
      extraExpenseAmount: _toDouble(json['extraExpenseAmount']),
      advancePaymentAmount: _toDouble(json['advancePaymentAmount']),
      netAmount: _toDouble(json['netAmount']),
      status: json['status']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString(),
      approvedDistanceKm: _toDoubleOrNull(json['approvedDistanceKm']),
      reviewRemarks: json['reviewRemarks']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get statusKey => status.trim().toLowerCase();

  bool get isPending => statusKey == 'pending';
  bool get isDisputed => statusKey == 'disputed';
  bool get isApproved => statusKey == 'approved';
  bool get isRejected => statusKey == 'rejected';
}

/// `GET /api/sales/claims/my/preview` → `data.preview`.
class ClaimPreview {
  final String monthKey;
  final double systemDistanceKm;
  final String? vehicleType;
  final double ratePerKm;
  final double amount;
  final ClaimSettings? settings;

  /// Set when the user already submitted this month (submit is disabled).
  final SalesClaim? existing;

  const ClaimPreview({
    required this.monthKey,
    this.systemDistanceKm = 0,
    this.vehicleType,
    this.ratePerKm = 0,
    this.amount = 0,
    this.settings,
    this.existing,
  });

  factory ClaimPreview.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final rawExisting = json['existing'];
    return ClaimPreview(
      monthKey: json['monthKey']?.toString() ?? '',
      systemDistanceKm: _toDouble(json['systemDistanceKm']),
      vehicleType: json['vehicleType']?.toString(),
      ratePerKm: _toDouble(json['ratePerKm']),
      amount: _toDouble(json['amount']),
      settings: rawSettings is Map
          ? ClaimSettings.fromJson(Map<String, dynamic>.from(rawSettings))
          : null,
      existing: rawExisting is Map
          ? SalesClaim.fromJson(Map<String, dynamic>.from(rawExisting))
          : null,
    );
  }

  bool get alreadySubmitted => existing != null;
}

/// One row of the day-wise KM table (`GET /api/sales/tracking/my-history`).
class ClaimHistoryDay {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final double totalDistanceKm;

  const ClaimHistoryDay({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.totalDistanceKm = 0,
  });

  /// Tolerant parser — the tracking history payload is a list of sessions
  /// whose field names vary (`checkIn` / `check_in`, `totalDistanceKm` / `km`).
  factory ClaimHistoryDay.fromJson(Map<String, dynamic> json) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    return ClaimHistoryDay(
      date:
          pick([
            'date',
            'day',
            'sessionDate',
            'startedAt',
            'checkIn',
            'checkInAt',
          ]) ??
          '',
      checkIn: pick(['checkIn', 'check_in', 'checkin', 'startedAt', 'startTime']),
      checkOut: pick([
        'checkOut',
        'check_out',
        'checkout',
        'endedAt',
        'endTime',
        'closedAt',
      ]),
      totalDistanceKm: _toDouble(
        json['totalDistanceKm'] ??
            json['total_distance_km'] ??
            json['distanceKm'] ??
            json['km'],
      ),
    );
  }
}
