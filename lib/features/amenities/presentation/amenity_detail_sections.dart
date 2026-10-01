import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import '../domain/amenity_details.dart';
import '../domain/service.dart';
import 'amenity_bottom_sheets.dart';
import 'amenity_formatters.dart';
import 'service_icons.dart';

final amenityCurrencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
);

TextStyle amenityBodySecondary(BuildContext context) =>
    GatesTypography.body.copyWith(color: context.palette.textSecondary);

/// A hairline divider with the vertical rhythm the design uses between
/// stacked sections (24px gaps, the divider itself sitting in the middle).
class AmenitySectionDivider extends StatelessWidget {
  const AmenitySectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GatesSpacing.space12),
      child: Divider(height: 1, color: context.palette.borderSubtle),
    );
  }
}

class AmenitySectionHeading extends StatelessWidget {
  const AmenitySectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GatesSpacing.space16),
      child: Text(text, style: GatesTypography.headingSmall),
    );
  }
}

class AmenityIdentity extends StatelessWidget {
  const AmenityIdentity({super.key, required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final metaParts = [
      if (amenity.capacity != null)
        context.l10n.amenitiesCapacity(amenity.capacity!),
      amenity.requiresBooking
          ? context.l10n.amenitiesBookingRequired
          : context.l10n.amenitiesFreeAccess,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(amenity.name, style: GatesTypography.headingLarge),
        if (amenity.location != null) ...[
          const SizedBox(height: GatesSpacing.space8),
          Text(amenity.location!, style: amenityBodySecondary(context)),
        ],
        const SizedBox(height: GatesSpacing.space4),
        Text(metaParts, style: context.gatesText.labelSecondary),
      ],
    );
  }
}

class AmenityFeaturedServices extends StatelessWidget {
  const AmenityFeaturedServices({super.key, required this.services});

  final List<AmenityService> services;

  @override
  Widget build(BuildContext context) {
    final featured = services.where((s) => s.isFeatured).toList();
    final visible = featured.isEmpty ? services : featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmenitySectionHeading(context.l10n.amenitiesOffersHeading),
        for (final entry in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: GatesSpacing.space16),
            child: Row(
              children: [
                Icon(
                  serviceIconFor(entry.service.icon),
                  size: 24,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(width: GatesSpacing.space16),
                Expanded(
                  child: Text(entry.service.name, style: GatesTypography.body),
                ),
              ],
            ),
          ),
        if (services.length > visible.length)
          SizedBox(
            width: double.infinity,
            child: GatesButton(
              label: context.l10n.amenitiesViewAllServices,
              style: GatesButtonStyle.secondary,
              onPressed: () => _showAllServicesSheet(context, services),
            ),
          ),
      ],
    );
  }

  void _showAllServicesSheet(
    BuildContext context,
    List<AmenityService> services,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GatesRadius.radius24),
        ),
      ),
      builder: (context) => _AllServicesSheet(services: services),
    );
  }
}

class _AllServicesSheet extends StatelessWidget {
  const _AllServicesSheet({required this.services});

  final List<AmenityService> services;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.amenitiesAllServices,
                  style: GatesTypography.headingSmall,
                ),
                IconButton(
                  tooltip: context.l10n.amenitiesClose,
                  icon: const Icon(TablerIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index].service;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      serviceIconFor(service.icon),
                      color: context.palette.textSecondary,
                    ),
                    title: Text(service.name, style: GatesTypography.body),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmenityDescription extends StatelessWidget {
  const AmenityDescription({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmenitySectionHeading(context.l10n.amenitiesAboutHeading),
        Html(
          data: html,
          style: {
            'body': Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              fontFamily: 'Manrope',
              fontSize: FontSize(16),
              color: context.palette.textPrimary,
            ),
            'a': Style(color: context.palette.textBrand),
          },
        ),
      ],
    );
  }
}

class AmenitySchedule extends StatelessWidget {
  const AmenitySchedule({super.key, required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmenitySectionHeading(context.l10n.amenitiesScheduleHeading),
        for (final block in amenity.effectiveSchedule)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              amenityScheduleBlockLabel(context.l10n, block),
              style: GatesTypography.body,
            ),
          ),
      ],
    );
  }
}

class AmenityBookingRules extends StatelessWidget {
  const AmenityBookingRules({super.key, required this.details});

  final AmenityDetails details;

  @override
  Widget build(BuildContext context) {
    final amenity = details.amenity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmenitySectionHeading(context.l10n.amenitiesBeforeBookingHeading),
        if (amenity.bookingDurationMinutes != null) ...[
          Text(
            context.l10n.amenitiesDurationPerBooking,
            style: GatesTypography.label,
          ),
          const SizedBox(height: 4),
          Text(
            amenityDurationLabel(context.l10n, amenity.bookingDurationMinutes!),
            style: amenityBodySecondary(context),
          ),
          const SizedBox(height: GatesSpacing.space16),
        ],
        if (details.bookingLimits.isNotEmpty) ...[
          Text(
            context.l10n.amenitiesLimitPerResident,
            style: GatesTypography.label,
          ),
          const SizedBox(height: 4),
          for (final limit in details.bookingLimits)
            Text(
              amenityBookingLimitLabel(context.l10n, limit),
              style: amenityBodySecondary(context),
            ),
          const SizedBox(height: GatesSpacing.space16),
        ],
        if (details.blackouts.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GatesSpacing.space16),
            decoration: BoxDecoration(
              color: context.palette.statusWarningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.amenitiesClosedDates,
                  style: GatesTypography.label.copyWith(
                    color: context.palette.statusWarning,
                  ),
                ),
                const SizedBox(height: GatesSpacing.space8),
                for (final blackout in details.blackouts)
                  Text(
                    amenityBlackoutLabel(context.l10n, blackout),
                    style: context.gatesText.labelSecondary.copyWith(
                      color: context.palette.statusWarning,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class AmenityCost extends StatelessWidget {
  const AmenityCost({super.key, required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final hasCost = amenity.requiresPayment && amenity.price != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmenitySectionHeading(context.l10n.amenitiesCostHeading),
        Text(
          hasCost
              ? amenityCurrencyFormat.format(amenity.price)
              : context.l10n.amenitiesNoCost,
          style: GatesTypography.headingMedium,
        ),
        if (hasCost && amenity.bookingDurationMinutes != null) ...[
          const SizedBox(height: GatesSpacing.space8),
          Text(
            context.l10n.amenitiesPerBookingOf(
              amenityDurationLabel(
                context.l10n,
                amenity.bookingDurationMinutes!,
              ),
            ),
            style: context.gatesText.labelSecondary,
          ),
        ],
        if (hasCost && amenity.paymentMethods.isNotEmpty) ...[
          const SizedBox(height: GatesSpacing.space16),
          Text(
            context.l10n.amenitiesAcceptedMethods,
            style: GatesTypography.label,
          ),
          const SizedBox(height: 4),
          Text(
            amenity.paymentMethods
                .map((m) => amenityPaymentMethodLabel(context.l10n, m))
                .join(' · '),
            style: context.gatesText.labelSecondary,
          ),
        ],
      ],
    );
  }
}

class AmenityTermsButton extends StatelessWidget {
  const AmenityTermsButton({super.key, required this.terms});

  final String terms;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GatesButton(
        label: context.l10n.amenitiesTerms,
        style: GatesButtonStyle.secondary,
        onPressed: () => showTermsSheet(context, terms),
      ),
    );
  }
}
