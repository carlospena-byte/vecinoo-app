import 'package:flutter/cupertino.dart';

import 'gates_palette.dart';

/// iOS push / swipe-back with the native slide and edge gesture, plus a soft
/// dim on the page being covered so the two screens read as layers instead
/// of competing for attention.
class GatesPageTransitionsBuilder extends PageTransitionsBuilder {
  const GatesPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final dim = context.palette.shadow;
    final base = CupertinoRouteTransitionMixin.buildPageTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        base,
        IgnorePointer(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOut,
            ),
            child: ColoredBox(color: dim),
          ),
        ),
      ],
    );
  }
}
