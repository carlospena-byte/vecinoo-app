import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool _keyboardOpen(BuildContext context) =>
    MediaQuery.viewInsetsOf(context).bottom > 0;

/// Figma "Acción fija": white bar pinned above the system inset holding the
/// primary button. Hides itself while the keyboard is open so the form gets
/// the whole viewport; pair it with a [GatesInlineAction] at the end of the
/// scrollable content so the button stays reachable by scrolling.
class GatesFixedAction extends StatelessWidget {
  const GatesFixedAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_keyboardOpen(context)) return const SizedBox.shrink();
    return Container(
      color: context.palette.bgSurface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: GatesSpacing.space24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space12,
            GatesSpacing.space24,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The same primary action rendered as the last item of the scrollable
/// content, only while the keyboard is open (when [GatesFixedAction] is hidden).
class GatesInlineAction extends StatelessWidget {
  const GatesInlineAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_keyboardOpen(context)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: GatesSpacing.space16),
      child: child,
    );
  }
}
