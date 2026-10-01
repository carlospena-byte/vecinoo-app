import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The rounded, safe-area-aware modal bottom sheet shell shared by every
/// Gates bottom sheet — see amenity_bottom_sheets.dart for why `useSafeArea`
/// matters here (default `showModalBottomSheet` strips the top inset).
Future<T?> showGatesSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.palette.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: builder,
  );
}

/// The title + close button row every Gates bottom sheet opens with.
class GatesSheetHeader extends StatelessWidget {
  const GatesSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GatesTypography.headingSmall),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
