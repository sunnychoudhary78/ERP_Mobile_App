import 'package:erp_app/features/inventory/operations/presentation/inventory_documents_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_hub_list.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_ledger_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_lots_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_payables_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_reports_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_stock_movements_screen.dart';
import 'package:erp_app/features/inventory/operations/presentation/inventory_warehouses_screen.dart';
import 'package:flutter/material.dart';


/// Inventory operations hub. Every section is its own screen.
///
/// [initialTab] is kept so existing callers still compile. When it is given the
/// matching section opens directly (0 Payables, 1 Lots, 2 Stock movements,
/// 3 Warehouses, 4 Ledger, 5 Reports, 6 Documents); when it is null the menu
/// is shown.
class InventoryOperationsScreen extends StatelessWidget {
  final int? initialTab;

  const InventoryOperationsScreen({super.key, this.initialTab});

  static final List<HubSection> _sections = [
    HubSection(
      icon: Icons.receipt_long_outlined,
      title: 'Payables',
      subtitle: 'Purchase bills, vendor payments and credits',
      builder: (_) => const InventoryPayablesScreen(),
    ),
    HubSection(
      icon: Icons.layers_outlined,
      title: 'Inventory lots',
      subtitle: 'Received, processing and sellable lots',
      builder: (_) => const InventoryLotsScreen(),
    ),
    HubSection(
      icon: Icons.swap_horiz,
      title: 'Stock movements',
      subtitle: 'Stock in / out / transfer, stock out bills, payments received',
      builder: (_) => const InventoryStockMovementsScreen(),
    ),
    HubSection(
      icon: Icons.warehouse_outlined,
      title: 'Warehouses',
      subtitle: 'Locations where stock is kept',
      builder: (_) => const InventoryWarehousesScreen(),
    ),
    HubSection(
      icon: Icons.menu_book_outlined,
      title: 'Stock ledger',
      subtitle: 'Every stock movement with filters',
      builder: (_) => const InventoryLedgerScreen(),
    ),
    HubSection(
      icon: Icons.bar_chart_outlined,
      title: 'Reports',
      subtitle: 'Overview, stock by product, low stock, warehouse balances',
      builder: (_) => const InventoryReportsScreen(),
    ),
    HubSection(
      icon: Icons.description_outlined,
      title: 'Documents',
      subtitle: 'Files and links attached to inventory lots',
      builder: (_) => const InventoryDocumentsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = initialTab;
    if (tab != null) {
      return _sections[tab.clamp(0, _sections.length - 1).toInt()].builder(
        context,
      );
    }
    return InventoryHubScaffold(
      title: 'Inventory operations',
      sections: _sections,
    );
  }
}