import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import 'amenities_controller.dart';

class CancelBookingState {
  const CancelBookingState({this.isCancelling = false});

  final bool isCancelling;
}

sealed class CancelBookingEvent {
  const CancelBookingEvent();
}

/// The booking is cancelled and the list refreshed; the sheet closes.
class BookingCancelled extends CancelBookingEvent {
  const BookingCancelled();
}

class CancelBookingFailed extends CancelBookingEvent {
  const CancelBookingFailed(this.failure);
  final Failure failure;
}

/// Cancels one booking (optionally with a reason) and refreshes the
/// resident's bookings.
class CancelBookingController extends Notifier<CancelBookingState> {
  CancelBookingController(this.bookingId);

  final String bookingId;

  final _events = StreamController<CancelBookingEvent>.broadcast();
  bool _disposed = false;

  Stream<CancelBookingEvent> get events => _events.stream;

  @override
  CancelBookingState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    return const CancelBookingState();
  }

  Future<void> cancel({String? reason}) async {
    if (state.isCancelling) return;
    state = const CancelBookingState(isCancelling: true);
    try {
      await ref
          .read(amenitiesRepositoryProvider)
          .cancelBooking(bookingId, reason: reason);
      ref.invalidate(myBookingsProvider);
      if (_disposed) return;
      _events.add(const BookingCancelled());
    } catch (error) {
      if (_disposed) return;
      state = const CancelBookingState();
      _events.add(CancelBookingFailed(Failure.from(error)));
    }
  }
}

final cancelBookingControllerProvider = NotifierProvider.autoDispose
    .family<CancelBookingController, CancelBookingState, String>(
      CancelBookingController.new,
    );
