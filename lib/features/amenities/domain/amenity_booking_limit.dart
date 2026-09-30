enum BookingLimitPeriod { day, week, month }

BookingLimitPeriod _periodFromString(String value) {
  return BookingLimitPeriod.values.firstWhere(
    (p) => p.name == value,
    orElse: () => BookingLimitPeriod.week,
  );
}

extension BookingLimitPeriodLabel on BookingLimitPeriod {
  /// e.g. "día", "semana", "mes" — matches gates-admin's period labels.
  String get label => switch (this) {
    BookingLimitPeriod.day => 'día',
    BookingLimitPeriod.week => 'semana',
    BookingLimitPeriod.month => 'mes',
  };
}

/// A booking-frequency rule for an amenity, e.g. "max 2 per week". Several
/// can apply at once. This is advisory/informational only — nothing in the
/// backend currently counts a resident's existing bookings against it.
class AmenityBookingLimit {
  const AmenityBookingLimit({required this.maxCount, required this.period});

  final int maxCount;
  final BookingLimitPeriod period;

  String get label {
    final countLabel = maxCount == 1 ? 'reserva' : 'reservas';
    return 'Máximo $maxCount $countLabel por ${period.label}';
  }

  factory AmenityBookingLimit.fromMap(Map<String, dynamic> map) {
    return AmenityBookingLimit(
      maxCount: map['max_count'] as int,
      period: _periodFromString(map['period'] as String),
    );
  }
}
