// lib/features/inventory/products/presentation/screens/product_form_screen.dart
//
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
    _openingStock = TextEditingController(text: e?.openingStock?.toString() ?? '0');
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
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a category')));
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
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
        title: Text(widget.isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            _field(_name, 'Name *', validator: _requiredValidator),
            _field(_sku, 'SKU *', validator: _requiredValidator),
            _field(_unit, 'Unit * (e.g. Nos, Kg)', validator: _requiredValidator),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Could not load categories: ${e.toString().replaceFirst('Exception: ', '')}',
                style: TextStyle(color: AppColors.danger),
              ),
              data: (categories) {
                final validValue = categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null;
                return DropdownButtonFormField<int>(
                  value: validValue,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_productCode, 'Product code')),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _fetchingCode ? null : _fetchNextCode,
                  child: _fetchingCode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Auto'),
                ),
              ],
            ),
            _field(_brandName, 'Brand'),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_mrp, 'MRP', keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_b2bPrice, 'B2B Price',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _field(_costPrice, 'Cost Price',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_sellingPrice, 'Selling Price',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _productType,
              decoration: const InputDecoration(
                labelText: 'Product type *',
                border: OutlineInputBorder(),
              ),
              items: _productTypeOptions
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _productType = value ?? _productType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sourcing,
              decoration: const InputDecoration(
                labelText: 'Sourcing *',
                border: OutlineInputBorder(),
              ),
              items: _sourcingOptions.entries
                  .map((option) => DropdownMenuItem(
                        value: option.value,
                        child: Text(option.key),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _sourcing = value ?? _sourcing),
            ),
            const SizedBox(height: 12),
            _field(_openingStock, 'Opening stock',
                keyboardType: TextInputType.number),
            warehousesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Could not load warehouses: ${e.toString().replaceFirst('Exception: ', '')}',
                style: TextStyle(color: AppColors.danger),
              ),
              data: (warehouses) => DropdownButtonFormField<int>(
                value: _warehouseId,
                decoration: const InputDecoration(
                  labelText: 'Warehouse *',
                  border: OutlineInputBorder(),
                ),
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
                validator: (value) =>
                  value == null ? 'Please select a warehouse' : null,
                onChanged: (value) => setState(() => _warehouseId = value),
              ),
            ),
            const SizedBox(height: 12),
            _buildDimensions(),
            _field(_description, 'Description', maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
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
                  : Text(widget.isEdit ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _buildImagePicker() {
    final existingImageUrl = resolveImageUrl(widget.existing?.imageUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product image', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 88,
                height: 88,
                child: _selectedImage != null
                    ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                    : existingImageUrl != null
                        ? Image.network(existingImageUrl, fit: BoxFit.cover)
                        : ColoredBox(
                            color: AppColors.surface,
                            child: Icon(Icons.image_outlined,
                                color: AppColors.muted, size: 34),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _chooseImageSource,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_selectedImage == null ? 'Add image' : 'Change image'),
            ),
            if (_selectedImage != null)
              IconButton(
                tooltip: 'Remove selected image',
                onPressed: _saving
                    ? null
                    : () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product dimensions (optional)',
                style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: _saving ? null : _addDimension,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_dimensions.isEmpty)
          Text('Add attributes such as length, width, weight, or grade.',
              style: TextStyle(color: AppColors.muted)),
        ..._dimensions.asMap().entries.map((entry) {
          final index = entry.key;
          final dimension = entry.value;
          return Row(
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
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}