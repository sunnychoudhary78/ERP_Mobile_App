import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';


class ContactsListScreen extends ConsumerStatefulWidget {
  const ContactsListScreen({super.key});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAlphabeticalSort = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // // Phone Call trigger helper
  // Future<void> _makeCall(String phoneNumber) async {
  //   if (phoneNumber.isEmpty) return;
  //   final Uri url = Uri(scheme: 'tel', path: phoneNumber);
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url);
  //   }
  // }

  // // Email trigger helper
  // Future<void> _sendEmail(String email) async {
  //   if (email.isEmpty) return;
  //   final Uri url = Uri(scheme: 'mailto', path: email);
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url);
  //   }
  // }

  // Dynamic Avatar background color based on name
  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF5B2C6F),
      const Color(0xFF117A65),
      const Color(0xFFB9770E),
      const Color(0xFF283747),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  // Badge Style Helper
  Map<String, Color> _getBadgeStyle(String tag) {
    final cleanTag = tag.toUpperCase();
    if (cleanTag.contains('ENTERPRISE')) {
      return {'bg': const Color(0xFFD4EFDF), 'text': const Color(0xFF1E8449)};
    } else if (cleanTag.contains('NEW') || cleanTag.contains('URGENT')) {
      return {'bg': const Color(0xFFFADBD8), 'text': AppColors.danger};
    } else if (cleanTag.contains('VIP')) {
      return {'bg': const Color(0xFFD5F5E3), 'text': const Color(0xFF27AE60)};
    } else if (cleanTag.contains('CONTRACTING')) {
      return {'bg': const Color(0xFFE8DAEF), 'text': const Color(0xFF884EA0)};
    }
    return {'bg': const Color(0xFFE5E7E9), 'text': AppColors.muted};
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.pushNamed(context, '/crm/leads/form');
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
        builder: (contacts) {
          // Filter contacts
          var filteredContacts = contacts.where((c) {
            final query = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                c.account.toLowerCase().contains(query) ||
                c.phone.toLowerCase().contains(query) ||
                c.email.toLowerCase().contains(query);
          }).toList();

          // Sort contacts
          if (_isAlphabeticalSort) {
            filteredContacts.sort((a, b) => a.name.compareTo(b.name));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(salesWorkspaceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Find by name, company, phone or email...',
                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 12),

                // Title & Count
               
                // 

                // Empty State or List of Cards
                if (filteredContacts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No contacts found.',
                            style: TextStyle(color: AppColors.muted, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredContacts.map((c) => _buildContactCard(context, c)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Contact Card Widget with explicit Phone & Email display
  Widget _buildContactCard(BuildContext context, dynamic contact) {
    // Generate Initials
    final nameParts = contact.name.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : (contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C');

    final String tagText = contact.status ?? 'ENTERPRISE';
    final badgeStyle = _getBadgeStyle(tagText);

    final String phoneText = contact.phone.toString().trim();
    final String emailText = contact.email.toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/crm/contacts/detail',
          arguments: contact.leadId, // Retains leadId detail routing logic
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Avatar, Info & Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Initial Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(contact.name),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Account
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.account.isNotEmpty ? contact.account : 'N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeStyle['bg'],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tagText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeStyle['text'],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F4)),
              const SizedBox(height: 12),

              // Detailed Phone Number and Email Rows
              if (phoneText.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 15, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phoneText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              if (emailText.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 15, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        emailText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              const SizedBox(height: 8),

              // Action Buttons: Call & Email
              // Row(
              //   children: [
              //     Expanded(
              //       child: OutlinedButton.icon(
              //         onPressed: () => _makeCall(contact.phone),
              //         icon: const Icon(Icons.phone, size: 15),
              //         label: const Text('Call'),
              //         style: OutlinedButton.styleFrom(
              //           foregroundColor: AppColors.text,
              //           side: const BorderSide(color: AppColors.border),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(12),
              //           ),
              //           padding: const EdgeInsets.symmetric(vertical: 10),
              //         ),
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: OutlinedButton.icon(
              //         onPressed: () => _sendEmail(contact.email),
              //         icon: const Icon(Icons.email, size: 15),
              //         label: const Text('Email'),
              //         style: OutlinedButton.styleFrom(
              //           foregroundColor: AppColors.text,
              //           side: const BorderSide(color: AppColors.border),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(12),
              //           ),
              //           padding: const EdgeInsets.symmetric(vertical: 10),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}