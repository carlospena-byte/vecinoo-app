import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GatesButtonStyle { primary, secondary }

class GatesButton extends StatelessWidget {
  const GatesButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GatesButtonStyle.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GatesButtonStyle style;
  final bool loading;

  bool get _isPrimary => style == GatesButtonStyle.primary;

  @override
  Widget build(BuildContext context) {
    final interactionDisabled = onPressed == null || loading;
    final disabled = onPressed == null;
    final foreground = _isPrimary
        ? GatesColors.textInverse
        : GatesColors.textBrand;

    final background = WidgetStateProperty.resolveWith<Color>((states) {
      if (disabled) return GatesColors.bgSubtle;
      if (_isPrimary) {
        if (states.contains(WidgetState.pressed)) return GatesColors.bgPressed;
        return GatesColors.bgBrand;
      }
      if (states.contains(WidgetState.pressed)) return GatesColors.bgAccent;
      return GatesColors.bgSurface;
    });

    final side = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (_isPrimary) return null;
      if (disabled) return const BorderSide(color: GatesColors.bgSubtle);
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: GatesColors.borderFocus, width: 2);
      }
      return const BorderSide(color: GatesColors.borderDefault);
    });

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: interactionDisabled ? null : onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: background,
          foregroundColor: WidgetStatePropertyAll(
            disabled ? GatesColors.textSecondary : foreground,
          ),
          side: side,
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(GatesRadius.radiusFull),
              ),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: GatesSpacing.space16),
          ),
          textStyle: WidgetStatePropertyAll(GatesTypography.label),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    disabled ? GatesColors.textSecondary : foreground,
                  ),
                ),
              )
            : Text(label),
      ),
    );
  }
}
