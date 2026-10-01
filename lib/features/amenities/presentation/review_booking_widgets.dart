import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'amenities_controller.dart';

class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GatesTypography.label),
              const SizedBox(height: 4),
              Text(value, style: GatesTypography.body),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class ReviewDivider extends StatelessWidget {
  const ReviewDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GatesSpacing.space16),
      child: Divider(height: 1, color: context.palette.borderSubtle),
    );
  }
}

class ReviewErrorBanner extends StatelessWidget {
  const ReviewErrorBanner({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: context.palette.statusErrorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GatesTypography.label.copyWith(
              color: context.palette.statusError,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: context.gatesText.caption.copyWith(
              color: context.palette.statusError,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewAmenityThumbnail extends ConsumerWidget {
  const ReviewAmenityThumbnail({super.key, required this.amenityId});

  final String amenityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlsAsync = ref.watch(amenityImageUrlsProvider(amenityId));
    final url = urlsAsync.value?.values.firstOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: url != null
            ? Image.network(url, fit: BoxFit.cover, excludeFromSemantics: true)
            : Container(
                color: context.palette.bgSubtle,
                alignment: Alignment.center,
                child: Icon(
                  TablerIcons.buildingCommunity,
                  color: context.palette.textSecondary,
                ),
              ),
      ),
    );
  }
}
