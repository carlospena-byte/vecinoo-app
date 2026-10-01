/// A photo attached to an amenity, stored in the private `amenity-images`
/// Supabase Storage bucket. `storagePath` must be resolved to a signed URL
/// before it can be displayed — see `AmenitiesRepository.signImageUrls`.
class AmenityImage {
  const AmenityImage({
    required this.id,
    required this.amenityId,
    required this.storagePath,
    required this.isPrimary,
    required this.sortOrder,
  });

  final String id;
  final String amenityId;
  final String storagePath;
  final bool isPrimary;
  final int sortOrder;

  factory AmenityImage.fromMap(Map<String, dynamic> map) {
    return AmenityImage(
      id: map['id'] as String,
      amenityId: map['amenity_id'] as String,
      storagePath: map['storage_path'] as String,
      isPrimary: map['is_primary'] as bool? ?? false,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// Sorted with the primary photo first, then by `sortOrder`.
  static List<AmenityImage> sorted(List<AmenityImage> images) {
    final sorted = [...images];
    sorted.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  }
}
