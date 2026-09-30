import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A "slide to confirm" track for a destructive action that shouldn't be a
/// single accidental tap away — replaces stacking a confirm AlertDialog on
/// top of an already-open bottom sheet (a "double modal") with one inline
/// gesture inside the sheet itself.
///
/// Dragging the thumb past [confirmThreshold] of the track's width fires
/// [onConfirmed] and locks the thumb at the end; releasing short of that
/// snaps it back to the start.
class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.loading = false,
    this.confirmThreshold = 1.0,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool loading;
  final double confirmThreshold;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  static const _thumbSize = 48.0;
  static const _trackHeight = 56.0;
  static const _edgePadding = 4.0;

  double _dragExtent = 0;
  bool _isDragging = false;
  bool _confirmed = false;

  @override
  void didUpdateWidget(SwipeToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent stopped loading without the sheet closing (e.g. the
    // cancellation failed) — give the thumb back to the user instead of
    // leaving it stranded at the end of the track.
    if (oldWidget.loading && !widget.loading && _confirmed) {
      setState(() {
        _confirmed = false;
        _dragExtent = 0;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_confirmed || widget.loading) return;
    setState(() => _isDragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxExtent) {
    if (_confirmed || widget.loading) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(0.0, maxExtent);
    });
  }

  void _handleDragEnd(double maxExtent) {
    if (_confirmed || widget.loading) return;
    final progress = maxExtent == 0 ? 0.0 : _dragExtent / maxExtent;
    final reachedThreshold = progress >= widget.confirmThreshold;
    setState(() {
      _isDragging = false;
      _dragExtent = reachedThreshold ? maxExtent : 0;
      _confirmed = reachedThreshold;
    });
    if (reachedThreshold) widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = (constraints.maxWidth - _thumbSize - _edgePadding * 2)
            .clamp(0.0, double.infinity);
        final progress = maxExtent == 0
            ? 0.0
            : (_dragExtent / maxExtent).clamp(0.0, 1.0);

        // Neutral until the user actually starts dragging, then eases into
        // the destructive red — so the track doesn't read as an alarming
        // "danger zone" the moment the sheet opens, only once it's really
        // about to fire.
        final trackColor = Color.lerp(
          GatesColors.bgSubtle,
          GatesColors.statusError.withValues(alpha: 0.1),
          progress,
        )!;
        final borderColor = Color.lerp(
          GatesColors.borderDefault,
          GatesColors.statusError.withValues(alpha: 0.3),
          progress,
        )!;
        final thumbColor = Color.lerp(
          GatesColors.textSecondary,
          GatesColors.statusError,
          progress,
        )!;
        final labelColor = Color.lerp(
          GatesColors.textSecondary,
          GatesColors.statusError,
          progress,
        )!;

        return Container(
          width: double.infinity,
          height: _trackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - progress,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: _thumbSize),
                      child: Text(
                        widget.label,
                        style: GatesTypography.label.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: _edgePadding + _dragExtent,
                child: GestureDetector(
                  onHorizontalDragStart: _handleDragStart,
                  onHorizontalDragUpdate: (details) =>
                      _handleDragUpdate(details, maxExtent),
                  onHorizontalDragEnd: (_) => _handleDragEnd(maxExtent),
                  onHorizontalDragCancel: () => _handleDragEnd(maxExtent),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                    ),
                    child: widget.loading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GatesColors.textInverse,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: GatesColors.textInverse,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
