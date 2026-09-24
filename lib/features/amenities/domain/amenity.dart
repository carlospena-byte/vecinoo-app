class Amenity {
  const Amenity({
    required this.id,
    required this.residentialId,
    required this.name,
    this.description,
    this.location,
    this.capacity,
    required this.requiresBooking,
  });

  final String id;
  final String residentialId;
  final String name;
  final String? description;
  final String? location;
  final int? capacity;
  final bool requiresBooking;

  factory Amenity.fromMap(Map<String, dynamic> map) {
    return Amenity(
      id: map['id'] as String,
      residentialId: map['residential_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      capacity: map['capacity'] as int?,
      requiresBooking: map['requires_booking'] as bool? ?? false,
    );
  }
}
