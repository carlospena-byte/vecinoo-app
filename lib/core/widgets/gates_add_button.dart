import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round "+" button in the header of the tab list screens (Visitas,
/// Reservas) that starts creating a new item.
class GatesAddButton extends StatelessWidget {
  const GatesAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgBrand,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add, color: context.palette.textOnBrand, size: 24),
        ),
      ),
    );
  }
}
