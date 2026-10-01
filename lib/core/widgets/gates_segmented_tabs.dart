import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One option in a [GatesSegmentedTabs] bar.
class GatesSegmentedTabOption<T> {
  const GatesSegmentedTabOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill-shaped segmented tab bar — the standard way to switch between a
/// small, fixed set of views (visit kind, booking status...). Previously
/// reimplemented per screen with drifting styles; this is the single
/// source of truth, styled after "Tabs / Visitas" (Figma node `337:1682`).
class GatesSegmentedTabs<T> extends StatelessWidget {
  const GatesSegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<GatesSegmentedTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      // 6pt top/bottom keeps each pill at the 44pt minimum touch target.
      padding: const EdgeInsets.symmetric(
        horizontal: GatesSpacing.space8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.palette.bgSubtle,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: GatesSpacing.space4),
              Expanded(
                child: _GatesTabPill(
                  label: options[i].label,
                  selected: options[i].value == selected,
                  onTap: () => onSelect(options[i].value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GatesTabPill extends StatelessWidget {
  const _GatesTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? context.palette.bgBrand : Colors.transparent,
        // Outline marks the selection without relying on the fill alone.
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? context.palette.borderSelectedBrand
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: GatesSpacing.space8,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GatesTypography.label.copyWith(
                  color: selected
                      ? context.palette.textOnBrand
                      : context.palette.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
