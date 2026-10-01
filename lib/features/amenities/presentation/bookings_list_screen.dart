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

enum _BookingsTab { pending, confirmed, history }

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
class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  _BookingsTab _tab = _BookingsTab.pending;

  @override
  Widget build(BuildContext context) {
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
                child: GatesSegmentedTabs<_BookingsTab>(
                  options: [
                    GatesSegmentedTabOption(
                      value: _BookingsTab.pending,
                      label: context.l10n.amenitiesTabPending,
                    ),
                    GatesSegmentedTabOption(
                      value: _BookingsTab.confirmed,
                      label: context.l10n.amenitiesTabConfirmed,
                    ),
                    GatesSegmentedTabOption(
                      value: _BookingsTab.history,
                      label: context.l10n.amenitiesTabHistory,
                    ),
                  ],
                  selected: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
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
                  final filtered = switch (_tab) {
                    _BookingsTab.pending =>
                      bookings.where(_isPending).toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime)),
                    _BookingsTab.confirmed =>
                      bookings.where(_isConfirmed).toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime)),
                    _BookingsTab.history =>
                      bookings.where(_isHistory).toList()
                        ..sort((a, b) => b.startTime.compareTo(a.startTime)),
                  };
                  if (filtered.isEmpty) {
                    return EmptyView(
                      key: const ValueKey('body-empty'),
                      message: _emptyMessage(context, _tab),
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

bool _isPending(AmenityBooking b) =>
    b.status == BookingStatus.pending && b.isUpcoming;
bool _isConfirmed(AmenityBooking b) =>
    b.status == BookingStatus.confirmed && b.isUpcoming;
bool _isHistory(AmenityBooking b) => !_isPending(b) && !_isConfirmed(b);

String _emptyMessage(BuildContext context, _BookingsTab tab) => switch (tab) {
  _BookingsTab.pending => context.l10n.amenitiesEmptyPending,
  _BookingsTab.confirmed => context.l10n.amenitiesEmptyConfirmed,
  _BookingsTab.history => context.l10n.amenitiesEmptyHistory,
};

/// "Reservation card / Compact" — Figma node 292:861.
class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final AmenityBooking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: () => showBookingDetailSheet(context, ref, booking),
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
