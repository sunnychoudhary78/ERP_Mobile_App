// lib/features/inventory/products/presentation/screens/product_detail_screen.dart

import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/product/data/provider/product_provider.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'product_form_screen.dart';
import 'products_screen.dart' show resolveImageUrl, statusColor;

class ProductDetailScreen extends ConsumerWidget {
  final InventoryItem item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Product Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(existing: item),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: _DetailBody(item: item),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final InventoryItem item;

  const _DetailBody({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = resolveImageUrl(item.imageUrl);
    final costHistoryAsync = ref.watch(itemCostHistoryProvider(item.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 120,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: Icon(Icons.inventory_2_outlined,
                            color: AppColors.muted, size: 40),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: Icon(Icons.inventory_2_outlined,
                          color: AppColors.muted, size: 40),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (item.status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor(item.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status!.toUpperCase(),
                  style: TextStyle(
                    color: statusColor(item.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        Center(
          child: Text(
            item.productCode ?? item.sku,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 20),

        _SectionCard(
          title: 'Pricing',
          rows: [
            _kv('MRP', item.mrp),
            _kv('B2B Price', item.b2bPrice),
            _kv('Cost Price', item.costPrice),
            _kv('Selling Price', item.sellingPrice),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Stock',
          rows: [
            MapEntry('Current stock', '${item.currentStock} ${item.unit ?? ''}'),
            MapEntry('Reorder level', '${item.reorderLevel ?? '-'}'),
            MapEntry('Opening stock', '${item.openingStock ?? '-'}'),
          ],
          trailing: TextButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('Adjust'),
            onPressed: () => _showAdjustStockSheet(context, ref, item),
          ),
        ),
        if (item.stocks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: item.stocks
                  .map((s) => ListTile(
                        dense: true,
                        title: Text(s.warehouseName),
                        trailing: Text('${s.quantity}'),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Details',
          rows: [
            MapEntry('SKU', item.sku),
            MapEntry('Category', item.categoryName ?? '-'),
            MapEntry('Brand', item.brandName ?? '-'),
            MapEntry('HSN/SAC', item.hsnSac ?? '-'),
            MapEntry('Product type', item.productType ?? '-'),
            MapEntry('Sourcing', item.sourcing ?? '-'),
            MapEntry('Visibility', item.visibility ?? '-'),
            if (item.vendorName != null) MapEntry('Vendor', item.vendorName!),
          ],
        ),
        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(title: 'Description', rows: const [], freeText: item.description),
        ],

        const SizedBox(height: 12),
        Text('Cost history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        costHistoryAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: TextStyle(color: AppColors.muted),
          ),
          data: (history) {
            if (history.isEmpty) {
              return Text('No cost changes recorded',
                  style: TextStyle(color: AppColors.muted));
            }
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: history
                    .map((h) => ListTile(
                          dense: true,
                          title: Text(
                            h.previousCost != null
                                ? '₹${h.previousCost} → ₹${h.cost}'
                                : '₹${h.cost}',
                          ),
                          subtitle: h.note != null ? Text(h.note!) : null,
                          trailing: h.date != null
                              ? Text(
                                  '${h.date!.day}/${h.date!.month}/${h.date!.year}',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ))
                    .toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  MapEntry<String, String> _kv(String label, num? value) {
    return MapEntry(label, value == null ? '-' : '₹$value');
  }

  Future<void> _showAdjustStockSheet(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final qtyController =
        TextEditingController(text: item.currentStock.toString());
    final hintController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Adjust stock — ${item.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Warehouse hint (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final qty = num.tryParse(qtyController.text.trim());
    if (qty == null || qty < 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      }
      return;
    }

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.updateItemStock(
        item.id,
        quantity: qty,
        warehouseHint: hintController.text.trim().isEmpty
            ? null
            : hintController.text.trim(),
      );
      ref.invalidate(itemDetailProvider(item.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Stock updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> rows;
  final Widget? trailing;
  final String? freeText;

  const _SectionCard({
    required this.title,
    required this.rows,
    this.trailing,
    this.freeText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            if (freeText != null) Text(freeText!),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.key, style: TextStyle(color: AppColors.muted)),
                    Text(r.value),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}