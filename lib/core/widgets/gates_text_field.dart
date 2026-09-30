import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Figma "Field / IFTA": label and value both sit inside a bordered box
/// (label pinned above the value, never floating across the border line
/// the way Material's OutlineInputBorder + always-floating label does).
///
/// Built on [FormField] directly (rather than [TextFormField]) so the
/// container border and label color can react to validation errors —
/// [FormFieldState.hasError] isn't otherwise exposed to a wrapper widget.
class GatesTextField extends StatefulWidget {
  const GatesTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.obscureText = false,
    this.onChanged,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.autofocus = false,
  });

  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  @override
  State<GatesTextField> createState() => _GatesTextFieldState();
}

class _GatesTextFieldState extends State<GatesTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final hasError =
            widget.errorText != null && widget.errorText!.isNotEmpty ||
            field.hasError;
        final errorMessage =
            (widget.errorText != null && widget.errorText!.isNotEmpty)
            ? widget.errorText
            : field.errorText;
        final isFocused = _focusNode.hasFocus;
        final labelColor = hasError
            ? GatesColors.statusError
            : GatesColors.textSecondary;

        Color borderColor;
        double borderWidth;
        if (!widget.enabled) {
          borderColor = GatesColors.borderDefault;
          borderWidth = 1;
        } else if (hasError) {
          borderColor = GatesColors.statusError;
          borderWidth = isFocused ? 2 : 1;
        } else if (isFocused) {
          borderColor = GatesColors.borderFocus;
          borderWidth = 2;
        } else {
          borderColor = GatesColors.borderDefault;
          borderWidth = 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? GatesColors.bgSurface
                    : GatesColors.bgSubtle,
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: GatesSpacing.space16,
                vertical: GatesSpacing.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: GatesTypography.caption.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  TextField(
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    textCapitalization: widget.textCapitalization,
                    enabled: widget.enabled,
                    obscureText: widget.obscureText,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    autofillHints: widget.autofillHints,
                    onChanged: (value) {
                      field.didChange(value);
                      widget.onChanged?.call(value);
                    },
                    style: GatesTypography.body.copyWith(
                      color: widget.enabled
                          ? GatesColors.textPrimary
                          : GatesColors.textSecondary,
                    ),
                    cursorColor: GatesColors.borderFocus,
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: GatesTypography.body.copyWith(
                        color: GatesColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if ((errorMessage != null && errorMessage.isNotEmpty) ||
                (widget.helperText != null &&
                    widget.helperText!.isNotEmpty)) ...[
              const SizedBox(height: GatesSpacing.space4),
              Text(
                hasError ? errorMessage! : widget.helperText!,
                style: GatesTypography.caption.copyWith(
                  color: hasError
                      ? GatesColors.statusError
                      : GatesColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
