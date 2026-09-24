// lib/features/inventory/products/presentation/screens/product_detail_screen.dart

import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
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
    final canManage = ref.watch(authProvider).canAny(
          AppPermissions.productManageAccess,
        );
    final canAdjustStock = ref.watch(authProvider).canAny(
      AppPermissions.productStockManageAccess,
    );
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        centerTitle: true,
        title: const Text(
          'Product Detail',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: canManage
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
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
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: _DetailBody(item: item, canAdjustStock: canAdjustStock),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final InventoryItem item;
  final bool canAdjustStock;

  const _DetailBody({required this.item, required this.canAdjustStock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = resolveImageUrl(item.imageUrl);
    final costHistoryAsync = ref.watch(itemCostHistoryProvider(item.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ---------- Hero header ----------
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 2,
                color: AppColors.accent.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                item.productCode ?? item.sku,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              if (item.status != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor(item.status).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor(item.status).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    item.status!.toUpperCase(),
                    style: TextStyle(
                      color: statusColor(item.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---------- Pricing ----------
        _SectionCard(
          title: 'Pricing',
          icon: Icons.sell_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PriceTile(
                      label: 'Selling Price',
                      value: item.sellingPrice,
                      emphasize: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PriceTile(label: 'MRP', value: item.mrp),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _kvRow('B2B Price', _rupee(item.b2bPrice)),
              _kvRow('Cost Price', _rupee(item.costPrice)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------- Stock ----------
        _SectionCard(
          title: 'Stock',
          icon: Icons.inventory_2_outlined,
          trailing: canAdjustStock
              ? TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Adjust'),
                  onPressed: () => _showAdjustStockSheet(context, ref, item),
                )
              : null,
          child: Column(
            children: [
              _kvRow(
                'Current stock',
                '${item.currentStock} ${item.unit ?? ''}'.trim(),
                highlight: true,
              ),
              _kvRow('Reorder level', '${item.reorderLevel ?? '-'}'),
              _kvRow('Opening stock', '${item.openingStock ?? '-'}'),
              if (item.stocks.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),
                ...item.stocks.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warehouse_outlined,
                                size: 16, color: AppColors.muted),
                            const SizedBox(width: 8),
                            Text(s.warehouseName),
                          ],
                        ),
                        Text(
                          '${s.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------- Details ----------
        _SectionCard(
          title: 'Details',
          icon: Icons.description_outlined,
          child: Column(
            children: [
              _kvRow('SKU', item.sku),
              _kvRow('Category', item.categoryName ?? '-'),
              _kvRow('Brand', item.brandName ?? '-'),
              _kvRow('HSN/SAC', item.hsnSac ?? '-'),
              _kvRow('Product type', item.productType ?? '-'),
              _kvRow('Sourcing', item.sourcing ?? '-'),
              _kvRow('Visibility', item.visibility ?? '-'),
              if (item.vendorName != null) _kvRow('Vendor', item.vendorName!),
            ],
          ),
        ),

        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Description',
            icon: Icons.notes_outlined,
            child: Text(
              item.description!,
              style: TextStyle(color: AppColors.text, height: 1.4),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ---------- Cost history ----------
        Row(
          children: [
            Icon(Icons.history, size: 18, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(
              'Cost history',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        costHistoryAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
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
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(history.length, (i) {
                  final h = history[i];
                  final isLast = i == history.length - 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 10),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.previousCost != null
                                        ? '₹${h.previousCost} → ₹${h.cost}'
                                        : '₹${h.cost}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (h.note != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      h.note!,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (h.date != null)
                              Text(
                                '${h.date!.day}/${h.date!.month}/${h.date!.year}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                        if (!isLast) ...[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: AppColors.border),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surface,
      child: Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 40),
    );
  }

  String _rupee(num? value) => value == null ? '-' : '₹$value';

  Widget _kvRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Adjust stock',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.name,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'New quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hintController,
                decoration: InputDecoration(
                  labelText: 'Warehouse hint (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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

class _PriceTile extends StatelessWidget {
  final String label;
  final num? value;
  final bool emphasize;

  const _PriceTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.accent.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value == null ? '-' : '₹$value',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: emphasize ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: AppColors.accent),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}