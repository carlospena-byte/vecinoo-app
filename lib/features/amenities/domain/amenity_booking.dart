enum BookingStatus { pending, confirmed, cancelled, expired }

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
    this.rejectionReason,
    this.imageUrl,
  });

  final String id;
  final String amenityId;
  final String amenityName;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String? notes;

  /// Optional note left by whoever rejected this booking (admin panel or
  /// this app's own cancel flow) explaining why — distinct from [notes],
  /// which is the requester's own note left when booking.
  final String? rejectionReason;
  final String? imageUrl;

  bool get isUpcoming =>
      endTime.isAfter(DateTime.now()) &&
      status != BookingStatus.cancelled &&
      status != BookingStatus.expired;

  /// Whether the resident can still cancel this booking — future and not
  /// already cancelled. Mirrors the "Reservation card / Compact" Figma spec.
  bool get isCancellable => isUpcoming;

  factory AmenityBooking.fromMap(Map<String, dynamic> map, {String? imageUrl}) {
    final amenity = map['amenities'] as Map<String, dynamic>?;
    return AmenityBooking(
      id: map['id'] as String,
      amenityId: map['amenity_id'] as String,
      amenityName: amenity?['name'] as String? ?? 'Amenidad',
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      status: _statusFromString(map['status'] as String),
      notes: map['notes'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      imageUrl: imageUrl,
    );
  }
}
