import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GatesButtonStyle { primary, secondary, destructive }

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
  bool get _isSecondary => style == GatesButtonStyle.secondary;

  @override
  Widget build(BuildContext context) {
    final interactionDisabled = onPressed == null || loading;
    final disabled = onPressed == null;
    final foreground = switch (style) {
      GatesButtonStyle.primary => context.palette.textOnBrand,
      GatesButtonStyle.secondary => context.palette.textBrand,
      GatesButtonStyle.destructive => context.palette.textOnDanger,
    };

    final background = WidgetStateProperty.resolveWith<Color>((states) {
      if (disabled) return context.palette.bgSubtle;
      if (_isPrimary) {
        if (states.contains(WidgetState.pressed)) {
          return context.palette.bgPressed;
        }
        return context.palette.bgBrand;
      }
      if (style == GatesButtonStyle.destructive) {
        return context.palette.bgDanger;
      }
      if (states.contains(WidgetState.pressed)) return context.palette.bgAccent;
      return context.palette.bgSurface;
    });

    final side = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (!_isSecondary) return null;
      if (disabled) return BorderSide(color: context.palette.bgSubtle);
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: context.palette.borderFocus, width: 2);
      }
      return BorderSide(color: context.palette.borderDefault);
    });

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: interactionDisabled ? null : onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: background,
          foregroundColor: WidgetStatePropertyAll(
            disabled ? context.palette.textSecondary : foreground,
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
                    disabled ? context.palette.textSecondary : foreground,
                  ),
                ),
              )
            : Text(label),
      ),
    );
  }
}
