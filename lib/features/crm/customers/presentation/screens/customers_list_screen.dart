import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Uses theme color tokens for background palettes
  Color _getAvatarBgColor(int index) {
    const colors = [
      AppColors.primaryDark,
      Color(0xFFE5E8EB), // Neutral avatar grey
      Color(0xFF5C1D06), // Accent avatar brown
      Color(0xFF91F086), // Mint green highlight
    ];
    return colors[index % colors.length];
  }

  Color _getAvatarTextColor(int index) {
    const colors = [
      Colors.white,
      AppColors.text,
      Colors.white,
      AppColors.primary,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmCustomersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        title: Text(
          'Customers',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            
          ),
        ),
       
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add customer logic
        },
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Customer',
          style: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      body: CrmAsyncBody(
        async: async,
        onRetry: () => ref.read(crmCustomersProvider.notifier).refresh(),
        builder: (customers) {
          final filteredCustomers = customers.where((c) {
            return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(crmCustomersProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Search & Filter Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          hintStyle: const TextStyle(color: AppColors.muted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                          contentPadding: EdgeInsets.zero,
                          fillColor: AppColors.card,
                        ),
                      ),
                    ),
                   
                   
              
                  ],
                ),
                const SizedBox(height: 16),

                // Customer List
                if (filteredCustomers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No customers found.',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...List.generate(filteredCustomers.length, (index) {
                    final customer = filteredCustomers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Material(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/crm/customers/detail',
                            arguments: customer.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border.withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: _getAvatarBgColor(index),
                                  child: Text(
                                    _getInitials(customer.name),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: _getAvatarTextColor(index),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      if (customer.email != null && customer.email!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.email!,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                      if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.phone!,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.border,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}