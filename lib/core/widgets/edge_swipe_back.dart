import 'package:flutter/material.dart';

/// Restores the iOS edge swipe-back when a [PopScope] has `canPop: false`
/// (which disables the native gesture). While [enabled], a right-swipe that
/// starts at the left edge calls [onBack].
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    required this.enabled,
    required this.onBack,
    required this.child,
    super.key,
  });

  final bool enabled;
  final VoidCallback onBack;
  final Widget child;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  static const _edgeWidth = 24.0;
  static const _triggerDistance = 60.0;

  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dx = 0,
            onHorizontalDragUpdate: (d) =>
                _dx += isRtl ? -d.delta.dx : d.delta.dx,
            onHorizontalDragEnd: (_) {
              if (_dx >= _triggerDistance) widget.onBack();
              _dx = 0;
            },
          ),
        ),
      ],
    );
  }
}
