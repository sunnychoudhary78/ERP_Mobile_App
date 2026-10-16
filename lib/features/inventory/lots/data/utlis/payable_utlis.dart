import 'package:flutter/material.dart';

// ───────── generic parsing helpers ─────────

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

num numOf(dynamic v) {
  if (v is num) return v;
  return num.tryParse('${v ?? ''}'.replaceAll(',', '').trim()) ?? 0;
}

String txt(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  return s == 'null' ? '' : s;
}

/// First non-empty value among [keys]. If a value is a nested object
/// (e.g. `vendor: {id, name}`) its `name` / `title` is used.
String firstText(Map m, List<String> keys, {String fallback = ''}) {
  for (final k in keys) {
    final v = m[k];
    if (v is Map) {
      final s = txt(v['name'] ?? v['title']);
      if (s.isNotEmpty) return s;
      continue;
    }
    final s = txt(v);
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

/// 1234567.5 -> ₹12,34,567.50 (Indian grouping)
String inr(dynamic v, {bool symbol = true}) {
  final n = numOf(v);
  final fixed = n.abs().toStringAsFixed(2).split('.');
  var whole = fixed[0];
  if (whole.length > 3) {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    whole = '${parts.join(',')},$last3';
  }
  return '${n < 0 ? '-' : ''}${symbol ? '₹' : ''}$whole.${fixed[1]}';
}

String qtyText(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String dateText(dynamic v) {
  final d = v is DateTime ? v : DateTime.tryParse(txt(v));
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')} ${_months[l.month - 1]} ${l.year}';
}

String isoDay(DateTime d) => d.toIso8601String().substring(0, 10);

// ───────── bill view-model (works on the raw JSON, no model dependency) ─────────

class BillView {
  BillView(this.raw);
  final Map<String, dynamic> raw;

  int get id => numOf(raw['id']).toInt();
  String get billNo =>
      firstText(raw, ['billNo', 'billNumber'], fallback: 'Bill #$id');

  int? get vendorId {
    final n = numOf(raw['vendorId'] ?? asMap(raw['vendor'])['id']).toInt();
    return n == 0 ? null : n;
  }

  String get vendorName =>
      firstText(raw, ['vendorName', 'vendor'], fallback: 'Unknown vendor');

  int? get purchaseId {
    final n = numOf(raw['purchaseId'] ?? asMap(raw['purchase'])['id']).toInt();
    return n == 0 ? null : n;
  }

  String get poNo {
    final s = firstText(raw, ['poNo', 'poNumber']);
    return s.isNotEmpty ? s : firstText(asMap(raw['purchase']), ['poNumber']);
  }

  String get invoiceNo => firstText(raw, ['vendorInvoiceNo', 'invoiceNo']);
  dynamic get invoiceDate => raw['invoiceDate'] ?? raw['createdAt'];
  dynamic get dueDate => raw['dueDate'];

  num get amount => numOf(raw['amount'] ?? raw['totalAmount'] ?? raw['total']);
  num get paid => numOf(raw['paidAmount']);
  num get credited => numOf(raw['creditedAmount']);
  num get balance {
    final b = raw['balanceAmount'];
    final v = b != null ? numOf(b) : amount - paid - credited;
    return v < 0 ? 0 : v;
  }

  bool get isPaid => amount > 0 && balance <= 0;

  String get status {
    final s = txt(raw['status']).toUpperCase();
    if (s.isNotEmpty) return s;
    return isPaid ? 'PAID' : 'OPEN';
  }

  double get settledFraction =>
      amount <= 0 ? 0 : ((paid + credited) / amount).clamp(0, 1).toDouble();

  bool get isOverdue {
    if (isPaid || balance <= 0) return false;
    final d = DateTime.tryParse(txt(dueDate));
    return d != null && d.isBefore(DateTime.now());
  }

  List<Map<String, dynamic>> get lines {
    final l = raw['lines'] ?? raw['items'];
    if (l is! List) return const [];
    return [for (final e in l) normLine(e)];
  }

  /// GST / tax / subtotal style numeric fields, whatever the backend names them.
  List<MapEntry<String, num>> get taxFields {
    final re = RegExp(r'gst|tax|subtotal|round', caseSensitive: false);
    final out = <MapEntry<String, num>>[];
    raw.forEach((k, v) {
      if (!re.hasMatch(k) || k.toLowerCase().contains('eligib')) return;
      if (v is num || (v is String && num.tryParse(v) != null)) {
        final n = numOf(v);
        if (n != 0) out.add(MapEntry(_prettyKey(k), n));
      }
    });
    return out;
  }
}

String _prettyKey(String k) {
  final spaced = k.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Normalises a bill line / PO item line to one shape.
Map<String, dynamic> normLine(dynamic rawLine, {bool preferReceived = false}) {
  final m = asMap(rawLine);
  final item = asMap(m['item']);
  final desc = firstText(
    m,
    ['description', 'itemName', 'productName', 'name'],
    fallback: firstText(item, ['name'], fallback: 'Item'),
  );
  num qty;
  if (preferReceived && numOf(m['receivedQty']) > 0) {
    qty = numOf(m['receivedQty']);
  } else {
    qty = numOf(m['quantity'] ?? m['qty'] ?? m['orderedQty']);
  }
  final rate = numOf(
    m['rate'] ?? m['price'] ?? m['unitPrice'] ?? m['unitRate'],
  );
  var amount = numOf(m['amount'] ?? m['total'] ?? m['lineTotal']);
  if (amount == 0) amount = qty * rate;
  return {
    'itemId': m['itemId'] ?? item['id'],
    'description': desc,
    'hsnSac': firstText(
      m,
      ['hsnSac', 'hsn', 'hsnCode'],
      fallback: firstText(item, ['hsnSac', 'hsn']),
    ),
    'quantity': qty,
    'rate': rate,
    'unit': firstText(
      m,
      ['measureUnit', 'unit', 'per'],
      fallback: firstText(item, ['unit']),
    ),
    'amount': amount,
  };
}

// ───────── small shared widgets ─────────

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PAID':
      return const Color(0xFF15803D);
    case 'PARTIAL':
    case 'PARTIALLY_PAID':
      return const Color(0xFF1D4ED8);
    case 'OVERDUE':
      return const Color(0xFFB91C1C);
    case 'CANCELLED':
    case 'VOID':
      return Colors.grey;
    default:
      return const Color(0xFFB45309);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: t.bodySmall)),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: t.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LineTile extends StatelessWidget {
  const LineTile(this.line, {super.key, this.onDelete});
  final Map<String, dynamic> line;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final unit = txt(line['unit']);
    final hsn = txt(line['hsnSac']);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        txt(line['description']),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${qtyText(numOf(line['quantity']))}${unit.isEmpty ? '' : ' $unit'}'
        ' × ${inr(line['rate'])}${hsn.isEmpty ? '' : '  •  HSN $hsn'}',
        style: t.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            inr(line['amount']),
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}