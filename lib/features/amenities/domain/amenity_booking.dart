enum BookingStatus { pending, confirmed, cancelled }

BookingStatus _statusFromString(String value) {
  return BookingStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BookingStatus.pending,
  );
}

class AmenityBooking {
  const AmenityBooking({
    required this.id,
    required this.amenityId,
    required this.amenityName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
  });

  final String id;
  final String amenityId;
  final String amenityName;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String? notes;

  bool get isUpcoming => endTime.isAfter(DateTime.now()) && status != BookingStatus.cancelled;

  factory AmenityBooking.fromMap(Map<String, dynamic> map) {
    final amenity = map['amenities'] as Map<String, dynamic>?;
    return AmenityBooking(
      id: map['id'] as String,
      amenityId: map['amenity_id'] as String,
      amenityName: amenity?['name'] as String? ?? 'Amenidad',
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      status: _statusFromString(map['status'] as String),
      notes: map['notes'] as String?,
    );
  }
}
