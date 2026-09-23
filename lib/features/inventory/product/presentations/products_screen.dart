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
      return const Color(0xFF16A34A);
    case 'PENDING':
      return const Color(0xFFD97706);
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
    setState(() {}); // refresh clear-icon visibility
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsListProvider);
    final canManage = ref.watch(authProvider).canAny(
          AppPermissions.productManageAccess,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              elevation: 1,
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
                if (created == true) {
                  ref.read(productsListProvider.notifier).refresh();
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          _SearchBar(controller: _searchController, onChanged: _onSearchChanged),
          const SizedBox(height: 4),
          _StatusTabs(state: state),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProductsListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFFB0B5BD)),
            SizedBox(height: 12),
            Center(
              child: Text(
                'No products found',
                style: TextStyle(color: Color(0xFF8A8F98), fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
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
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, SKU or code',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9AA0A8)),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9AA0A8)),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF9AA0A8)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFECEDF0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.4),
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: ProductStatusFilter.values.map((f) {
          final selected = state.statusFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(productsListProvider.notifier).setStatusFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : const Color(0xFFECEDF0),
                  ),
                ),
                child: Text(
                  '${f.label} · ${counts[f] ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF6B7078),
                  ),
                ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 58,
                    height: 58,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (item.productCode != null) item.productCode!,
                          if (item.categoryName != null) item.categoryName!,
                          if (item.brandName != null) item.brandName!,
                        ].join('  ·  '),
                        style: const TextStyle(color: Color(0xFF9AA0A8), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.mrp != null) _priceTag('MRP', item.mrp!),
                          if (item.b2bPrice != null) _priceTag('B2B', item.b2bPrice!),
                          if (item.costPrice != null) _priceTag('Cost', item.costPrice!),
                          if (item.sellingPrice != null)
                            _priceTag('Sell', item.sellingPrice!, highlight: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                            size: 13,
                            color: item.isLowStock ? AppColors.danger : const Color(0xFF9AA0A8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${item.currentStock} ${item.unit ?? ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: item.isLowStock ? AppColors.danger : const Color(0xFF9AA0A8),
                              fontWeight: item.isLowStock ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceTag(String label, num value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withOpacity(0.10) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ₹$value',
        style: TextStyle(
          fontSize: 14,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          color: highlight ? AppColors.primary : const Color(0xFF6B7078),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFB0B5BD), size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status!.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
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
            Icon(Icons.error_outline, color: AppColors.danger, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7078)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}