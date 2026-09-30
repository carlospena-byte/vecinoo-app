import 'amenity.dart';
import 'amenity_blackout.dart';
import 'amenity_booking_limit.dart';
import 'amenity_image.dart';
import 'service.dart';

/// An amenity plus every related record needed to render the extended
/// detail screen: gallery images, its services (with which are featured),
/// booking-frequency limits, and blackout dates.
class AmenityDetails {
  const AmenityDetails({
    required this.amenity,
    required this.images,
    required this.services,
    required this.bookingLimits,
    required this.blackouts,
  });

  final Amenity amenity;
  final List<AmenityImage> images;
  final List<AmenityService> services;
  final List<AmenityBookingLimit> bookingLimits;
  final List<AmenityBlackout> blackouts;

  List<AmenityService> get featuredServices =>
      services.where((s) => s.isFeatured).toList();

  factory AmenityDetails.fromMap(Map<String, dynamic> map) {
    return AmenityDetails(
      amenity: Amenity.fromMap(map),
      images: AmenityImage.sorted(
        (map['amenity_images'] as List? ?? const [])
            .map((row) => AmenityImage.fromMap(row as Map<String, dynamic>))
            .toList(),
      ),
      services: (map['amenity_services'] as List? ?? const [])
          .map((row) => AmenityService.fromMap(row as Map<String, dynamic>))
          .toList(),
      bookingLimits: (map['amenity_booking_limits'] as List? ?? const [])
          .map(
            (row) => AmenityBookingLimit.fromMap(row as Map<String, dynamic>),
          )
          .toList(),
      blackouts: (map['amenity_blackouts'] as List? ?? const [])
          .map((row) => AmenityBlackout.fromMap(row as Map<String, dynamic>))
          .toList(),
    );
  }
}
