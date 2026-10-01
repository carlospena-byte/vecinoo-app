import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/nav_clearance.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amenity_thumbnail.dart';
import '../../../core/widgets/gates_add_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity_booking.dart';
import 'amenities_controller.dart';
import 'booking_bottom_sheets.dart';
import 'bookings_list_controller.dart';

final _shortDateFormat = DateFormat('EEE d MMM y', 'es');
final _timeFormat = DateFormat('HH:mm', 'es');

/// Strips intl's trailing "." on abbreviated es weekday/month tokens and
/// capitalizes the first letter — turns "sáb. 17 oct. 2026" into the
/// Figma-exact "Sáb 17 oct 2026".
String _shortDateLabel(DateTime date) {
  final raw = _shortDateFormat.format(date).replaceAll('.', '');
  return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
}

String _timeRangeLabel(AmenityBooking booking) =>
    '${_timeFormat.format(booking.startTime)}–${_timeFormat.format(booking.endTime)}';

/// "Reservas" tab — same shape as the Visitas tab: header with a "+" that
/// starts a new booking, then Pendientes / Confirmadas / Historial. Figma
/// nodes R04B (Confirmadas) and R04C (Historial); Pendientes reuses the
/// same card/tab shell.
class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(bookingsListControllerProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                  Expanded(
                    child: Text(
                      context.l10n.amenitiesBookingsTitle,
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                  GatesAddButton(
                    semanticLabel: context.l10n.amenitiesNewBooking,
                    onTap: () => context.push('/amenities'),
                  ),
                ],
              ),
            ),
            bookingsAsync.when(
              loading: () =>
                  const SizedBox.shrink(key: ValueKey('tabs-loading')),
              error: (e, _) =>
                  const SizedBox.shrink(key: ValueKey('tabs-error')),
              data: (bookings) => Padding(
                key: const ValueKey('tabs-data'),
                padding: const EdgeInsets.fromLTRB(
                  GatesSpacing.space24,
                  GatesSpacing.space16,
                  GatesSpacing.space24,
                  0,
                ),
                child: GatesSegmentedTabs<BookingsTab>(
                  options: [
                    GatesSegmentedTabOption(
                      value: BookingsTab.pending,
                      label: context.l10n.amenitiesTabPending,
                    ),
                    GatesSegmentedTabOption(
                      value: BookingsTab.confirmed,
                      label: context.l10n.amenitiesTabConfirmed,
                    ),
                    GatesSegmentedTabOption(
                      value: BookingsTab.history,
                      label: context.l10n.amenitiesTabHistory,
                    ),
                  ],
                  selected: tab,
                  onSelect: ref
                      .read(bookingsListControllerProvider.notifier)
                      .select,
                ),
              ),
            ),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const LoadingView(key: ValueKey('body-loading')),
                error: (e, _) => ErrorView(
                  key: const ValueKey('body-error'),
                  message: context.l10n.amenitiesBookingsLoadError,
                  onRetry: () => ref.invalidate(myBookingsProvider),
                ),
                data: (bookings) {
                  final filtered = bookingsForTab(bookings, tab);
                  if (filtered.isEmpty) {
                    return EmptyView(
                      key: const ValueKey('body-empty'),
                      message: _emptyMessage(context, tab),
                      icon: Icons.event_busy_outlined,
                    );
                  }
                  return RefreshIndicator(
                    key: const ValueKey('body-list'),
                    onRefresh: () async => ref.invalidate(myBookingsProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        GatesSpacing.space24,
                        GatesSpacing.space16,
                        GatesSpacing.space24,
                        homeNavClearance(context),
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: GatesSpacing.space12),
                      itemBuilder: (context, index) =>
                          _BookingCard(booking: filtered[index]),
                    ),
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

String _emptyMessage(BuildContext context, BookingsTab tab) => switch (tab) {
  BookingsTab.pending => context.l10n.amenitiesEmptyPending,
  BookingsTab.confirmed => context.l10n.amenitiesEmptyConfirmed,
  BookingsTab.history => context.l10n.amenitiesEmptyHistory,
};

/// "Reservation card / Compact" — Figma node 292:861.
class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final AmenityBooking booking;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: () => showBookingDetailSheet(context, booking),
      child: Container(
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.amenityName,
                    style: GatesTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    '${_shortDateLabel(booking.startTime)}\n${_timeRangeLabel(booking)}',
                    style: context.gatesText.labelSecondary,
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  _StatusBadge(
                    status: booking.status,
                    isUpcoming: booking.isUpcoming,
                  ),
                ],
              ),
            ),
            const SizedBox(width: GatesSpacing.space16),
            AmenityThumbnail(imageUrl: booking.imageUrl),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isUpcoming});

  final BookingStatus status;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      BookingStatus.pending => (
        context.palette.statusWarningBg,
        context.palette.statusWarning,
        context.l10n.amenitiesStatusPending,
      ),
      BookingStatus.confirmed => (
        context.palette.bgAccent,
        context.palette.textBrand,
        context.l10n.amenitiesStatusConfirmed,
      ),
      BookingStatus.cancelled => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
        context.l10n.amenitiesStatusCancelled,
      ),
      BookingStatus.expired => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
        context.l10n.amenitiesStatusExpired,
      ),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radius8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: context.gatesText.caption.copyWith(color: foreground),
      ),
    );
  }
}
