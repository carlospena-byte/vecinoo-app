import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/amenity_booking.dart';

enum BookingsTab { pending, confirmed, history }

bool _isPending(AmenityBooking b) =>
    b.status == BookingStatus.pending && b.isUpcoming;
bool _isConfirmed(AmenityBooking b) =>
    b.status == BookingStatus.confirmed && b.isUpcoming;
bool _isHistory(AmenityBooking b) => !_isPending(b) && !_isConfirmed(b);

/// The bookings shown under [tab]: upcoming ones soonest first, history most
/// recent first.
List<AmenityBooking> bookingsForTab(
  List<AmenityBooking> bookings,
  BookingsTab tab,
) {
  return switch (tab) {
    BookingsTab.pending =>
      bookings.where(_isPending).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime)),
    BookingsTab.confirmed =>
      bookings.where(_isConfirmed).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime)),
    BookingsTab.history =>
      bookings.where(_isHistory).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)),
  };
}

/// Which tab of the bookings list is selected.
class BookingsListController extends Notifier<BookingsTab> {
  @override
  BookingsTab build() => BookingsTab.pending;

  void select(BookingsTab tab) => state = tab;
}

final bookingsListControllerProvider =
    NotifierProvider.autoDispose<BookingsListController, BookingsTab>(
      BookingsListController.new,
    );
