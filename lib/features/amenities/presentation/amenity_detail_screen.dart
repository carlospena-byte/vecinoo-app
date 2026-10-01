import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';
import '../domain/amenity_details.dart';
import '../domain/service.dart';
import 'amenities_controller.dart';
import 'amenity_bottom_sheets.dart';
import 'booking_date_time_sheet.dart';
import 'review_booking_screen.dart';
import 'service_icons.dart';

final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$');

TextStyle _bodySecondary(BuildContext context) =>
    GatesTypography.body.copyWith(color: context.palette.textSecondary);

String _durationLabel(int minutes) {
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hora' : '$hours horas';
  }
  return '$minutes minutos';
}

String _blackoutLabel(AmenityBlackout blackout) {
  final formatter = DateFormat('d MMM', 'es');
  final range = isSameDay(blackout.startDate, blackout.endDate)
      ? formatter.format(blackout.startDate)
      : '${formatter.format(blackout.startDate)} – ${formatter.format(blackout.endDate)}';
  return blackout.reason == null || blackout.reason!.isEmpty
      ? range
      : '$range · ${blackout.reason}';
}

/// The amenity's extended detail screen — gallery, identity, services,
/// description, schedule, booking rules and cost — with a fixed CTA that
/// opens the booking calendar. Figma: "A01 · Ficha completa / contenido
/// extendido" (node 248:1399).
class AmenityDetailScreen extends ConsumerWidget {
  const AmenityDetailScreen({super.key, required this.amenityId});

  final String amenityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(amenityDetailsProvider(amenityId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: detailsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudo cargar la amenidad.',
          onRetry: () => ref.invalidate(amenityDetailsProvider(amenityId)),
        ),
        data: (details) => _AmenityDetailContent(details: details),
      ),
    );
  }
}

class _AmenityDetailContent extends ConsumerWidget {
  const _AmenityDetailContent({required this.details});

  final AmenityDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenity = details.amenity;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GatesSpacing.space24,
              GatesSpacing.space16,
              GatesSpacing.space24,
              0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                Text('Amenidad', style: GatesTypography.headingSmall),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Gallery(
                  amenityId: amenity.id,
                  imageCount: details.images.length,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GatesSpacing.space24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: GatesSpacing.space24),
                      _Identity(amenity: amenity),
                      const _Section(),
                      if (details.services.isNotEmpty) ...[
                        _FeaturedServices(services: details.services),
                        const _Section(),
                      ],
                      if (amenity.description != null) ...[
                        _Description(html: amenity.description!),
                        const _Section(),
                      ],
                      if (amenity.effectiveSchedule.isNotEmpty) ...[
                        _Schedule(amenity: amenity),
                        const _Section(),
                      ],
                      if (amenity.requiresBooking) ...[
                        _BookingRules(details: details),
                        const _Section(),
                      ],
                      // Cost is about the booking, so free-access amenities
                      // skip it (the section above already ended in a divider).
                      if (amenity.requiresBooking) _Cost(amenity: amenity),
                      if (amenity.terms != null) ...[
                        if (amenity.requiresBooking) const _Section(),
                        _TermsButton(terms: amenity.terms!),
                      ],
                      const SizedBox(height: GatesSpacing.space24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (amenity.requiresBooking) _FixedActionBar(details: details),
        ],
      ),
    );
  }
}

/// A hairline divider with the vertical rhythm the design uses between
/// stacked sections (24px gaps, the divider itself sitting in the middle).
class _Section extends StatelessWidget {
  const _Section();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GatesSpacing.space12),
      child: Divider(height: 1, color: context.palette.borderSubtle),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GatesSpacing.space16),
      child: Text(text, style: GatesTypography.headingSmall),
    );
  }
}

class _Gallery extends ConsumerStatefulWidget {
  const _Gallery({required this.amenityId, required this.imageCount});

  final String amenityId;
  final int imageCount;

  @override
  ConsumerState<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<_Gallery> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageCount == 0) return const _GalleryPlaceholder();

    final urlsAsync = ref.watch(amenityImageUrlsProvider(widget.amenityId));
    return urlsAsync.when(
      loading: () => const SizedBox(height: 260, child: LoadingView()),
      error: (e, _) =>
          const _GalleryPlaceholder(icon: Icons.broken_image_outlined),
      data: (urls) {
        final details = ref
            .watch(amenityDetailsProvider(widget.amenityId))
            .value;
        final images = details?.images ?? const [];
        final photoUrls = images
            .map((image) => urls[image.storagePath])
            .whereType<String>()
            .toList();
        if (photoUrls.isEmpty) return const _GalleryPlaceholder();

        return SizedBox(
          height: 260,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: photoUrls.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _openViewer(context, photoUrls, index),
                  child: Image.network(
                    photoUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const LoadingView(),
                  ),
                ),
              ),
              if (photoUrls.length > 1)
                Positioned(
                  right: GatesSpacing.space24,
                  bottom: 20,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: GatesSpacing.space16,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.bgSurface,
                      borderRadius: BorderRadius.circular(
                        GatesRadius.radiusFull,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_page + 1} / ${photoUrls.length}',
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textBrand,
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

  void _openViewer(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _PhotoViewer(photoUrls: photoUrls, initialIndex: initialIndex),
      ),
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder({this.icon = Icons.deck_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: context.palette.bgSubtle,
      alignment: Alignment.center,
      child: Icon(icon, size: 48, color: context.palette.textSecondary),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.photoUrls, required this.initialIndex});

  final List<String> photoUrls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) => InteractiveViewer(
          child: Center(
            child: Image.network(photoUrls[index], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final metaParts = [
      if (amenity.capacity != null) '${amenity.capacity} personas',
      amenity.requiresBooking ? 'Reservación necesaria' : 'Acceso libre',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(amenity.name, style: GatesTypography.headingLarge),
        if (amenity.location != null) ...[
          const SizedBox(height: GatesSpacing.space8),
          Text(amenity.location!, style: _bodySecondary(context)),
        ],
        const SizedBox(height: GatesSpacing.space4),
        Text(metaParts, style: context.gatesText.labelSecondary),
      ],
    );
  }
}

class _FeaturedServices extends StatelessWidget {
  const _FeaturedServices({required this.services});

  final List<AmenityService> services;

  @override
  Widget build(BuildContext context) {
    final featured = services.where((s) => s.isFeatured).toList();
    final visible = featured.isEmpty ? services : featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Lo que ofrece este espacio'),
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
              label: 'Ver todos los servicios',
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
                  'Todos los servicios',
                  style: GatesTypography.headingSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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

class _Description extends StatelessWidget {
  const _Description({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Un espacio para compartir'),
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

class _Schedule extends StatelessWidget {
  const _Schedule({required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Horarios de uso'),
        for (final block in amenity.effectiveSchedule)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(block.label, style: GatesTypography.body),
          ),
      ],
    );
  }
}

class _BookingRules extends StatelessWidget {
  const _BookingRules({required this.details});

  final AmenityDetails details;

  @override
  Widget build(BuildContext context) {
    final amenity = details.amenity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Antes de reservar'),
        if (amenity.bookingDurationMinutes != null) ...[
          Text('Duración por reserva', style: GatesTypography.label),
          const SizedBox(height: 4),
          Text(
            _durationLabel(amenity.bookingDurationMinutes!),
            style: _bodySecondary(context),
          ),
          const SizedBox(height: GatesSpacing.space16),
        ],
        if (details.bookingLimits.isNotEmpty) ...[
          Text('Límite por residente', style: GatesTypography.label),
          const SizedBox(height: 4),
          for (final limit in details.bookingLimits)
            Text(limit.label, style: _bodySecondary(context)),
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
                  'Fechas cerradas',
                  style: GatesTypography.label.copyWith(
                    color: context.palette.statusWarning,
                  ),
                ),
                const SizedBox(height: GatesSpacing.space8),
                for (final blackout in details.blackouts)
                  Text(
                    _blackoutLabel(blackout),
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

class _Cost extends StatelessWidget {
  const _Cost({required this.amenity});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final hasCost = amenity.requiresPayment && amenity.price != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Costo de la reserva'),
        Text(
          hasCost ? _currencyFormat.format(amenity.price) : 'Sin costo',
          style: GatesTypography.headingMedium,
        ),
        if (hasCost && amenity.bookingDurationMinutes != null) ...[
          const SizedBox(height: GatesSpacing.space8),
          Text(
            'Por reserva de ${_durationLabel(amenity.bookingDurationMinutes!)}',
            style: context.gatesText.labelSecondary,
          ),
        ],
        if (hasCost && amenity.paymentMethods.isNotEmpty) ...[
          const SizedBox(height: GatesSpacing.space16),
          Text('Métodos aceptados', style: GatesTypography.label),
          const SizedBox(height: 4),
          Text(
            amenity.paymentMethods.map(Amenity.paymentMethodLabel).join(' · '),
            style: context.gatesText.labelSecondary,
          ),
        ],
      ],
    );
  }
}

class _TermsButton extends StatelessWidget {
  const _TermsButton({required this.terms});

  final String terms;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GatesButton(
        label: 'Términos y condiciones',
        style: GatesButtonStyle.secondary,
        onPressed: () => showTermsSheet(context, terms),
      ),
    );
  }
}

class _FixedActionBar extends StatelessWidget {
  const _FixedActionBar({required this.details});

  final AmenityDetails details;

  Amenity get amenity => details.amenity;

  Future<void> _pickDateTime(BuildContext context) async {
    final selection = await showBookingDateTimeSheet(
      context,
      amenity: amenity,
      blackouts: details.blackouts,
    );
    if (selection == null || !context.mounted) return;
    context.push(
      '/amenities/${amenity.id}/review',
      extra: ReviewBookingArgs(details: details, selection: selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel = amenity.requiresPayment && amenity.price != null
        ? _currencyFormat.format(amenity.price)
        : 'Sin costo';
    final durationLabel = amenity.bookingDurationMinutes != null
        ? 'por reserva · ${_durationLabel(amenity.bookingDurationMinutes!)}'
        : 'por reserva';

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
              label: 'Elegir fecha',
              onPressed: () => _pickDateTime(context),
            ),
          ),
        ],
      ),
    );
  }
}
