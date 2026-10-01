import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Field / IFTA"-style read-only row that opens a picker or sheet on tap
/// (date, time, catalog choice...): label above the value, optional helper
/// below, and a trailing icon.
class GatesTapField extends StatelessWidget {
  const GatesTapField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? helper;
  final IconData? icon;

  /// Defaults to `palette.textBrand`.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(GatesRadius.radius16),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: GatesSpacing.space16,
                vertical: GatesSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: context.palette.bgSurface,
                border: Border.all(color: context.palette.borderDefault),
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: context.gatesText.caption),
                        const SizedBox(height: GatesSpacing.space4),
                        Text(value, style: GatesTypography.body),
                      ],
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? context.palette.textBrand,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: GatesSpacing.space4),
          Text(helper!, style: context.gatesText.caption),
        ],
      ],
    );
  }
}
