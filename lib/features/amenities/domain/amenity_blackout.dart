/// A date range (inclusive, whole days) where an amenity can't be booked —
/// maintenance, board-only use, etc. This is enforced at the DB level (a
/// trigger on `amenity_bookings` rejects any booking overlapping one of
/// these, raising Postgres error code `AM001`), so fetching these here is
/// only for surfacing them in the UI ahead of time, not for enforcement.
class AmenityBlackout {
  const AmenityBlackout({
    required this.id,
    required this.amenityId,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  final String id;
  final String amenityId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  factory AmenityBlackout.fromMap(Map<String, dynamic> map) {
    return AmenityBlackout(
      id: map['id'] as String,
      amenityId: map['amenity_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      reason: map['reason'] as String?,
    );
  }
}
