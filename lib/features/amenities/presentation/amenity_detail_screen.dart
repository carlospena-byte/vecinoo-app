import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity_details.dart';
import 'amenities_controller.dart';
import 'amenity_action_bar.dart';
import 'amenity_detail_controller.dart';
import 'amenity_detail_sections.dart';

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
          message: context.l10n.amenitiesDetailLoadError,
          onRetry: () => ref.invalidate(amenityDetailsProvider(amenityId)),
        ),
        data: (details) => _AmenityDetailContent(details: details),
      ),
    );
  }
}

class _AmenityDetailContent extends ConsumerStatefulWidget {
  const _AmenityDetailContent({required this.details});

  final AmenityDetails details;

  @override
  ConsumerState<_AmenityDetailContent> createState() =>
      _AmenityDetailContentState();
}

class _AmenityDetailContentState extends ConsumerState<_AmenityDetailContent> {
  StreamSubscription<ReviewRequested>? _events;

  AmenityDetails get details => widget.details;

  @override
  void initState() {
    super.initState();
    // Keep the controller alive for as long as the screen is: without photos
    // nothing else watches it, so it would auto-dispose (closing `events`)
    // and the date picker's selection would never reach the review step.
    ref.listenManual(
      amenityDetailControllerProvider(details.amenity.id),
      (_, _) {},
    );
    _events = ref
        .read(amenityDetailControllerProvider(details.amenity.id).notifier)
        .events
        .listen((event) {
          if (!mounted) return;
          context.push(
            '/amenities/${details.amenity.id}/review',
            extra: event.args,
          );
        });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: context.l10n.amenitiesBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(TablerIcons.arrowLeft, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                Text(
                  context.l10n.amenitiesDetailTitle,
                  style: GatesTypography.headingSmall,
                ),
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
                      AmenityIdentity(amenity: amenity),
                      const AmenitySectionDivider(),
                      if (details.services.isNotEmpty) ...[
                        AmenityFeaturedServices(services: details.services),
                        const AmenitySectionDivider(),
                      ],
                      if (amenity.description != null) ...[
                        AmenityDescription(html: amenity.description!),
                        const AmenitySectionDivider(),
                      ],
                      if (amenity.effectiveSchedule.isNotEmpty) ...[
                        AmenitySchedule(amenity: amenity),
                        const AmenitySectionDivider(),
                      ],
                      if (amenity.requiresBooking) ...[
                        AmenityBookingRules(details: details),
                        const AmenitySectionDivider(),
                      ],
                      // Cost is about the booking, so free-access amenities
                      // skip it (the section above already ended in a divider).
                      if (amenity.requiresBooking)
                        AmenityCost(amenity: amenity),
                      if (amenity.terms != null) ...[
                        if (amenity.requiresBooking)
                          const AmenitySectionDivider(),
                        AmenityTermsButton(terms: amenity.terms!),
                      ],
                      const SizedBox(height: GatesSpacing.space24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (amenity.requiresBooking) AmenityActionBar(details: details),
        ],
      ),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _decodeWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    return (mq.size.width * mq.devicePixelRatio).round();
  }

  /// Decodes the neighbouring photos ahead of the swipe so they are ready
  /// when the page slides in.
  void _precacheNeighbours(BuildContext context, List<String> urls, int page) {
    final width = _decodeWidth(context);
    for (final i in [page - 1, page + 1]) {
      if (i < 0 || i >= urls.length) continue;
      precacheImage(
        ResizeImage(NetworkImage(urls[i]), width: width),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageCount == 0) return const _GalleryPlaceholder();

    final page = ref.watch(
      amenityDetailControllerProvider(widget.amenityId)
          .select((s) => s.galleryPage),
    );
    final urlsAsync = ref.watch(amenityGalleryUrlsProvider(widget.amenityId));
    return urlsAsync.when(
      loading: () => const SizedBox(height: 260, child: LoadingView()),
      error: (e, _) => const _GalleryPlaceholder(icon: TablerIcons.photoOff),
      data: (photoUrls) {
        if (photoUrls.isEmpty) return const _GalleryPlaceholder();

        return SizedBox(
          height: 260,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: photoUrls.length,
                onPageChanged: (i) {
                  ref
                      .read(
                        amenityDetailControllerProvider(widget.amenityId)
                            .notifier,
                      )
                      .setGalleryPage(i);
                  _precacheNeighbours(context, photoUrls, i);
                },
                itemBuilder: (context, index) => Semantics(
                  button: true,
                  label: context.l10n.amenitiesPhotoLabel(
                    index + 1,
                    photoUrls.length,
                  ),
                  hint: context.l10n.amenitiesPhotoHint,
                  excludeSemantics: true,
                  onTap: () => _openViewer(context, photoUrls, index),
                  child: GestureDetector(
                    onTap: () => _openViewer(context, photoUrls, index),
                    child: Image.network(
                      photoUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Decode at display size, not full resolution:
                      // decoding multi-MP photos on the raster/UI thread
                      // while paging is what made the swipe stutter.
                      cacheWidth: _decodeWidth(context),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const LoadingView(),
                    ),
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
                      '${page + 1} / ${photoUrls.length}',
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
  const _GalleryPlaceholder({this.icon = TablerIcons.buildingCommunity});

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
            child: Image.network(
              photoUrls[index],
              fit: BoxFit.contain,
              semanticLabel: context.l10n.amenitiesPhotoLabel(
                index + 1,
                photoUrls.length,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
