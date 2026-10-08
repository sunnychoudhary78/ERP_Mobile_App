import 'dart:convert';
import 'dart:io';
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:erp_app/features/inventory/product/data/provider/product_provider.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_product_type.dart';
import 'package:erp_app/features/inventory/shared/data/models/inventory_item_model.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'products_screen.dart';

const _statusOptions = ['ACTIVE', 'PENDING', 'REJECTED', 'INACTIVE'];
const _unitOptions = [
  'Micrometer (µm)',
  'ml',
  'mm',
  'Nos (numbers)',
  'pack',
  'pair',
  'pcs (pieces)',
];
const _sourcingOptions = {
  'Purchased': 'BUY',
  'In House': 'MAKE',
  'Outsourced': 'OUTSOURCED',
};
const _sourcingIcons = {
  'Purchased': Icons.shopping_bag_outlined,
  'In House': Icons.precision_manufacturing_outlined,
  'Outsourced': Icons.local_shipping_outlined,
};

const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
final List<TextInputFormatter> _decimalFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
];

/// SKU may contain only letters, digits and - _ . / #
/// (no emoji, spaces or other symbols). Edit here to change what is allowed.
final RegExp _skuAllowedChar = RegExp(r'[A-Za-z0-9\-_./#]');
final RegExp _skuPattern = RegExp(r'^[A-Za-z0-9\-_./#]+$');
final List<TextInputFormatter> _skuFormatters = [
  FilteringTextInputFormatter.allow(_skuAllowedChar),
];

// ───────────────────────── Design tokens ─────────────────────────
const double _radiusField = 12;
const double _radiusCard = 16;
const double _fieldGap = 14;

OutlineInputBorder _outline(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radiusField),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Label that shows a red asterisk when the text ends with " *".
Widget _labelText(String label) {
  if (label.endsWith(' *')) {
    return Text.rich(
      TextSpan(
        text: label.substring(0, label.length - 2),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  return Text(label);
}

/// One shared decoration for every input in the form, so all fields,
/// dropdowns and the unit picker look identical.
InputDecoration _decoration({
  String? label,
  String? hint,
  String? prefix,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    label: label == null ? null : _labelText(label),
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.muted.withOpacity(0.7),
      fontSize: 14,
    ),
    labelStyle: TextStyle(color: AppColors.muted, fontSize: 14),
    floatingLabelStyle: TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
    prefixText: prefix,
    prefixStyle: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: _outline(AppColors.border),
    enabledBorder: _outline(AppColors.border),
    disabledBorder: _outline(AppColors.border.withOpacity(0.6)),
    focusedBorder: _outline(AppColors.primary, width: 1.6),
    errorBorder: _outline(AppColors.danger),
    focusedErrorBorder: _outline(AppColors.danger, width: 1.6),
    errorStyle: TextStyle(color: AppColors.danger, fontSize: 12),
  );
}

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
  String? _warehouseHint;

  /// Snapshot of the form as it was when opened (edit mode). Used to detect
  /// whether the user actually changed anything before sending an approval.
  String? _initialSnapshot;
  final List<_ProductDimensionDraft> _dimensions = [];
  String _status = 'ACTIVE';
  String? _productType;
  String? _sourcing;
  bool _saving = false;
  bool _fetchingCode = false;
  XFile? _selectedImage;
  final _imagePicker = ImagePicker();

  static const _maxImageBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    // Always load a fresh warehouse list when the form opens, so a warehouse
    // created after the provider was first cached shows up in the dropdown.
    Future.microtask(() {
      if (mounted) ref.invalidate(productWarehousesProvider);
    });
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sku = TextEditingController(text: e?.sku ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _productCode = TextEditingController(text: e?.productCode ?? '');
    _brandName = TextEditingController(text: e?.brandName ?? '');
    _mrp = TextEditingController(text: e?.mrp?.toString() ?? '');
    _b2bPrice = TextEditingController(text: e?.b2bPrice?.toString() ?? '');
    _sellingPrice = TextEditingController(
      text: e?.sellingPrice?.toString() ?? '',
    );
    _costPrice = TextEditingController(text: e?.costPrice?.toString() ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _openingStock = TextEditingController(
      text: e?.openingStock?.toString() ?? '0',
    );
    _categoryId = e?.categoryId;
    _dimensions.addAll(
      e?.productDimensions.map((dimension) {
            return _ProductDimensionDraft(
              label: dimension['label']?.toString(),
              value: dimension['value']?.toString(),
              unit: dimension['unit']?.toString(),
            );
          }) ??
          const <_ProductDimensionDraft>[],
    );
    _status = e?.status?.toUpperCase() ?? 'ACTIVE';
    _productType = e?.productType?.toUpperCase() == 'PHYSICAL'
        ? 'Physical'
        : inventoryProductTypeLabel(e?.productType);
    _sourcing = _sourcingOptions.containsValue(e?.sourcing?.toUpperCase())
        ? e!.sourcing!.toUpperCase()
        : null;

    // Edit mode: pre-fill the warehouse the product was created with,
    // taken from the item's stock entries.
    if (e != null && e.stocks.isNotEmpty) {
      _warehouseId = e.stocks.first.warehouseId;
      _warehouseHint = e.stocks.first.warehouseName;
    }

    _initialSnapshot = _snapshot();
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
    final isCamera = source == ImageSource.camera;
    final image = await _imagePicker.pickImage(
      source: source,
      // Camera photos can be very large, so compress them at capture time
      // instead of asking the user to "upload a smaller image".
      maxWidth: isCamera ? 1920 : null,
      maxHeight: isCamera ? 1920 : null,
      imageQuality: isCamera ? 85 : null,
    );
    if (image == null) return;

    final size = await image.length();
    if (size > _maxImageBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCamera
                  ? 'Could not process the captured photo. Please try again.'
                  : 'Image must be 5 MB or smaller',
            ),
          ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Product photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to add the image',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              _sheetAction(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                subtitle: 'Pick an existing photo',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _sheetAction(
                icon: Icons.camera_alt_outlined,
                title: 'Take a photo',
                subtitle: 'Use your camera',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the unit picker.
  ///
  ///  * The keyboard is closed BEFORE the sheet opens, and the sheet does not
  ///    auto-focus a search box.
  ///  * The sheet is only "scroll controlled" when it actually has a search
  ///    box (long lists).
  ///  * Picking a unit only updates [_unit]'s controller, so just the unit
  ///    field repaints - the whole screen doesn't call setState().
  Future<void> _selectUnit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final currentUnit = _unit.text.trim();
    final options = <String>[
      ..._unitOptions,
      if (currentUnit.isNotEmpty && !_unitOptions.contains(currentUnit))
        currentUnit,
    ];

    final selectedUnit = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: options.length > _UnitPickerSheet.searchThreshold,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _UnitPickerSheet(options: options, selected: currentUnit),
    );

    if (selectedUnit != null && mounted) {
      _unit.text = selectedUnit;
    }
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
    setState(() {});
    // Dispose after the row has left the tree, not while it is still mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => dimension.dispose());
  }

  /// Builds the request body from the current form state.
  Map<String, dynamic> _buildBody() {
    return <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'unit': _unit.text.trim(),
      'categoryId': _categoryId,
      'status': _status,
      if (_productCode.text.trim().isNotEmpty)
        'productCode': _productCode.text.trim(),
      if (_brandName.text.trim().isNotEmpty)
        'brandName': _brandName.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_numOrNull(_mrp.text) != null) 'mrp': _numOrNull(_mrp.text),
      if (_numOrNull(_b2bPrice.text) != null)
        'b2bPrice': _numOrNull(_b2bPrice.text),
      if (_numOrNull(_sellingPrice.text) != null)
        'sellingPrice': _numOrNull(_sellingPrice.text),
      if (_numOrNull(_costPrice.text) != null)
        'costPrice': _numOrNull(_costPrice.text),
      if (_productType != null)
        'productType': inventoryProductTypeApiValues[_productType],
      if (_sourcing != null) 'sourcing': _sourcing,
      if (_numOrNull(_openingStock.text) != null)
        'openingStock': _numOrNull(_openingStock.text),
      if (_warehouseHint != null) 'warehouseHint': _warehouseHint,
      if (_dimensions.any(
        (dimension) => dimension.label.text.trim().isNotEmpty,
      ))
        'productDimensions': _dimensions
            .where((dimension) => dimension.label.text.trim().isNotEmpty)
            .map(
              (dimension) => {
                'label': dimension.label.text.trim(),
                if (dimension.value.text.trim().isNotEmpty)
                  'value': dimension.value.text.trim(),
                if (dimension.unit.text.trim().isNotEmpty)
                  'unit': dimension.unit.text.trim(),
              },
            )
            .toList(),
    };
  }

  String _snapshot() => jsonEncode(_buildBody());

  /// True when nothing was changed compared to the product as it was opened.
  bool get _hasNoChanges =>
      widget.isEdit &&
      _selectedImage == null &&
      _initialSnapshot != null &&
      _snapshot() == _initialSnapshot;

  /// If the product has a warehouse but only its name is known (or the id was
  /// not on the model), match it against the loaded warehouse list so the
  /// dropdown shows the saved warehouse instead of being empty.
  void _syncWarehouseFromExisting(List<dynamic> warehouses) {
    if (!widget.isEdit || _warehouseId != null) return;
    final name = _warehouseHint?.trim().toLowerCase();
    if (name == null || name.isEmpty) return;
    for (final w in warehouses) {
      if ((w.name as String).trim().toLowerCase() == name) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _warehouseId = w.id as int;
            _warehouseHint = w.name as String;
            // Re-baseline so the auto-filled warehouse isn't seen as a change.
            _initialSnapshot = _snapshot();
          });
        });
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a warehouse')),
      );
      return;
    }

    // Nothing changed -> don't create a new approval request for the manager.
    if (_hasNoChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No changes to save'),
        ),
      );
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _saving = true);

    final body = _buildBody();

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

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final warehousesAsync = ref.watch(productWarehousesProvider);
    final existingName = widget.existing?.name.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.isEdit && existingName != null && existingName.isNotEmpty
                  ? existingName
                  : 'Fields marked * are required',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      resizeToAvoidBottomInset: true,
      // As a bottomNavigationBar the save button sits above the keyboard and
      // the form body shrinks to the space left, so the focused field can
      // always scroll fully into view.
      bottomNavigationBar: RepaintBoundary(child: _buildBottomBar()),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.info_outline_rounded,
              title: 'Basic details',
              subtitle: 'Name, SKU, category and status',
              children: [
                _field(
                  _name,
                  'Name *',
                  validator: _requiredValidator,
                  textCapitalization: TextCapitalization.words,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _field(
                        _sku,
                        'SKU *',
                        validator: _skuValidator,
                        inputFormatters: _skuFormatters,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _unitField()),
                  ],
                ),
                categoriesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: _fieldGap),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(bottom: _fieldGap),
                    child: Text(
                      'Could not load categories: ${e.toString().replaceFirst('Exception: ', '')}',
                      style: TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ),
                  data: (categories) {
                    final validValue =
                        categories.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null;
                    return _dropdown<int>(
                      label: 'Category *',
                      value: validValue,
                      validator: (v) =>
                          v == null ? 'Please select a category' : null,
                      items: categories.map((c) {
                        final type = c.type?.trim();
                        final label = type == null || type.isEmpty
                            ? c.name
                            : '${c.name} ($type)';
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    );
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        _productCode,
                        'Product code',
                        suffixIcon: _autoCodeButton(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _brandName,
                        'Brand',
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
                _statusChips(),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.sell_outlined,
              title: 'Pricing',
              subtitle: 'All amounts in rupees',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        _mrp,
                        'MRP',
                        keyboardType: _decimalKeyboard,
                        inputFormatters: _decimalFormatters,
                        prefix: '₹ ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _sellingPrice,
                        'Selling price',
                        keyboardType: _decimalKeyboard,
                        inputFormatters: _decimalFormatters,
                        prefix: '₹ ',
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        _b2bPrice,
                        'B2B price',
                        keyboardType: _decimalKeyboard,
                        inputFormatters: _decimalFormatters,
                        prefix: '₹ ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _costPrice,
                        'Cost price',
                        keyboardType: _decimalKeyboard,
                        inputFormatters: _decimalFormatters,
                        prefix: '₹ ',
                      ),
                    ),
                  ],
                ),
                _marginHint(),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.category_outlined,
              title: 'Classification & stock',
              subtitle: 'Type, sourcing and warehouse',
              children: [
                _dropdown<String>(
                  label: 'Product type',
                  value: _productType,
                  items: inventoryProductTypeApiValues.keys
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (type) => setState(() => _productType = type),
                ),
                _fieldLabel('Sourcing'),
                const SizedBox(height: 8),
                _segmented(
                  options: _sourcingOptions.keys.toList(),
                  selected: _sourcing == null
                      ? null
                      : _sourcingOptions.entries
                            .firstWhere((e) => e.value == _sourcing)
                            .key,
                  onSelected: (label) =>
                      setState(() => _sourcing = _sourcingOptions[label]),
                ),
                const SizedBox(height: _fieldGap + 2),
                warehousesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: _fieldGap),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(bottom: _fieldGap),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Could not load warehouses: ${e.toString().replaceFirst('Exception: ', '')}',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(productWarehousesProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (warehouses) {
                    _syncWarehouseFromExisting(warehouses);
                    final validWarehouseId =
                        warehouses.any((w) => w.id == _warehouseId)
                        ? _warehouseId
                        : null;
                    return _dropdown<int>(
                      label: 'Warehouse *',
                      value: validWarehouseId,
                      items: warehouses
                          .map(
                            (warehouse) => DropdownMenuItem<int>(
                              value: warehouse.id,
                              child: Text(
                                warehouse.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                          v == null ? 'Please select a warehouse' : null,
                      onChanged: (value) {
                        String? warehouseHint;
                        for (final warehouse in warehouses) {
                          if (warehouse.id == value) {
                            warehouseHint = warehouse.name;
                            break;
                          }
                        }
                        setState(() {
                          _warehouseId = value;
                          _warehouseHint = warehouseHint;
                        });
                      },
                    );
                  },
                ),
                _field(
                  _openingStock,
                  'Opening stock',
                  keyboardType: _decimalKeyboard,
                  inputFormatters: _decimalFormatters,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.straighten_outlined,
              title: 'Dimensions',
              subtitle: 'Optional product attributes',
              trailing: TextButton.icon(
                onPressed: _saving ? null : _addDimension,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              children: [_buildDimensions()],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.notes_outlined,
              title: 'Description',
              subtitle: 'Notes or extra details',
              children: [
                _field(
                  _description,
                  'Add product notes or details',
                  maxLines: 4,
                  showLabel: false,
                  isLast: true,
                  // Keep extra room below the caret while typing so the
                  // text never ends up behind the keyboard.
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isEdit
                            ? Icons.check_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEdit ? 'Save changes' : 'Create product',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

  String? _skuValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Required';
    if (!_skuPattern.hasMatch(value)) {
      return 'Only letters, numbers and - _ . / # are allowed';
    }
    return null;
  }

  /// Small caption above chip / segmented groups.
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 0.2,
      ),
    );
  }

  /// "Auto" generator shown inside the Product code field.
  Widget _autoCodeButton() {
    if (_fetchingCode) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: 'Generate next code',
      onPressed: _saving ? null : _fetchNextCode,
      icon: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
    );
  }

  /// Live margin helper under the pricing fields. Rebuilds only itself.
  Widget _marginHint() {
    return ListenableBuilder(
      listenable: Listenable.merge([_mrp, _sellingPrice, _costPrice]),
      builder: (context, _) {
        final sell = _numOrNull(_sellingPrice.text);
        final cost = _numOrNull(_costPrice.text);
        final mrp = _numOrNull(_mrp.text);

        final hints = <Widget>[];

        if (sell != null && cost != null && sell > 0) {
          final profit = sell - cost;
          final pct = profit / sell * 100;
          final positive = profit >= 0;
          final color = positive ? Colors.green.shade700 : AppColors.danger;
          hints.add(
            _hintPill(
              icon: positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
              text:
                  'Margin ₹${profit.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
            ),
          );
        }

        if (sell != null && mrp != null && sell > mrp) {
          hints.add(
            _hintPill(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              text: 'Selling price is above MRP',
            ),
          );
        }

        if (hints.isEmpty) return const SizedBox.shrink();
        return Wrap(spacing: 8, runSpacing: 8, children: hints);
      },
    );
  }

  Widget _hintPill({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Status'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statusOptions.map((status) {
            final selected = _status == status;
            final color = _statusColor(status);
            return ChoiceChip(
              avatar: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              label: Text(status),
              selected: selected,
              onSelected: (_) => setState(() => _status = status),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: selected ? Colors.white : color,
              ),
              selectedColor: color,
              backgroundColor: color.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? color : color.withOpacity(0.35),
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
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
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_radiusField),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          final fg = isSelected ? Colors.white : AppColors.text;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sourcingIcons[option] ?? Icons.circle_outlined,
                      size: 19,
                      color: fg,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        option,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
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
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.muted,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            'No image',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final existingImageUrl = resolveImageUrl(widget.existing?.imageUrl);
    final hasImage = _selectedImage != null || existingImageUrl != null;

    // The preview is only ~100dp wide. Decode it at that size instead of
    // decoding a full-resolution camera photo into memory.
    const decodeWidth = 400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _saving ? null : _chooseImageSource,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _selectedImage != null
                        ? Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            cacheWidth: decodeWidth,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : existingImageUrl != null
                        ? Image.network(
                            existingImageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: decodeWidth,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product image',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'PNG or JPG, up to 5 MB',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseImageSource,
                      icon: Icon(
                        hasImage
                            ? Icons.swap_horiz_rounded
                            : Icons.upload_rounded,
                        size: 17,
                      ),
                      label: Text(hasImage ? 'Replace' : 'Upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _selectedImage = null),
                        icon: const Icon(Icons.delete_outline_rounded, size: 17),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
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
      return InkWell(
        borderRadius: BorderRadius.circular(_radiusField),
        onTap: _saving ? null : _addDimension,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_radiusField),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                'Add an attribute',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Length, width, weight, grade and more',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _dimensions.length; index++)
          _dimensionRow(index, _dimensions[index]),
      ],
    );
  }

  Widget _dimensionRow(int index, _ProductDimensionDraft dimension) {
    return Container(
      // A stable key keeps each row's text state attached to the right draft
      // when a row in the middle is removed.
      key: ObjectKey(dimension),
      margin: EdgeInsets.only(bottom: index == _dimensions.length - 1 ? 0 : 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_radiusField),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attribute ${index + 1}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove dimension',
                visualDensity: VisualDensity.compact,
                onPressed: _saving ? null : () => _removeDimension(index),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _field(dimension.label, 'Name (e.g. Length)'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _field(dimension.value, 'Value', isLast: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _field(dimension.unit, 'Unit', isLast: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: _fieldGap),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: _saving ? null : onChanged,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        isExpanded: true,
        menuMaxHeight: 320,
        borderRadius: BorderRadius.circular(_radiusField),
        dropdownColor: Colors.white,
        icon: Icon(Icons.expand_more_rounded, color: AppColors.muted),
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        decoration: _decoration(label: label),
      ),
    );
  }

  Widget _unitField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _fieldGap),
      child: TextFormField(
        controller: _unit,
        readOnly: true,
        enableInteractiveSelection: false,
        // Clears the "Required" error as soon as a unit is picked.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTap: _saving ? null : _selectUnit,
        validator: _requiredValidator,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        decoration: _decoration(
          label: 'Unit *',
          suffixIcon: Icon(Icons.expand_more_rounded, color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? prefix,
    Widget? suffixIcon,
    bool showLabel = true,
    bool isLast = false,
    EdgeInsets scrollPadding = const EdgeInsets.all(20),
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : _fieldGap),
      child: TextFormField(
        controller: controller,
        scrollPadding: scrollPadding,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        decoration: _decoration(
          label: showLabel ? label : null,
          hint: showLabel ? null : label,
          prefix: prefix,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

/// Bottom sheet used to pick a unit.
///
/// Light by design: a simple fixed-height list, no auto-focused keyboard.
/// A search box only appears when the list is long (more than
/// [searchThreshold] units), and even then it is not auto-focused.
class _UnitPickerSheet extends StatefulWidget {
  static const searchThreshold = 8;

  final List<String> options;
  final String selected;

  const _UnitPickerSheet({required this.options, required this.selected});

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  static const _rowExtent = 54.0;

  late final bool _showSearch =
      widget.options.length > _UnitPickerSheet.searchThreshold;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
              .where((unit) => unit.toLowerCase().contains(_query))
              .toList();

    // Only follow the keyboard when there is a search box to type into.
    final bottomInset = _showSearch
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select unit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unit of measure for this product',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (_showSearch) ...[
                TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search units',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: _outline(AppColors.border),
                    enabledBorder: _outline(AppColors.border),
                    focusedBorder: _outline(AppColors.primary, width: 1.6),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No matching units',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemExtent: _rowExtent,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final unit = filtered[index];
                          return _UnitTile(
                            unit: unit,
                            isSelected: unit == widget.selected,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final String unit;
  final bool isSelected;

  const _UnitTile({required this.unit, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(_radiusField),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radiusField),
          onTap: () => Navigator.of(context).pop(unit),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}