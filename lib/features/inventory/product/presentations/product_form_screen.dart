import 'dart:io';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/product/data/provider/product_provider.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'products_screen.dart';

const _statusOptions = ['ACTIVE', 'PENDING', 'REJECTED', 'INACTIVE'];
const _productTypeOptions = ['Physical', 'Service'];
const _sourcingOptions = {
  'Purchased': 'BUY',
  'In House': 'MAKE',
  'Outsourced': 'OUTSOURCED',
};

class _ProductDimensionDraft {
  final TextEditingController label;
  final TextEditingController value;
  final TextEditingController unit;

  _ProductDimensionDraft({String? label, String? value, String? unit})
      : label = TextEditingController(text: label ?? ''),
        value = TextEditingController(text: value ?? ''),
        unit = TextEditingController(text: unit ?? '');

  void dispose() {
    label.dispose();
    value.dispose();
    unit.dispose();
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  final InventoryItem? existing;

  const ProductFormScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _unit;
  late final TextEditingController _productCode;
  late final TextEditingController _brandName;
  late final TextEditingController _mrp;
  late final TextEditingController _b2bPrice;
  late final TextEditingController _sellingPrice;
  late final TextEditingController _costPrice;
  late final TextEditingController _description;
  late final TextEditingController _openingStock;

  int? _categoryId;
  int? _warehouseId;
  final List<_ProductDimensionDraft> _dimensions = [];
  String _status = 'ACTIVE';
  String _productType = 'Physical';
  String _sourcing = 'BUY';
  bool _saving = false;
  bool _fetchingCode = false;
  XFile? _selectedImage;
  final _imagePicker = ImagePicker();

  static const _maxImageBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sku = TextEditingController(text: e?.sku ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _productCode = TextEditingController(text: e?.productCode ?? '');
    _brandName = TextEditingController(text: e?.brandName ?? '');
    _mrp = TextEditingController(text: e?.mrp?.toString() ?? '');
    _b2bPrice = TextEditingController(text: e?.b2bPrice?.toString() ?? '');
    _sellingPrice =
        TextEditingController(text: e?.sellingPrice?.toString() ?? '');
    _costPrice = TextEditingController(text: e?.costPrice?.toString() ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _openingStock =
        TextEditingController(text: e?.openingStock?.toString() ?? '0');
    _categoryId = e?.categoryId;
    _dimensions.addAll(e?.productDimensions.map((dimension) {
          return _ProductDimensionDraft(
            label: dimension['label']?.toString(),
            value: dimension['value']?.toString(),
            unit: dimension['unit']?.toString(),
          );
        }) ?? const <_ProductDimensionDraft>[]);
    _status = e?.status?.toUpperCase() ?? 'ACTIVE';
    _productType = _productTypeOptions.contains(e?.productType)
        ? e!.productType!
        : 'Physical';
    _sourcing = _sourcingOptions.containsValue(e?.sourcing?.toUpperCase())
        ? e!.sourcing!.toUpperCase()
        : 'BUY';
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unit.dispose();
    _productCode.dispose();
    _brandName.dispose();
    _mrp.dispose();
    _b2bPrice.dispose();
    _sellingPrice.dispose();
    _costPrice.dispose();
    _description.dispose();
    _openingStock.dispose();
    for (final dimension in _dimensions) {
      dimension.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchNextCode() async {
    setState(() => _fetchingCode = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final code = await repo.getNextProductCode();
      if (code != null && mounted) {
        setState(() => _productCode.text = code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingCode = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return;

    final size = await image.length();
    if (size > _maxImageBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be 5 MB or smaller')),
        );
      }
      return;
    }

    if (mounted) setState(() => _selectedImage = image);
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child:
                      Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  num? _numOrNull(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }

  void _addDimension() {
    setState(() => _dimensions.add(_ProductDimensionDraft()));
  }

  void _removeDimension(int index) {
    final dimension = _dimensions.removeAt(index);
    dimension.dispose();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'unit': _unit.text.trim(),
      'categoryId': _categoryId,
      'status': _status,
      if (_productCode.text.trim().isNotEmpty)
        'productCode': _productCode.text.trim(),
      if (_brandName.text.trim().isNotEmpty) 'brandName': _brandName.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_numOrNull(_mrp.text) != null) 'mrp': _numOrNull(_mrp.text),
      if (_numOrNull(_b2bPrice.text) != null)
        'b2bPrice': _numOrNull(_b2bPrice.text),
      if (_numOrNull(_sellingPrice.text) != null)
        'sellingPrice': _numOrNull(_sellingPrice.text),
      if (_numOrNull(_costPrice.text) != null)
        'costPrice': _numOrNull(_costPrice.text),
      'productType': _productType,
      'sourcing': _sourcing,
      if (_numOrNull(_openingStock.text) != null)
        'openingStock': _numOrNull(_openingStock.text),
      if (_warehouseId != null) 'warehouseHint': _warehouseId,
      if (_dimensions.any((dimension) => dimension.label.text.trim().isNotEmpty))
        'productDimensions': _dimensions
            .where((dimension) => dimension.label.text.trim().isNotEmpty)
            .map((dimension) => {
                  'label': dimension.label.text.trim(),
                  if (dimension.value.text.trim().isNotEmpty)
                    'value': dimension.value.text.trim(),
                  if (dimension.unit.text.trim().isNotEmpty)
                    'unit': dimension.unit.text.trim(),
                })
            .toList(),
    };

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final Map<String, dynamic> res;
      if (widget.isEdit) {
        res = await repo.updateItem(
          widget.existing!.id,
          body,
          imagePath: _selectedImage?.path,
          imageFilename: _selectedImage?.name,
        );
      } else {
        res = await repo.createItem(
          body,
          imagePath: _selectedImage?.path,
          imageFilename: _selectedImage?.name,
        );
      }

      if (!mounted) return;

      final wentToApproval = res['approvalId'] != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: wentToApproval ? AppColors.accent : Colors.green,
          content: Text(
            wentToApproval
                ? (res['message']?.toString() ?? 'Sent for approval')
                : (widget.isEdit ? 'Product updated' : 'Product created'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final warehousesAsync = ref.watch(productWarehousesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        title: Text(
          widget.isEdit ? 'Edit Product' : 'Add Product',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _buildImagePicker(),
                const SizedBox(height: 16),
                _sectionCard(
                  icon: Icons.info_outline,
                  title: 'Basic details',
                  children: [
                    _field(_name, 'Name *', validator: _requiredValidator),
                    _field(_sku, 'SKU *', validator: _requiredValidator),
                    _field(_unit, 'Unit * (e.g. Nos, Kg)',
                        validator: _requiredValidator),
                    categoriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Text(
                        'Could not load categories: ${e.toString().replaceFirst('Exception: ', '')}',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                      data: (categories) {
                        final validValue = categories.any((c) => c.id == _categoryId)
                            ? _categoryId
                            : null;
                        return _dropdown<int>(
                          label: 'Category *',
                          value: validValue,
                          items: categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(_productCode, 'Product code')),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _fetchingCode ? null : _fetchNextCode,
                            child: _fetchingCode
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Auto'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(_brandName, 'Brand'),
                    _statusChips(),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.sell_outlined,
                  title: 'Pricing',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field(_mrp, 'MRP',
                              keyboardType: TextInputType.number, prefix: '₹'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_b2bPrice, 'B2B Price',
                              keyboardType: TextInputType.number, prefix: '₹'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_costPrice, 'Cost Price',
                              keyboardType: TextInputType.number, prefix: '₹'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_sellingPrice, 'Selling Price',
                              keyboardType: TextInputType.number, prefix: '₹'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.category_outlined,
                  title: 'Classification',
                  children: [
                    Text('Product type',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                    const SizedBox(height: 6),
                    _segmented(
                      options: _productTypeOptions,
                      selected: _productType,
                      onSelected: (v) => setState(() => _productType = v),
                    ),
                    const SizedBox(height: 14),
                    Text('Sourcing',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                    const SizedBox(height: 6),
                    _segmented(
                      options: _sourcingOptions.keys.toList(),
                      selected: _sourcingOptions.entries
                          .firstWhere((e) => e.value == _sourcing)
                          .key,
                      onSelected: (label) =>
                          setState(() => _sourcing = _sourcingOptions[label]!),
                    ),
                    const SizedBox(height: 14),
                    warehousesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (e, _) => Text(
                        'Could not load warehouses: ${e.toString().replaceFirst('Exception: ', '')}',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                      data: (warehouses) => _dropdown<int>(
                        label: 'Warehouse *',
                        value: _warehouseId,
                        validator: (value) =>
                            value == null ? 'Please select a warehouse' : null,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('No warehouse selected'),
                          ),
                          ...warehouses.map(
                            (warehouse) => DropdownMenuItem<int>(
                              value: warehouse.id,
                              child: Text(warehouse.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _warehouseId = value),
                      ),
                    ),
                    _field(_openingStock, 'Opening stock',
                        keyboardType: TextInputType.number),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.straighten_outlined,
                  title: 'Dimensions',
                  trailing: TextButton.icon(
                    onPressed: _saving ? null : _addDimension,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  children: [_buildDimensions()],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.notes_outlined,
                  title: 'Description',
                  children: [
                    _field(_description, 'Add product notes or details',
                        maxLines: 4, showLabel: false),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.isEdit ? 'Save changes' : 'Create product',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _statusChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((status) {
              final selected = _status == status;
              final color = _statusColor(status);
              return ChoiceChip(
                label: Text(status),
                selected: selected,
                onSelected: (_) => setState(() => _status = status),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
                selectedColor: color,
                backgroundColor: color.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: color.withOpacity(0.4)),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return AppColors.danger;
      case 'INACTIVE':
      default:
        return AppColors.muted;
    }
  }

  Widget _segmented({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.text,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final existingImageUrl = resolveImageUrl(widget.existing?.imageUrl);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _selectedImage != null
                      ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                      : existingImageUrl != null
                          ? Image.network(existingImageUrl, fit: BoxFit.cover)
                          : ColoredBox(
                              color: AppColors.surface,
                              child: Icon(Icons.inventory_2_outlined,
                                  color: AppColors.muted, size: 30),
                            ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: _saving ? null : _chooseImageSource,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product image',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'PNG or JPG, up to 5 MB',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _chooseImageSource,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                          _selectedImage == null ? 'Upload' : 'Replace'),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 14),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _selectedImage = null),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensions() {
    if (_dimensions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.straighten, color: AppColors.muted, size: 22),
            const SizedBox(height: 6),
            Text(
              'Add attributes such as length, width, weight, or grade',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _dimensions.asMap().entries.map((entry) {
        final index = entry.key;
        final dimension = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field(dimension.label, 'Name')),
              const SizedBox(width: 8),
              Expanded(child: _field(dimension.value, 'Value')),
              const SizedBox(width: 8),
              Expanded(child: _field(dimension.unit, 'Unit')),
              IconButton(
                tooltip: 'Remove dimension',
                onPressed: _saving ? null : () => _removeDimension(index),
                icon: Icon(Icons.close, size: 18, color: AppColors.muted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
    bool showLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: showLabel ? label : null,
          hintText: showLabel ? null : label,
          prefixText: prefix,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}