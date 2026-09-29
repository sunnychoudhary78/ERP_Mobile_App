
import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text-field decoration
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration appFieldDecoration(
  String label, {
  bool required = false,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? prefixText,
  String? errorText,
  bool dense = false,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    prefixText: prefixText,
    errorText: errorText,
    isDense: dense,
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: TextStyle(color: AppColors.muted, fontSize: 14),
    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
    contentPadding: EdgeInsets.symmetric(
      vertical: dense ? 12 : 14,
      horizontal: 14,
    ),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    disabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.accent, 1.4),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.4),
  );
}

/// RAW_MATERIAL / PENDING_APPROVAL  ->  Raw Material / Pending Approval
String appPrettyLabel(String value) {
  if (value.isEmpty) return value;
  if (!value.contains('_') && value != value.toUpperCase()) return value;
  return value
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Status colours / pill
// ─────────────────────────────────────────────────────────────────────────────

Color appStatusColor(String status) {
  final s = status.toUpperCase();
  if (s.contains('REJECT') || s.contains('CANCEL') || s.contains('FAIL')) {
    return AppColors.danger;
  }
  if (s.contains('INACTIVE')) return AppColors.muted;
  if (s.contains('APPROVED') ||
      s.contains('COMPLETE') ||
      s.contains('RECEIVED') ||
      s.contains('DELIVER') ||
      s.contains('CLOSED') ||
      s.contains('ACTIVE')) {
    return const Color(0xFF2E7D32);
  }
  if (s.contains('PENDING') ||
      s.contains('DRAFT') ||
      s.contains('OPEN') ||
      s.contains('PARTIAL') ||
      s.contains('PROCESS') ||
      s.contains('SUBMIT') ||
      s.contains('AWAIT')) {
    return const Color(0xFFB7791F);
  }
  return AppColors.muted;
}

class AppStatusPill extends StatelessWidget {
  final String status;

  const AppStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = appStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        (status.isEmpty ? 'UNKNOWN' : status).replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet shell
// ─────────────────────────────────────────────────────────────────────────────

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Sheet shell: fixed header, scrolling body, pinned footer.
/// The keyboard lifts the whole sheet, so nothing hides behind it.
/// Open it with [showAppSheet].
class AppSheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  const AppSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottomSafe = keyboard > 0 ? 0.0 : media.viewPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 2,
                    color: AppColors.accent.withValues(alpha: 0.6),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle!,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  footer == null ? 20 + bottomSafe : 16,
                ),
                child: child,
              ),
            ),
            if (footer != null)
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomSafe),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker (dropdown replacement)
// ─────────────────────────────────────────────────────────────────────────────

class AppPickerOption<T> {
  final T value;
  final String label;

  const AppPickerOption(this.value, this.label);
}

/// Closes the keyboard first (so nothing shifts), then shows a
/// bottom-anchored picker. Returns null when dismissed.
Future<T?> showAppPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppPickerOption<T>> options,
  T? selected,
  bool? searchable,
}) async {
  final keyboardWasOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
  FocusManager.instance.primaryFocus?.unfocus();
  if (keyboardWasOpen) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  if (!context.mounted) return null;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable ?? options.length > 7,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<AppPickerOption<T>> options;
  final T? selected;
  final bool searchable;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottomSafe = keyboard > 0 ? 0.0 : media.viewPadding.bottom;
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.label.toLowerCase().contains(_query))
            .toList();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Select ${widget.title}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                ),
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  decoration: appFieldDecoration(
                    'Search',
                    dense: true,
                    prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.clear, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'No matches',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: 8 + bottomSafe),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final isSelected = option.value == widget.selected;
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(
                            option.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.text,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: AppColors.accent)
                              : null,
                          onTap: () => Navigator.pop(context, option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppPickerField<T> extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final T? value;
  final List<AppPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? errorText;
  final bool enabled;
  final bool? searchable;

  const AppPickerField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.required = false,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.searchable,
  });

  @override
  Widget build(BuildContext context) {
    String? text;
    for (final o in options) {
      if (o.value == value) {
        text = o.label;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled
          ? () async {
              final picked = await showAppPicker<T>(
                context,
                title: label,
                options: options,
                selected: value,
                searchable: searchable,
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        isEmpty: text == null,
        decoration: appFieldDecoration(
          label,
          required: required,
          hint: hint,
          errorText: errorText,
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
        ),
        child: Text(
          text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? AppColors.text : AppColors.muted,
          ),
        ),
      ),
    );
  }
}