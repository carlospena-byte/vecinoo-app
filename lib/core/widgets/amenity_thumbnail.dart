import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The square, rounded amenity photo used across booking cards and lists —
/// a placeholder tile when there's no signed URL yet (or it fails to load).
class AmenityThumbnail extends StatelessWidget {
  const AmenityThumbnail({super.key, required this.imageUrl, this.size = 80});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Decorative: the amenity name is always shown next to it.
    return ExcludeSemantics(child: _buildTile(context));
  }

  Widget _buildTile(BuildContext context) {
    final radius = BorderRadius.circular(GatesRadius.radius8);
    if (imageUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.palette.bgSubtle,
          borderRadius: radius,
        ),
        child: Icon(Icons.image_outlined, color: context.palette.textSecondary),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: context.palette.bgSubtle,
          child: Icon(
            Icons.image_outlined,
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
