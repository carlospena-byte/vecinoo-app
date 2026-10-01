import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Single-colour line icon from `assets/icons`, tinted with a palette token
/// so it follows the theme instead of the colour baked into the SVG.
class GatesSvgIcon extends StatelessWidget {
  const GatesSvgIcon(this.asset, {super.key, required this.size, this.color});

  final String asset;
  final double size;

  /// Defaults to `palette.iconDefault`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? context.palette.iconDefault,
        BlendMode.srcIn,
      ),
    );
  }
}
