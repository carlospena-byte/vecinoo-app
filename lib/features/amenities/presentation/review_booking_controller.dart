import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/amenities_repository.dart';
import '../domain/amenity_booking.dart';
import '../domain/amenity_details.dart';
import 'amenities_controller.dart';
import 'booking_selection.dart';

/// Arguments for `/amenities/:id/review` — the amenity's full details (for
/// the blackouts list and cost/terms sheets) plus the day/time the resident
/// just picked in the date/time sheet.
class ReviewBookingArgs {
  const ReviewBookingArgs({required this.details, required this.selection});

  final AmenityDetails details;
  final BookingSelection selection;
}

/// Why the booking could not be submitted.
enum ReviewBookingErrorKind {
  pastDate,
  endNotAfterStart,
  conflict,
  blackout,
  submit,
}

/// Recoverable error shown inline on the review screen. [failure] is only
/// set for [ReviewBookingErrorKind.submit].
class ReviewBookingError {
  const ReviewBookingError(this.kind, [this.failure]);

  final ReviewBookingErrorKind kind;
  final Failure? failure;
}

class ReviewBookingState {
  const ReviewBookingState({
    required this.selection,
    this.notes,
    this.isSubmitting = false,
    this.error,
  });

  final BookingSelection selection;
  final String? notes;
  final bool isSubmitting;
  final ReviewBookingError? error;

  ReviewBookingState copyWith({
    BookingSelection? selection,
    Object? notes = _keep,
    bool? isSubmitting,
    Object? error = _keep,
  }) {
    return ReviewBookingState(
      selection: selection ?? this.selection,
      notes: identical(notes, _keep) ? this.notes : notes as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _keep)
          ? this.error
          : error as ReviewBookingError?,
    );
  }
}

const _keep = Object();

/// The booking was created: the screen moves to the result screen.
class BookingCreated {
  const BookingCreated(this.booking);
  final AmenityBooking booking;
}

/// Owns the review step: the (changeable) selection, notes, validation and
/// the create-booking call with its typed conflict/blackout/failure errors.
class ReviewBookingController extends Notifier<ReviewBookingState> {
  ReviewBookingController(this.args);

  final ReviewBookingArgs args;

  final _events = StreamController<BookingCreated>.broadcast();
  bool _disposed = false;

  Stream<BookingCreated> get events => _events.stream;

  @override
  ReviewBookingState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    return ReviewBookingState(selection: args.selection);
  }

  void changeSelection(BookingSelection selection) {
    state = state.copyWith(selection: selection, error: null);
  }

  /// Empty text clears the notes.
  void setNotes(String notes) {
    state = state.copyWith(notes: notes.isEmpty ? null : notes);
  }

  Future<void> confirm() async {
    if (state.isSubmitting) return;
    final selection = state.selection;
    if (selection.startDateTime.isBefore(ref.read(amenitiesClockProvider)())) {
      state = state.copyWith(
        error: const ReviewBookingError(ReviewBookingErrorKind.pastDate),
      );
      return;
    }
    if (!selection.endDateTime.isAfter(selection.startDateTime)) {
      state = state.copyWith(
        error: const ReviewBookingError(
          ReviewBookingErrorKind.endNotAfterStart,
        ),
      );
      return;
    }

    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final booking = await ref
          .read(amenitiesRepositoryProvider)
          .createBooking(
            amenityId: args.details.amenity.id,
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            startTime: selection.startDateTime,
            endTime: selection.endDateTime,
            notes: state.notes,
          );
      ref.invalidate(myBookingsProvider);
      if (_disposed) return;
      _events.add(BookingCreated(booking));
    } on BookingConflictException {
      _fail(const ReviewBookingError(ReviewBookingErrorKind.conflict));
    } on AmenityBlackoutException {
      _fail(const ReviewBookingError(ReviewBookingErrorKind.blackout));
    } catch (error) {
      _fail(
        ReviewBookingError(ReviewBookingErrorKind.submit, Failure.from(error)),
      );
    } finally {
      if (!_disposed) state = state.copyWith(isSubmitting: false);
    }
  }

  void _fail(ReviewBookingError error) {
    if (!_disposed) state = state.copyWith(error: error);
  }
}

final reviewBookingControllerProvider = NotifierProvider.autoDispose
    .family<ReviewBookingController, ReviewBookingState, ReviewBookingArgs>(
      ReviewBookingController.new,
    );
