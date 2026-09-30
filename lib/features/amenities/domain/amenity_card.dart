import 'amenity.dart';

/// An amenity plus its primary photo, resolved for the list screen. The
/// photo is signed server-side by [AmenitiesRepository.fetchAmenities]
/// since `amenity-images` is a private bucket.
class AmenityCard {
  const AmenityCard({required this.amenity, this.imageUrl});

  final Amenity amenity;
  final String? imageUrl;
}
