import 'package:erp_app/features/inventory/operations/presentation/inventory_accounts_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_approval_inbox_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_hub_list.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_legacy_production_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_legacy_sales_screen.dart';
import 'package:flutter/material.dart';



/// Approvals, legacy sales/production and Accounts inventory.
/// Every section is its own screen.
class InventoryAdvancedScreen extends StatelessWidget {
  const InventoryAdvancedScreen({super.key});

  static final List<HubSection> _sections = [
    HubSection(
      icon: Icons.fact_check_outlined,
      title: 'Approvals',
      subtitle: 'Team inbox, my pending approvals and my requests',
      builder: (_) => const InventoryApprovalInboxScreen(),
    ),
    HubSection(
      icon: Icons.point_of_sale_outlined,
      title: 'Sales & customers',
      subtitle: 'Customers, orders, invoices, credit notes and returns',
      builder: (_) => const InventoryLegacySalesScreen(),
    ),
    HubSection(
      icon: Icons.precision_manufacturing_outlined,
      title: 'Production orders',
      subtitle: 'Create and complete legacy production orders',
      builder: (_) => const InventoryLegacyProductionScreen(),
    ),
    HubSection(
      icon: Icons.account_balance_outlined,
      title: 'Accounts',
      subtitle: 'Stock reconciliation, godown valuation and stock journals',
      builder: (_) => const InventoryAccountsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) => InventoryHubScaffold(
    title: 'Inventory approvals & accounts',
    sections: _sections,
  );
}