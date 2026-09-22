import 'dart:async';

import 'package:erp_app/core/network/api_constants.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/product/data/provider/product_provider.dart';
import 'package:erp_app/features/inventory/product/presentations/product_details_screen.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_form_screen.dart';

/// Resolves an item's (possibly relative, `/api/uploads/...`) imageUrl into
/// an absolute URL using the current environment's API origin.
String? resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  final origin = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api.*$'), '');
  return '$origin$path';
}

Color statusColor(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'ACTIVE':
      return Colors.green;
    case 'PENDING':
      return Colors.orange;
    case 'REJECTED':
      return AppColors.danger;
    case 'INACTIVE':
      return AppColors.muted;
    default:
      return AppColors.muted;
  }
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(productsListProvider.notifier).search(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsListProvider);
    final canManage = ref.watch(authProvider).canAny(
          AppPermissions.productManageAccess,
        );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Products'),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
                if (created == true) {
                  ref.read(productsListProvider.notifier).refresh();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _SearchBar(controller: _searchController, onChanged: _onSearchChanged),
          _StatusTabs(state: state),
          const Divider(height: 1),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProductsListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(productsListProvider.notifier).refresh(),
      );
    }

    final filtered = state.filteredItems;

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(productsListProvider.notifier).refresh(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No products found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = filtered[index];
          return _ProductCard(
            item: item,
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(item: item),
                ),
              );
              if (changed == true) {
                ref.read(productsListProvider.notifier).refresh();
              }
            },
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search products by name / SKU / code',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _StatusTabs extends ConsumerWidget {
  final ProductsListState state;

  const _StatusTabs({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = state.statusCounts;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: ProductStatusFilter.values.map((f) {
          final selected = state.statusFilter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${f.label} (${counts[f] ?? 0})'),
              selected: selected,
              onSelected: (_) =>
                  ref.read(productsListProvider.notifier).setStatusFilter(f),
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(item.imageUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.productCode != null) item.productCode!,
                        if (item.categoryName != null) item.categoryName!,
                        if (item.brandName != null) item.brandName!,
                      ].join(' • '),
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        _priceLabel('MRP', item.mrp),
                        _priceLabel('B2B', item.b2bPrice),
                        _priceLabel('Cost', item.costPrice),
                        _priceLabel('Sell', item.sellingPrice),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${item.currentStock} ${item.unit ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isLowStock ? AppColors.danger : AppColors.muted,
                        fontWeight: item.isLowStock ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceLabel(String label, num? value) {
    if (value == null) return const SizedBox.shrink();
    return Text(
      '$label ₹$value',
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 24),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.isEmpty) return const SizedBox.shrink();
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status!.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}