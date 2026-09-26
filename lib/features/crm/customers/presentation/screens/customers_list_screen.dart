import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/shared/widgets/can_widget.dart';
import 'package:erp_app/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/presentation/providers/sales_workspace_provider.dart';
import '../../../shared/presentation/widgets/crm_async_body.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
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

  Color _getAvatarBgColor(int index) {
    const colors = [
      AppColors.primaryDark,
      Color(0xFFE5E8EB),
      Color(0xFF5C1D06),
      Color(0xFF91F086),
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

  void _retry() {
    ref.read(crmCustomersProvider.notifier).refresh();
    ref.read(salesWorkspaceProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(crmAllCustomersProvider);
    final textTheme = Theme.of(context).textTheme;

    return PermissionGate(
      anyOf: AppPermissions.crmCustomers,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 56,
          title: Text(
            'Customers',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButton: Can(
          anyOf: AppPermissions.crmCustomersManage,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/crm/customers/form',
              );
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer created')),
                );
                ref.read(crmCustomersProvider.notifier).refresh();
              }
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
        ),
        body: CrmAsyncBody(
          async: async,
          onRetry: _retry,
          builder: (customers) {
            final filteredCustomers = customers.where((c) {
              return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search customers...',
                            hintStyle: const TextStyle(color: AppColors.muted),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.muted,
                            ),
                            contentPadding: EdgeInsets.zero,
                            fillColor: AppColors.card,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (filteredCustomers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No customers found.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filteredCustomers.length, (index) {
                      final customer = filteredCustomers[index];
                      final isErp = customer.source == 'ERP';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Material(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isErp) {
                                Navigator.pushNamed(
                                  context,
                                  '/crm/customers/detail',
                                  arguments: customer.id,
                                );
                              } else if (customer.leadId != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/crm/leads/detail',
                                  arguments: customer.leadId,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.6),
                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.name,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        if (customer.email != null &&
                                            customer.email!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            customer.email!,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.muted,
                                                ),
                                          ),
                                        ],
                                        if (customer.phone != null &&
                                            customer.phone!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            customer.phone!,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.muted,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isErp
                                          ? AppColors.primary.withOpacity(0.12)
                                          : AppColors.muted.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      customer.source,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: isErp
                                            ? AppColors.primaryDark
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
      ),
    );
  }
}