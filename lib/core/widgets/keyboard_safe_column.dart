import 'package:flutter/material.dart';

/// A [Column] that fills the viewport (so an `Expanded` spacer can push
/// content to the bottom, matching Figma's "fixed bottom" action areas)
/// but becomes scrollable instead of overflowing once the keyboard — or
/// just a small device — leaves less room than the content needs.
class KeyboardSafeColumn extends StatelessWidget {
  const KeyboardSafeColumn({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The padding has to live *inside* the min-height box, not around
        // it via SingleChildScrollView's own `padding` — otherwise it adds
        // on top of a box already sized to the full viewport, guaranteeing
        // an overflow (and a forced scroll) by exactly that padding amount
        // even when the content would otherwise fit on screen.
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
