String _trimSeconds(String time) =>
    time.length >= 5 ? time.substring(0, 5) : time;

/// One day-group + time-range pair, e.g. `{ days: ['mon','tue'], openTime:
/// '08:00', closeTime: '09:00' }`. An amenity's `schedule` is a list of
/// these, so different day groups can have different hours.
class AmenityScheduleBlock {
  const AmenityScheduleBlock({
    required this.days,
    required this.openTime,
    required this.closeTime,
  });

  final List<String> days;
  final String openTime;
  final String closeTime;

  /// `openTime` without seconds, e.g. "08:00".
  String get openLabel => _trimSeconds(openTime);

  /// `closeTime` without seconds, e.g. "09:00".
  String get closeLabel => _trimSeconds(closeTime);

  factory AmenityScheduleBlock.fromMap(Map<String, dynamic> map) {
    return AmenityScheduleBlock(
      days: (map['days'] as List).map((d) => d as String).toList(),
      openTime: map['openTime'] as String,
      closeTime: map['closeTime'] as String,
    );
  }
}

class Amenity {
  const Amenity({
    required this.id,
    required this.residentialId,
    required this.name,
    this.description,
    this.location,
    this.capacity,
    required this.requiresBooking,
    this.terms,
    this.openingTime,
    this.closingTime,
    this.availableDays = const [],
    this.schedule = const [],
    this.requiresPayment = false,
    this.price,
    this.paymentMethods = const [],
    this.bookingDurationMinutes,
    this.requiresCleaning = false,
    this.cleanupMinutes,
  });

  final String id;
  final String residentialId;
  final String name;
  final String? description;
  final String? location;
  final int? capacity;
  final bool requiresBooking;
  final String? terms;

  /// Legacy columns, still written by gates-admin as derived values (union
  /// of all `schedule` block days, earliest open, latest close) for
  /// amenities that predate the per-day-group schedule.
  final String? openingTime;
  final String? closingTime;
  final List<String> availableDays;

  final List<AmenityScheduleBlock> schedule;

  final bool requiresPayment;
  final double? price;

  /// Values from `{cash, card, transfer}`, localized in the presentation layer.
  final List<String> paymentMethods;

  final int? bookingDurationMinutes;
  final bool requiresCleaning;
  final int? cleanupMinutes;

  /// `schedule` if the amenity has one, otherwise a single block synthesized
  /// from the legacy `available_days`/`opening_time`/`closing_time` columns
  /// (amenities created before the per-day-group schedule migration).
  List<AmenityScheduleBlock> get effectiveSchedule {
    if (schedule.isNotEmpty) return schedule;
    if (availableDays.isEmpty || openingTime == null || closingTime == null) {
      return const [];
    }
    return [
      AmenityScheduleBlock(
        days: availableDays,
        openTime: openingTime!,
        closeTime: closingTime!,
      ),
    ];
  }

  factory Amenity.fromMap(Map<String, dynamic> map) {
    return Amenity(
      id: map['id'] as String,
      residentialId: map['residential_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      capacity: map['capacity'] as int?,
      requiresBooking: map['requires_booking'] as bool? ?? false,
      terms: map['terms'] as String?,
      openingTime: map['opening_time'] as String?,
      closingTime: map['closing_time'] as String?,
      availableDays:
          (map['available_days'] as List?)?.map((d) => d as String).toList() ??
          const [],
      schedule:
          (map['schedule'] as List?)
              ?.map(
                (b) => AmenityScheduleBlock.fromMap(b as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      requiresPayment: map['requires_payment'] as bool? ?? false,
      price: (map['price'] as num?)?.toDouble(),
      paymentMethods:
          (map['payment_methods'] as List?)?.map((m) => m as String).toList() ??
          const [],
      bookingDurationMinutes: map['booking_duration_minutes'] as int?,
      requiresCleaning: map['requires_cleaning'] as bool? ?? false,
      cleanupMinutes: map['cleanup_minutes'] as int?,
    );
  }
}
