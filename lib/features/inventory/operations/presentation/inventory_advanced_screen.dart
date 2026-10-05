import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_accounts_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_approval_inbox_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_hub_list.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_legacy_production_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_legacy_sales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Approvals, legacy sales/production and Accounts inventory.
/// Every section is its own screen.
class InventoryAdvancedScreen extends ConsumerWidget {
  const InventoryAdvancedScreen({super.key});

  static final List<HubSection> _sections = [
    HubSection(
      icon: Icons.fact_check_outlined,
      title: 'Approvals',
      subtitle: 'Team inbox, my pending approvals and my requests',
      requiredPermissions: AppPermissions.inventoryApprovals,
      builder: (_) => const InventoryApprovalInboxScreen(),
    ),
    HubSection(
      icon: Icons.point_of_sale_outlined,
      title: 'Sales & customers',
      subtitle: 'Customers, orders, invoices, credit notes and returns',
      requiredPermissions: AppPermissions.inventorySalesAccess,
      builder: (_) => const InventoryLegacySalesScreen(),
    ),
    HubSection(
      icon: Icons.precision_manufacturing_outlined,
      title: 'Production orders',
      subtitle: 'Create and complete legacy production orders',
      requiredPermissions: AppPermissions.inventoryLegacyProductionAccess,
      builder: (_) => const InventoryLegacyProductionScreen(),
    ),
    HubSection(
      icon: Icons.account_balance_outlined,
      title: 'Accounts',
      subtitle: 'Stock reconciliation, godown valuation and stock journals',
      requiredPermissions: AppPermissions.inventoryAccountsAccess,
      builder: (_) => const InventoryAccountsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final availableSections = _sections
        .where((section) => auth.canAny(section.requiredPermissions))
        .toList(growable: false);

    if (availableSections.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory advanced')),
        body: const Center(
          child: Text('No advanced inventory sections are available to you'),
        ),
      );
    }

    return InventoryHubScaffold(
      title: 'Inventory advanced',
      sections: availableSections,
    );
  }
}
