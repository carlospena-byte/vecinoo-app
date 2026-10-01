import 'package:flutter/material.dart' show TimeOfDay;

/// A day + time range picked in the booking date/time sheet. For a
/// fixed-duration amenity, [end] is always [start] + `bookingDurationMinutes`.
class BookingSelection {
  const BookingSelection({
    required this.day,
    required this.start,
    required this.end,
  });

  final DateTime day;
  final TimeOfDay start;
  final TimeOfDay end;

  DateTime get startDateTime =>
      DateTime(day.year, day.month, day.day, start.hour, start.minute);
  DateTime get endDateTime =>
      DateTime(day.year, day.month, day.day, end.hour, end.minute);

  @override
  bool operator ==(Object other) =>
      other is BookingSelection &&
      other.day == day &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(day, start, end);
}
