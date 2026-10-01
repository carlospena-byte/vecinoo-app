import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';
import 'amenities_controller.dart';
import 'booking_selection.dart';

/// Inputs of the date/time sheet. Equality is by instance of the amenity,
/// blackouts and initial selection, so rebuilding the sheet with the same
/// objects keeps the same controller.
class BookingDateTimeArgs {
  const BookingDateTimeArgs({
    required this.amenity,
    required this.blackouts,
    this.initial,
  });

  final Amenity amenity;
  final List<AmenityBlackout> blackouts;
  final BookingSelection? initial;

  @override
  bool operator ==(Object other) =>
      other is BookingDateTimeArgs &&
      identical(other.amenity, amenity) &&
      identical(other.blackouts, blackouts) &&
      other.initial == initial;

  @override
  int get hashCode => Object.hash(
    identityHashCode(amenity),
    identityHashCode(blackouts),
    initial,
  );
}

enum BookingDateTimeError { endBeforeStart }

class BookingDateTimeState {
  const BookingDateTimeState({
    required this.selectedDay,
    required this.focusedDay,
    required this.start,
    required this.end,
    this.error,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final TimeOfDay start;

  /// Only used by flexible-duration amenities; null for fixed ones.
  final TimeOfDay? end;
  final BookingDateTimeError? error;

  BookingDateTimeState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    TimeOfDay? start,
    TimeOfDay? end,
    Object? error = _keep,
  }) {
    return BookingDateTimeState(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      start: start ?? this.start,
      end: end ?? this.end,
      error: identical(error, _keep)
          ? this.error
          : error as BookingDateTimeError?,
    );
  }
}

const _keep = Object();

/// The sheet confirmed a valid selection; it closes with it.
class BookingSelectionConfirmed {
  const BookingSelectionConfirmed(this.selection);
  final BookingSelection selection;
}

/// Owns the day/time picking rules (blackout days, fixed-duration end time,
/// end-after-start validation); the sheet renders it.
class BookingDateTimeController extends Notifier<BookingDateTimeState> {
  BookingDateTimeController(this.args);

  final BookingDateTimeArgs args;

  final _events = StreamController<BookingSelectionConfirmed>.broadcast();

  Stream<BookingSelectionConfirmed> get events => _events.stream;

  /// Fixed-duration amenities only ask for a start time.
  bool get isFixedDuration => args.amenity.bookingDurationMinutes != null;

  @override
  BookingDateTimeState build() {
    ref.onDispose(_events.close);
    final initial = args.initial;
    final day = initial?.day ?? ref.read(amenitiesClockProvider)();
    return BookingDateTimeState(
      selectedDay: day,
      focusedDay: day,
      start: initial?.start ?? const TimeOfDay(hour: 9, minute: 0),
      end: isFixedDuration
          ? null
          : (initial?.end ?? const TimeOfDay(hour: 10, minute: 0)),
    );
  }

  /// Start + duration for fixed amenities; the picked end otherwise.
  TimeOfDay get computedEnd {
    if (!isFixedDuration) return state.end!;
    final total =
        state.start.hour * 60 +
        state.start.minute +
        args.amenity.bookingDurationMinutes!;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  /// A day can be picked unless it is in the past or inside a blackout.
  bool isDayEnabled(DateTime day) {
    final earliest = ref
        .read(amenitiesClockProvider)()
        .subtract(const Duration(days: 1));
    return !day.isBefore(earliest) && !args.blackouts.any((b) => b.covers(day));
  }

  void selectDay(DateTime selected, DateTime focused) {
    state = state.copyWith(selectedDay: selected, focusedDay: focused);
  }

  void setStart(TimeOfDay time) =>
      state = state.copyWith(start: time, error: null);

  void setEnd(TimeOfDay time) => state = state.copyWith(end: time, error: null);

  void submit() {
    if (!isFixedDuration) {
      final start = DateTime(2000, 1, 1, state.start.hour, state.start.minute);
      final end = DateTime(2000, 1, 1, state.end!.hour, state.end!.minute);
      if (!end.isAfter(start)) {
        state = state.copyWith(error: BookingDateTimeError.endBeforeStart);
        return;
      }
    }
    _events.add(
      BookingSelectionConfirmed(
        BookingSelection(
          day: state.selectedDay,
          start: state.start,
          end: computedEnd,
        ),
      ),
    );
  }
}

final bookingDateTimeControllerProvider = NotifierProvider.autoDispose
    .family<
      BookingDateTimeController,
      BookingDateTimeState,
      BookingDateTimeArgs
    >(BookingDateTimeController.new);
