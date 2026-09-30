import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma "Switch": an 88px tappable row with a label, description and a
/// toggle whose state is also shown by a symbol (✓ on, − off), not color alone.
class GatesSwitchRow extends StatelessWidget {
  const GatesSwitchRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final String label;
  final String? description;

  /// Inline variant for filters: no card, no fixed 88px height.
  final bool compact;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        toggled: value,
        label: label,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Expanded(child: Text(label, style: GatesTypography.label)),
                const SizedBox(width: GatesSpacing.space16),
                _Track(value: value),
              ],
            ),
          ),
        ),
      );
    }
    return Semantics(
      toggled: value,
      label: label,
      child: Material(
        color: GatesColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
          side: const BorderSide(color: GatesColors.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(GatesSpacing.space16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: GatesTypography.label),
                      if (description != null) ...[
                        const SizedBox(height: GatesSpacing.space4),
                        Text(description!, style: GatesTypography.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: GatesSpacing.space16),
                _Track(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(GatesSpacing.space4),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? GatesColors.bgBrand : GatesColors.bgSubtle,
        border: Border.all(
          color: value ? GatesColors.bgBrand : GatesColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: GatesColors.bgSurface,
          shape: BoxShape.circle,
        ),
        child: Text(
          value ? '✓' : '−',
          style: GatesTypography.caption.copyWith(
            color: GatesColors.textBrand,
            height: 1,
          ),
        ),
      ),
    );
  }
}
