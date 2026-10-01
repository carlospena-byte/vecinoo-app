import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import '../domain/amenity_details.dart';
import 'amenity_detail_controller.dart';
import 'amenity_detail_sections.dart';
import 'amenity_formatters.dart';
import 'booking_date_time_sheet.dart';

/// The detail screen's fixed CTA: price/duration summary plus the button
/// that opens the booking date/time sheet.
class AmenityActionBar extends ConsumerWidget {
  const AmenityActionBar({super.key, required this.details});

  final AmenityDetails details;

  Amenity get amenity => details.amenity;

  Future<void> _pickDateTime(BuildContext context, WidgetRef ref) async {
    final selection = await showBookingDateTimeSheet(
      context,
      amenity: amenity,
      blackouts: details.blackouts,
    );
    if (selection == null || !context.mounted) return;
    ref
        .read(amenityDetailControllerProvider(amenity.id).notifier)
        .continueToReview(details, selection);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceLabel = amenity.requiresPayment && amenity.price != null
        ? amenityCurrencyFormat.format(amenity.price)
        : context.l10n.amenitiesNoCost;
    final durationLabel = amenity.bookingDurationMinutes != null
        ? context.l10n.amenitiesPerBookingDuration(
            amenityDurationLabel(context.l10n, amenity.bookingDurationMinutes!),
          )
        : context.l10n.amenitiesPerBooking;

    // The design's own 24px bottom padding already reads as "clear of the
    // home indicator" on non-notched devices; on devices with a real inset
    // (the home indicator itself) that inset already provides ≥24px, so we
    // take whichever is larger instead of stacking both — otherwise the row
    // ends up sitting far closer to the top padding (12px) than the bottom.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = math.max(GatesSpacing.space24, bottomInset);

    return Container(
      padding: EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        GatesSpacing.space12,
        GatesSpacing.space24,
        bottomPadding,
      ),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border(top: BorderSide(color: context.palette.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(priceLabel, style: GatesTypography.headingSmall),
                Text(durationLabel, style: context.gatesText.caption),
              ],
            ),
          ),
          const SizedBox(width: GatesSpacing.space12),
          SizedBox(
            width: 176,
            child: GatesButton(
              label: context.l10n.amenitiesPickDate,
              onPressed: () => _pickDateTime(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
