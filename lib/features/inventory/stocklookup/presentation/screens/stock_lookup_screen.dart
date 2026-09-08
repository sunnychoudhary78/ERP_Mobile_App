import 'dart:async';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/item_lookup_model.dart';
import 'package:erp_app/features/inventory/shared/data/models/warehouse_stock_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';

class StockLookupScreen extends ConsumerStatefulWidget {
  const StockLookupScreen({super.key});

  @override
  ConsumerState<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends ConsumerState<StockLookupScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(stockLookupProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _showSuggestions = value.trim().isNotEmpty);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(stockLookupProvider.notifier).search(value);
      ref.read(itemLookupProvider.notifier).lookup(value);
    });
  }

  void _onSuggestionTap(ItemLookupResult suggestion) {
    _searchDebounce?.cancel();
    _controller.value = TextEditingValue(
      text: suggestion.name,
      selection: TextSelection.collapsed(offset: suggestion.name.length),
    );
    setState(() => _showSuggestions = false);
    _searchFocusNode.unfocus();
    ref.read(stockLookupProvider.notifier).search(suggestion.name);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockLookupProvider);
    final lookupState = ref.watch(itemLookupProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Stock Lookup'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(fontSize: 15, color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'Search by name / SKU / product code...',
                      hintStyle: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.muted,
                      ),
                      suffixIcon: state.query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.muted,
                              ),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _showSuggestions = false);
                                ref.read(stockLookupProvider.notifier).clear();
                                ref.read(itemLookupProvider.notifier).clear();
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _searchDebounce?.cancel();
                      setState(() => _showSuggestions = false);
                      ref.read(stockLookupProvider.notifier).search(value);
                    },
                  ),
                  if (_showSuggestions && lookupState.results.isNotEmpty)
                    _SuggestionsDropdown(
                      results: lookupState.results,
                      onTap: _onSuggestionTap,
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(StockLookupState state) {
    if (state.query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Type to search items',
        subtitle: 'Enter a product name, SKU, or code above.',
      );
    }

    if (state.isForbidden) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'Access Restricted',
        subtitle: 'You do not have permission to access inventory records.',
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: state.errorMessage!,
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_outlined,
        title: 'No items found',
        subtitle: 'Try adjusting your search terms.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.items.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final item = state.items[index];
        return _ItemTile(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ItemDetailScreen(item: item)),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEAECEE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${item.sku}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    if (item.brandName != null)
                      Text(
                        'Brand: ${item.brandName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.currentStock} ${item.unit ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.isLowStock
                          ? AppColors.danger
                          : AppColors.text,
                    ),
                  ),
                  if (item.isLowStock) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LOW STOCK',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDetailScreen extends ConsumerWidget {
  final InventoryItem item;

  const _ItemDetailScreen({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(warehouseStockForItemProvider(item.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text("Item Detials"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(warehouseStockForItemProvider(item.id));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'SKU: ${item.sku}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Low Stock Banner (Dynamic Condition)
                if (item.isLowStock) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFADBD8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LOW STOCK ALERT',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Current stock is below reorder level '
                                '(${item.reorderLevel ?? '-'} units).',
                                style: TextStyle(
                                  color: AppColors.danger.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Item Details Box
                _ItemInfoCard(item: item),
                const SizedBox(height: 16),

                // Warehouse Stock Box
                _WarehouseStockCard(stockAsync: stockAsync),
                const SizedBox(height: 24),

                // Bottom Dynamic Action Buttons
                // SizedBox(
                //   width: double.infinity,
                //   height: 48,
                //   child: ElevatedButton.icon(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primary,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //     onPressed: () {
                //       // Action logic for request restock
                //     },
                //     icon: const Icon(Icons.add_shopping_cart, size: 18),
                //     label: const Text(
                //       'REQUEST RESTOCK',
                //       style: TextStyle(
                //         fontWeight: FontWeight.bold,
                //         letterSpacing: 0.5,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 10),
                // SizedBox(
                //   width: double.infinity,
                //   height: 48,
                //   child: OutlinedButton.icon(
                //     style: OutlinedButton.styleFrom(
                //       side: const BorderSide(color: AppColors.border),
                //       backgroundColor: Colors.white,
                //       foregroundColor: AppColors.text,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //     onPressed: () {
                //       // Action logic for transfer stock
                //     },
                //     icon: const Icon(Icons.swap_horiz, size: 20),
                //     label: const Text(
                //       'TRANSFER STOCK',
                //       style: TextStyle(
                //         fontWeight: FontWeight.bold,
                //         letterSpacing: 0.5,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemInfoCard extends StatelessWidget {
  final InventoryItem item;

  const _ItemInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _gridItem('PRODUCT CODE', item.productCode ?? '-'),
              ),
              Expanded(child: _gridItem('BRAND', item.brandName ?? '-')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _gridItem(
                  'UNIT',
                  item.unit != null ? '${item.unit}' : '-',
                ),
              ),
              Expanded(
                child: _accentedMetric(
                  label: 'CURRENT STOCK',
                  value: '${item.currentStock}',
                  color: item.isLowStock ? AppColors.danger : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _accentedMetric(
                  label: 'REORDER LEVEL',
                  value: item.reorderLevel?.toString() ?? '-',
                  color: AppColors.muted,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.isLowStock
                                ? AppColors.danger.withOpacity(0.12)
                                : AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: item.isLowStock
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.status ??
                                    (item.isLowStock ? 'Low' : 'Normal'),
                                style: TextStyle(
                                  color: item.isLowStock
                                      ? AppColors.danger
                                      : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _gridItem('HSN/SAC', item.hsnSac ?? '-')),
              Expanded(
                child: _gridItem(
                  'SELLING PRICE',
                  item.sellingPrice != null ? '\$${item.sellingPrice}' : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _gridItem('CATEGORY', item.categoryName ?? '-'),
        ],
      ),
    );
  }

  Widget _gridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _accentedMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarehouseStockCard extends StatelessWidget {
  final AsyncValue<List<WarehouseStockRow>> stockAsync;

  const _WarehouseStockCard({required this.stockAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warehouse Stock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          stockAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No warehouse stock available.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 20, color: AppColors.border),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final isLow = row.quantity < 15; // Example dynamic check

                  return Row(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          row.warehouseName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        '${row.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppColors.danger : AppColors.text,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) {
              final isForbidden = e.toString().contains('403');
              return Text(
                isForbidden
                    ? 'You do not have permission to view warehouse stock.'
                    : 'Error: $e',
                style: const TextStyle(color: AppColors.danger),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Typeahead suggestions from the compact lookup API (6.1b).
/// Tapping a row fills the search box and runs the full search
/// so stock/reorder details load through the existing flow.
class _SuggestionsDropdown extends StatelessWidget {
  final List<ItemLookupResult> results;
  final ValueChanged<ItemLookupResult> onTap;

  const _SuggestionsDropdown({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visible = results.take(8).toList();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: visible.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final r = visible[index];
          final subtitleParts = [
            r.sku,
            if (r.brandName != null && r.brandName!.isNotEmpty) r.brandName!,
          ];
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: AppColors.muted,
            ),
            title: Text(
              r.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            subtitle: Text(
              subtitleParts.join(' • '),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            onTap: () => onTap(r),
          );
        },
      ),
    );
  }
}
