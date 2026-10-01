enum BookingLimitPeriod { day, week, month }

BookingLimitPeriod _periodFromString(String value) {
  return BookingLimitPeriod.values.firstWhere(
    (p) => p.name == value,
    orElse: () => BookingLimitPeriod.week,
  );
}

/// A booking-frequency rule for an amenity, e.g. "max 2 per week". Several
/// can apply at once. This is advisory/informational only — nothing in the
/// backend currently counts a resident's existing bookings against it.
class AmenityBookingLimit {
  const AmenityBookingLimit({required this.maxCount, required this.period});

  final int maxCount;
  final BookingLimitPeriod period;

  factory AmenityBookingLimit.fromMap(Map<String, dynamic> map) {
    return AmenityBookingLimit(
      maxCount: map['max_count'] as int,
      period: _periodFromString(map['period'] as String),
    );
  }
}
