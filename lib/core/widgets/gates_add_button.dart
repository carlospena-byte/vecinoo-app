import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../theme/app_theme.dart';

/// Round "+" button in the header of the tab list screens (Visitas,
/// Reservas) that starts creating a new item.
class GatesAddButton extends StatelessWidget {
  const GatesAddButton({
    super.key,
    required this.onTap,
    required this.semanticLabel,
  });

  final VoidCallback onTap;

  /// What the button creates, read by screen readers ("Nueva visita").
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: context.palette.bgBrand,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              TablerIcons.plus,
              color: context.palette.textOnBrand,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
