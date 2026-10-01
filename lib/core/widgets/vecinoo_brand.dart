import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// "vecinoo" wordmark, shared across the auth/onboarding screens (Figma
/// file `Bla1GPfXA7JkuZcYpVi2DS`, node `136:786`).
class VecinooWordmark extends StatelessWidget {
  const VecinooWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'vecinoo',
      style: GatesTypography.headingLarge.copyWith(
        color: context.palette.textBrand,
      ),
    );
  }
}

/// "Marca / símbolo sobre luz": two interlocking rings, the brand's symbol
/// on the auth/onboarding screens.
class VecinooMark extends StatelessWidget {
  const VecinooMark({super.key});

  static const _ringDiameter = 110.0;
  static const _ringWidth = 12.0;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 212,
      child: Stack(
        children: [
          Positioned(left: 81, top: 56, child: _Ring()),
          Positioned(left: 152.5, top: 56, child: _Ring()),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VecinooMark._ringDiameter,
      height: VecinooMark._ringDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.palette.textBrand,
          width: VecinooMark._ringWidth,
        ),
      ),
    );
  }
}

/// Warm radial glow behind every screen, matching the Figma "Ambient /
/// warm glow" decoration (`left:-145 top:55 680x610` on a 390pt frame, a
/// soft yellow wash at 50% opacity). Mounted once by [GatesBackground];
/// individual screens must not add their own.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned(
      top: 55,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: palette.glowOpacity,
            child: Container(
              width: 680,
              height: 610,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.glowStrong.withValues(alpha: 0.48),
                    palette.glowSoft.withValues(alpha: 0.2),
                    palette.glowSoft.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide canvas: the Figma background colour plus the ambient glow,
/// installed once via `MaterialApp.builder`. Scaffolds and app bars are
/// transparent so it shows through on every screen.
class GatesBackground extends StatelessWidget {
  const GatesBackground({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: context.palette.bgCanvas,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const AmbientGlow(),
            if (child != null) Positioned.fill(child: child!),
          ],
        ),
      ),
    );
  }
}
