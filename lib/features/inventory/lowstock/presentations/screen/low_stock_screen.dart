import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(lowStockItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Low Stock'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lowStockItemsProvider);
          await ref.read(lowStockItemsProvider.future);
        },
        child: itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('No low-stock items 🎉')),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _LowStockTile(item: items[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            final msg = e.toString().replaceFirst('Exception: ', '');
            final forbidden = msg.contains('403') || msg.toLowerCase().contains('forbidden');
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(forbidden ? 'No inventory access' : 'Error: $msg'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final InventoryItem item;

  const _LowStockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_outlined, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.currentStock}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.danger),
              ),
              Text(
                'reorder @ ${item.reorderLevel ?? '-'}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}