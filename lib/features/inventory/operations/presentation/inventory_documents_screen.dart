import 'dart:async';

import 'package:dio/dio.dart';
import 'package:erp_app/core/permissions/app_permissions.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/shared/presentation/providers/inventory_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'inventory_ui_helpers.dart';

/// API origin used to resolve `/api/uploads/<file>` urls (same as the web
/// `resolveUploadUrl`). No trailing slash and no `/api`.
/// TODO: point this at your production origin / reuse your existing base-url
/// constant if the project already has one.
const String _apiOrigin = 'https://erp-uat.immortalgroup.in';

/// "Type Context" options from the web upload dialog (value -> label).
/// If the web sends different values, change them here only.
const Map<String, String> _docTypes = {
  'PURCHASE_INVOICE': 'Purchase Invoice',
  'PROCESSING_REPORT': 'Processing Report',
  'SALES_INVOICE': 'Sales Invoice',
  'QUALITY_AUDIT': 'Quality Audit',
};

const int _allLots = 0;
const int _globalOnly = -1;

class _DocsData {
  _DocsData(this.docs, this.lots)
    : lotById = {
        for (final lot in lots)
          if (_idOf(lot) > 0) _idOf(lot): lot,
      };

  final List<Map<String, dynamic>> docs;
  final List<Map<String, dynamic>> lots;
  final Map<int, Map<String, dynamic>> lotById;

  static int _idOf(Map<String, dynamic> lot) {
    final v = lot['id'] ?? lot['lotId'];
    return v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  }
}

class _DocumentDraft {
  const _DocumentDraft({
    required this.name,
    required this.type,
    required this.lotId,
    this.filePath,
    this.url,
  });

  final String name;
  final String type;
  final int? lotId;
  final String? filePath;
  final String? url;
}

class InventoryDocumentsScreen extends ConsumerStatefulWidget {
  const InventoryDocumentsScreen({super.key});

  @override
  ConsumerState<InventoryDocumentsScreen> createState() =>
      _InventoryDocumentsScreenState();
}

class _InventoryDocumentsScreenState
    extends ConsumerState<InventoryDocumentsScreen>
    with InventoryUiHelpers<InventoryDocumentsScreen> {
  late Future<_DocsData> _load;
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _lotFilter = _allLots;
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<_DocsData> _fetch() async {
    final repo = ref.read(inventoryRepositoryProvider);
    final docs = await asList(repo.getDocuments());
    if (kDebugMode && docs.isNotEmpty) debugPrint('DOCUMENT ROW: ${docs.first}');
    // Lots are only used to show "LOT-000003 (item)" instead of a raw id.
    // A failure here must not break the documents list.
    var lots = <dynamic>[];
    try {
      lots = await asList(repo.getLots());
    } catch (_) {}
    return _DocsData(
      docs.map((d) => mapOf(d)).toList(),
      lots.map((l) => mapOf(l)).toList(),
    );
  }

  @override
  void reload() => setState(() {
    _load = _fetch();
  });

  // ------------------------------------------------------------------ helpers
  int? _lotIdOf(Map<String, dynamic> doc) {
    final id = toInt(doc['lotId']);
    return id > 0 ? id : null;
  }

  String _lotLabel(Map<String, dynamic> lot) {
    final id = toInt(lot['id'] ?? lot['lotId']);
    final number = pickText(lot, ['lotNumber'], fallback: 'Lot #$id');
    final item = pickText(mapOf(lot['item']), ['name'], fallback: '');
    return item.isEmpty ? number : '$number ($item)';
  }

  String _lotNumberOf(Map<String, dynamic> doc, _DocsData data) {
    final id = _lotIdOf(doc);
    if (id == null) return 'Global Storage';
    final lot = data.lotById[id];
    return lot == null
        ? 'Lot #$id'
        : pickText(lot, ['lotNumber'], fallback: 'Lot #$id');
  }

  String _typeLabel(Map<String, dynamic> doc) {
    final raw = pickText(doc, ['type'], fallback: '').trim();
    return (raw.isEmpty ? 'DOCUMENT' : raw.replaceAll('_', ' ')).toUpperCase();
  }

  /// The backend row should have `createdAt`, but try common alternatives and
  /// finally any date-looking field so the date never silently shows "—".
  String _dateOf(Map<String, dynamic> doc) {
    const keys = [
      'createdAt',
      'created_at',
      'uploadedAt',
      'uploaded_at',
      'date',
      'createdOn',
      'updatedAt',
      'updated_at',
    ];
    for (final k in keys) {
      final v = doc[k];
      if (v != null && DateTime.tryParse('$v') != null) return fmtDate(v);
    }
    for (final e in doc.entries) {
      final k = e.key.toLowerCase();
      if ((k.contains('date') || k.contains('creat') || k.contains('upload')) &&
          e.value != null &&
          DateTime.tryParse('${e.value}') != null) {
        return fmtDate(e.value);
      }
    }
    return '—';
  }

  bool _matches(Map<String, dynamic> doc, _DocsData data) {
    final lotId = _lotIdOf(doc);
    if (_lotFilter == _globalOnly && lotId != null) return false;
    if (_lotFilter > 0 && lotId != _lotFilter) return false;
    if (_query.isNotEmpty) {
      final hay = [
        pickText(doc, ['name'], fallback: ''),
        _typeLabel(doc),
        _lotNumberOf(doc, data),
      ].join(' ').toLowerCase();
      if (!hay.contains(_query)) return false;
    }
    return true;
  }

  String _absoluteUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return '$_apiOrigin${u.startsWith('/') ? '' : '/'}$u';
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final canAdd = ref.watch(authProvider).canAny(const [
      AppPermissions.inventoryView,
      AppPermissions.dashboardView,
      AppPermissions.documentManage,
    ]);
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _addDocument,
              icon: const Icon(Icons.add),
              label: const Text('Add document'),
            )
          : null,
      body: loadBody<_DocsData>(
        future: _load,
        what: 'documents',
        builder: _content,
      ),
    );
  }

  Widget _content(_DocsData data) {
    final rows = data.docs.where((d) => _matches(d, data)).toList();
    final filter = (_lotFilter <= 0 || data.lotById.containsKey(_lotFilter))
        ? _lotFilter
        : _allLots;
    final hasFilters = _query.isNotEmpty || filter != _allLots;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name, type or lot',
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: DropdownButtonFormField<int>(
            value: filter,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Lot',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(value: _allLots, child: Text('All lots')),
              const DropdownMenuItem(
                value: _globalOnly,
                child: Text('Global Storage'),
              ),
              for (final lot in data.lots)
                if (data.lotById.containsKey(_DocsData._idOf(lot)))
                  DropdownMenuItem(
                    value: _DocsData._idOf(lot),
                    child: Text(_lotLabel(lot), overflow: TextOverflow.ellipsis),
                  ),
            ],
            onChanged: (v) => setState(() => _lotFilter = v ?? _allLots),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              hasFilters
                  ? '${rows.length} of ${data.docs.length} documents'
                  : '${data.docs.length} documents',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? messageList(
                  data.docs.isEmpty ? 'No documents' : 'No matching documents',
                  data.docs.isEmpty
                      ? 'Tap "Add document" to upload a file or add a link.'
                      : 'Try a different search or lot filter.',
                )
              : refreshList([for (final d in rows) _docCard(d, data)]),
        ),
      ],
    );
  }

  Widget _docCard(Map<String, dynamic> doc, _DocsData data) {
    final scheme = Theme.of(context).colorScheme;
    final lotId = _lotIdOf(doc);
    final lotName = _lotNumberOf(doc, data);
    final busy = _downloading.contains('${doc['id']}');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      pickText(doc, ['name'], fallback: 'Document'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Details',
                  icon: Icon(Icons.info_outline, color: scheme.primary),
                  onPressed: () => _showInfo(doc, data),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (lotId != null && data.lotById.containsKey(lotId))
                  InkWell(
                    onTap: () => setState(() => _lotFilter = lotId),
                    child: Text(
                      lotName,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Text(
                    lotName,
                    style: TextStyle(
                      color: lotId == null
                          ? Colors.black54
                          : scheme.primary,
                      fontWeight: lotId == null
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                const Text('•', style: TextStyle(color: Colors.black38)),
                Text(
                  _dateOf(doc),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  _typePill(_typeLabel(doc)),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: busy ? null : () => _download(doc),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 20),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typePill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blueGrey.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  // ------------------------------------------------------------------ details
  Future<void> _showInfo(Map<String, dynamic> doc, _DocsData data) {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    final lotId = _lotIdOf(doc);
    final lot = lotId == null ? null : data.lotById[lotId];
    final lotText = lotId == null
        ? 'Global Storage'
        : (lot == null ? 'Lot #$lotId' : _lotLabel(lot));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickText(doc, ['name'], fallback: 'Document'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              row('Type', _typeLabel(doc)),
              row('Lot', lotText),
              row('Uploaded', _dateOf(doc)),
              row('Updated', fmtDate(doc['updatedAt'])),
              row('File', pickText(doc, ['url'], fallback: '—')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _download(doc);
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Download'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ download
  Future<void> _download(Map<String, dynamic> doc) async {
    final url = _absoluteUrl(pickText(doc, ['url'], fallback: ''));
    if (url.isEmpty) {
      showError(Exception('This document has no file attached.'));
      return;
    }
    // A link added by URL (not an uploaded file) cannot be saved as a file.
    if (!url.contains('/uploads/')) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
      return;
    }
    final key = '${doc['id']}';
    setState(() => _downloading.add(key));
    try {
      final dir = await getTemporaryDirectory();
      final segments = Uri.parse(url).pathSegments;
      final fileName = segments.isEmpty ? 'document' : segments.last;
      final path = '${dir.path}/$fileName';
      await Dio().download(url, path);
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        showError(Exception(result.message));
      }
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => _downloading.remove(key));
    }
  }

  // ------------------------------------------------------------------ create
  Future<void> _addDocument() async {
    _DocsData? data;
    try {
      data = await _load;
    } catch (_) {}
    if (!mounted) return;
    final lots = <MapEntry<int, String>>[
      if (data != null)
        for (final lot in data.lots)
          if (_DocsData._idOf(lot) > 0)
            MapEntry(_DocsData._idOf(lot), _lotLabel(lot)),
    ];
    final draft = await showModalBottomSheet<_DocumentDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _KeyboardInset(child: _DocumentForm(lots: lots)),
    );
    if (draft == null) return;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (draft.url != null) {
        await repo.createDocumentLink(
          url: draft.url!,
          name: draft.name,
          type: draft.type,
          lotId: draft.lotId,
        );
        showSuccess('Document link added');
      } else {
        await repo.uploadDocument(
          name: draft.name,
          type: draft.type,
          lotId: draft.lotId,
          filePath: draft.filePath!,
        );
        showSuccess('Document uploaded');
      }
    } catch (e) {
      showError(e);
    }
  }
}

/// Lifts the bottom sheet above the keyboard without rebuilding the form on
/// every keyboard animation frame (the child instance is reused).
class _KeyboardInset extends StatelessWidget {
  const _KeyboardInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 100),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}

/// Same fields as the web upload dialog: name, Type Context, Lot ID, file/link.
class _DocumentForm extends StatefulWidget {
  const _DocumentForm({required this.lots});

  final List<MapEntry<int, String>> lots;

  @override
  State<_DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<_DocumentForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _url = TextEditingController();
  bool _isLink = false;
  String _type = _docTypes.keys.first;
  int? _lotId;
  PlatformFile? _file;
  String? _fileError;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final chosen = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = chosen?.files.single;
    if (file == null) return;
    if (file.size > 5 * 1024 * 1024) {
      setState(() => _fileError = 'File must be 5 MB or smaller.');
      return;
    }
    setState(() {
      _file = file;
      _fileError = null;
      if (_name.text.trim().isEmpty) {
        _name.text = file.name.replaceFirst(RegExp(r'\.[^.]*$'), '');
      }
    });
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (!_isLink && _file?.path == null) {
      setState(() => _fileError = 'Choose a PDF, JPG or PNG file');
      return;
    }
    if (!valid) return;
    Navigator.pop(
      context,
      _DocumentDraft(
        name: _name.text.trim(),
        type: _type,
        lotId: _lotId,
        filePath: _isLink ? null : _file!.path,
        url: _isLink ? _url.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add document',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Upload file'),
                    icon: Icon(Icons.upload_file),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Add link'),
                    icon: Icon(Icons.link),
                  ),
                ],
                selected: {_isLink},
                onSelectionChanged: (v) => setState(() => _isLink = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Document name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Type Context',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final e in _docTypes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                value: _lotId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Lot ID',
                  helperText: 'Leave as — to keep it in Global Storage',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('—')),
                  for (final lot in widget.lots)
                    DropdownMenuItem<int?>(
                      value: lot.key,
                      child: Text(lot.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _lotId = v),
              ),
              const SizedBox(height: 14),
              if (_isLink)
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    return Uri.tryParse(value)?.hasAbsolutePath == true &&
                            value.startsWith('http')
                        ? null
                        : 'Enter a valid URL';
                  },
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _file?.name ?? 'Choose file  (PDF, JPG, PNG · max 5 MB)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _fileError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(
                  _isLink ? Icons.add_link : Icons.cloud_upload_outlined,
                ),
                label: Text(_isLink ? 'Add link' : 'Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
