import 'sales_lead_model.dart';

/// Contact derived from a lead (mirrors web deriveContactsFromLeads).
class SalesContact {
  final String id;
  final String leadId;
  final String name;
  final String role;
  final String account;
  final String email;
  final String phone;
  final String owner;
  final String lastTouch;
  final String status;
  final String? lifecycleStage;
  final String? customerId;

  const SalesContact({
    required this.id,
    required this.leadId,
    required this.name,
    required this.role,
    required this.account,
    required this.email,
    required this.phone,
    required this.owner,
    required this.lastTouch,
    required this.status,
    this.lifecycleStage,
    this.customerId,
  });

  factory SalesContact.fromLead(SalesLead lead) {
    return SalesContact(
      id: 'C-${lead.id}',
      leadId: lead.id,
      name: lead.contactName.isNotEmpty ? lead.contactName : lead.companyName,
      role: lead.clientType == 'Returning' ? 'Returning client' : 'Prospect',
      account: lead.companyName,
      email: lead.email,
      phone: lead.phone,
      owner: lead.ownerName.isEmpty ? '—' : lead.ownerName,
      lastTouch: lead.updatedAt ?? lead.createdAt ?? '—',
      status: lead.status,
      lifecycleStage: lead.lifecycleStage,
      customerId: lead.customerId,
    );
  }
}
