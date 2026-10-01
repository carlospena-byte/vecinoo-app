import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gates_sheet.dart';

/// Figma "Dropdown / IFTA": a Field/IFTA look-alike that shows the current
/// value with a chevron and opens [showGatesOptionSheet] on tap, instead of
/// Material's [DropdownButton] popup.
class GatesSelectField<T> extends StatelessWidget {
  const GatesSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
  });

  final String label;
  final T value;

  /// Value -> the text shown for it, in menu order.
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// Shown in secondary color while [value] has no entry in [options].
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        side: BorderSide(color: context.palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final picked = await showGatesOptionSheet<T>(
            context,
            title: label,
            options: options,
            selected: value,
          );
          if (picked != null) onChanged(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GatesSpacing.space16,
            vertical: GatesSpacing.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: context.gatesText.caption),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      options[value] ?? placeholder ?? '',
                      style: options[value] == null && placeholder != null
                          ? GatesTypography.body.copyWith(
                              color: context.palette.textSecondary,
                            )
                          : GatesTypography.body,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: context.palette.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing [options] with a check next to [selected]; resolves
/// to the tapped value, or null if dismissed.
Future<T?> showGatesOptionSheet<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  required T selected,
}) {
  return showGatesSheet<T>(
    context,
    (sheetContext) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
          .copyWith(bottom: GatesSpacing.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GatesSheetHeader(title: title),
          const SizedBox(height: GatesSpacing.space8),
          for (final entry in options.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value, style: GatesTypography.body),
              trailing: entry.key == selected
                  ? Icon(Icons.check, color: context.palette.textBrand)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(entry.key),
            ),
        ],
      ),
    ),
  );
}
