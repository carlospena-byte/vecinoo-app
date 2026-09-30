import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 44px pill action for a screen's quieter buttons: text only, or [filled]
/// on a white pill. Used by the visit detail screens (FastLane and frequent).
class GatesTextAction extends StatelessWidget {
  const GatesTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: filled ? GatesColors.bgSurface : Colors.transparent,
          foregroundColor: color ?? GatesColors.textBrand,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(GatesRadius.radiusFull),
            ),
          ),
          textStyle: GatesTypography.label,
        ),
        child: Text(label),
      ),
    );
  }
}
