import 'sales_activity_model.dart';
import 'sales_bill_model.dart';
import 'sales_lead_model.dart';
import 'sales_quote_model.dart';
import 'sales_visit_model.dart';

class SalesWorkspace {
  final Map<String, dynamic>? config;
  final List<SalesLead> leads;
  final List<SalesActivity> activities;
  final List<SalesVisit> visits;
  final List<SalesQuote> quotes;
  final List<SalesBill> bills;

  const SalesWorkspace({
    this.config,
    required this.leads,
    required this.activities,
    required this.visits,
    required this.quotes,
    required this.bills,
  });

  factory SalesWorkspace.empty() => const SalesWorkspace(
        leads: [],
        activities: [],
        visits: [],
        quotes: [],
        bills: [],
      );

  factory SalesWorkspace.fromApiResponse(dynamic response) {
    Map<String, dynamic> root = {};
    if (response is Map<String, dynamic>) {
      root = response;
    } else if (response is Map) {
      root = Map<String, dynamic>.from(response);
    }

    final config = root['config'] is Map
        ? Map<String, dynamic>.from(root['config'] as Map)
        : null;

    Map<String, dynamic> ws = {};
    if (root['workspace'] is Map) {
      ws = Map<String, dynamic>.from(root['workspace'] as Map);
    } else if (root.containsKey('leads')) {
      ws = root;
    }

    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return SalesWorkspace(
      config: config,
      leads: asMaps(ws['leads']).map(SalesLead.fromJson).toList(),
      activities:
          asMaps(ws['activities']).map(SalesActivity.fromJson).toList(),
      visits: asMaps(ws['visits']).map(SalesVisit.fromJson).toList(),
      quotes: asMaps(ws['quotes']).map(SalesQuote.fromJson).toList(),
      bills: asMaps(ws['bills']).map(SalesBill.fromJson).toList(),
    );
  }

  SalesLead? leadById(String id) {
    for (final l in leads) {
      if (l.id == id || l.dbId == id) return l;
    }
    return null;
  }

  SalesQuote? quoteById(String id) {
    for (final q in quotes) {
      if (q.id == id || q.dbId == id) return q;
    }
    return null;
  }
}

/// Pending CRM approval item (won deal or quote).
class CrmApprovalItem {
  final String kind; // 'won' | 'quote'
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final SalesLead? lead;
  final SalesQuote? quote;

  const CrmApprovalItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.lead,
    this.quote,
  });
}
