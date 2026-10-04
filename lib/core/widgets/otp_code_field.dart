import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Figma "OTP / IFTA": a segmented code field rendered as independent boxes
/// (to avoid clipping and keep every character legible), backed by a single
/// invisible [TextField] so paste and SMS/email autofill still work.
///
/// Used both for numeric OTP codes (6 digits) and alphanumeric invitation
/// codes (8 uppercase characters, [alphanumeric]: true) — box width shrinks
/// automatically to fit whatever [length] is given.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.errorText,
    this.length = 6,
    this.alphanumeric = false,
    this.accentColor,
    this.autofillHints,
    this.onCompleted,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? errorText;
  final int length;
  final bool alphanumeric;

  /// Overrides the label/helper/idle-border color from the neutral
  /// default — e.g. the invitation-code field's coral accent. A real
  /// [errorText] still always wins.
  final Color? accentColor;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focusNode = FocusNode();
  late String _lastText = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _onChanged() {
    setState(() {});
    // The controller also notifies on caret moves (tapping a box), which
    // must not re-submit an already complete code.
    final text = widget.controller.text;
    final textChanged = text != _lastText;
    _lastText = text;
    if (textChanged && text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  /// Tapping a box moves the caret there: a filled box is selected so the
  /// next digit replaces it (and backspace clears it); an empty box puts
  /// the caret at the end of what's typed so far. Always re-shows the
  /// keyboard, since the field may already be focused with it dismissed.
  void _selectBox(int index) {
    final length = widget.controller.text.length;
    widget.controller.selection = index < length
        ? TextSelection(baseOffset: index, extentOffset: index + 1)
        : TextSelection.collapsed(offset: length);
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  /// The hidden field sits under [IgnorePointer], so the system paste menu
  /// can't appear; read the clipboard ourselves and apply the same filtering
  /// the keyboard path uses.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    var text = (data?.text ?? '').replaceAll(
      widget.alphanumeric ? RegExp('[^A-Za-z0-9]') : RegExp(r'\D'),
      '',
    );
    if (widget.alphanumeric) text = text.toUpperCase();
    if (text.length > widget.length) text = text.substring(0, widget.length);
    if (text.isEmpty || !mounted) return;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final code = widget.controller.text;
    final isFocused = _focusNode.hasFocus;
    final selection = widget.controller.selection;
    final activeIndex =
        (selection.isValid
                ? (selection.isCollapsed
                      ? selection.baseOffset
                      : selection.start)
                : code.length)
            .clamp(0, widget.length - 1);
    const gap = GatesSpacing.space8;

    final labelColor = hasError
        ? context.palette.statusError
        : (widget.accentColor ?? context.palette.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: context.gatesText.caption.copyWith(color: labelColor),
          ),
        ),
        const SizedBox(height: GatesSpacing.space8),
        SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth =
                  ((constraints.maxWidth - gap * (widget.length - 1)) /
                          widget.length)
                      .clamp(0, 48)
                      .toDouble();
              return Stack(
                children: [
                  // Invisible field underneath: captures the keyboard, paste and
                  // autofill, while the boxes above show the resulting characters.
                  // Hidden visually and for touch, but it is the one real
                  // control for screen readers (the boxes are decoration).
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      alwaysIncludeSemantics: true,
                      child: Semantics(
                        label: widget.label,
                        hint: context.l10n.commonCharactersCount(widget.length),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          keyboardType: widget.alphanumeric
                              ? TextInputType.visiblePassword
                              : TextInputType.number,
                          textCapitalization: widget.alphanumeric
                              ? TextCapitalization.characters
                              : TextCapitalization.none,
                          autofillHints: widget.autofillHints,
                          inputFormatters: [
                            widget.alphanumeric
                                ? FilteringTextInputFormatter.allow(
                                    RegExp('[A-Za-z0-9]'),
                                  )
                                : FilteringTextInputFormatter.digitsOnly,
                            if (widget.alphanumeric) _UpperCaseTextFormatter(),
                            LengthLimitingTextInputFormatter(widget.length),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _selectBox(widget.controller.text.length),
                        onLongPress: _paste,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < widget.length; i++)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _selectBox(i),
                            onLongPress: _paste,
                            child: _DigitBox(
                              digit: i < code.length ? code[i] : '',
                              focused: isFocused && i == activeIndex,
                              hasError: hasError,
                              idleBorderColor: widget.accentColor,
                              width: boxWidth,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if ((widget.errorText != null && widget.errorText!.isNotEmpty) ||
            (widget.helper != null && widget.helper!.isNotEmpty)) ...[
          const SizedBox(height: GatesSpacing.space8),
          Semantics(
            liveRegion: hasError,
            child: Text(
              hasError ? widget.errorText! : widget.helper!,
              style: context.gatesText.caption.copyWith(color: labelColor),
            ),
          ),
        ],
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.focused,
    required this.hasError,
    required this.width,
    this.idleBorderColor,
  });

  final String digit;
  final bool focused;
  final bool hasError;
  final double width;
  final Color? idleBorderColor;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth;
    if (hasError) {
      borderColor = context.palette.statusError;
      borderWidth = focused ? 2 : 1;
    } else if (focused) {
      borderColor = context.palette.borderFocus;
      borderWidth = 2;
    } else {
      borderColor = idleBorderColor ?? context.palette.borderDefault;
      borderWidth = 1;
    }

    return Container(
      width: width,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(digit, style: GatesTypography.headingSmall),
    );
  }
}
