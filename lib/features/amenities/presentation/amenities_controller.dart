import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_amenities_repository.dart';
import '../domain/amenities_repository.dart';
import '../domain/amenity_blackout.dart';
import '../domain/amenity_booking.dart';
import '../domain/amenity_card.dart';
import '../domain/amenity_details.dart';

final amenitiesRepositoryProvider = Provider<AmenitiesRepository>((ref) {
  return SupabaseAmenitiesRepository(ref.watch(supabaseClientProvider));
});

/// "Now" for booking validation; overridden in tests.
final amenitiesClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final amenitiesListProvider = FutureProvider.family<List<AmenityCard>, String>(
  (ref, residentialId) =>
      ref.watch(amenitiesRepositoryProvider).fetchAmenities(residentialId),
);

final myBookingsProvider = FutureProvider<List<AmenityBooking>>(
  (ref) => ref.watch(amenitiesRepositoryProvider).fetchMyBookings(),
);

final amenityBlackoutsProvider =
    FutureProvider.family<List<AmenityBlackout>, String>(
      (ref, amenityId) =>
          ref.watch(amenitiesRepositoryProvider).fetchBlackouts(amenityId),
    );

final amenityDetailsProvider = FutureProvider.family<AmenityDetails, String>(
  (ref, amenityId) =>
      ref.watch(amenitiesRepositoryProvider).fetchAmenityDetails(amenityId),
);

/// Signed URLs for an amenity's gallery, keyed by storage path — resolved
/// together since the bucket is private and each URL expires after an hour.
/// Keyed by amenity id (not the path list directly) so Riverpod can cache it
/// across rebuilds instead of re-signing every time a new list is built.
final amenityImageUrlsProvider =
    FutureProvider.family<Map<String, String>, String>((ref, amenityId) async {
      final details = await ref.watch(amenityDetailsProvider(amenityId).future);
      final paths = details.images.map((i) => i.storagePath).toList();
      return ref.watch(amenitiesRepositoryProvider).signImageUrls(paths);
    });

/// The gallery's photo URLs in display order; images whose URL could not be
/// signed are skipped.
final amenityGalleryUrlsProvider = FutureProvider.family<List<String>, String>((
  ref,
  amenityId,
) async {
  final details = await ref.watch(amenityDetailsProvider(amenityId).future);
  final urls = await ref.watch(amenityImageUrlsProvider(amenityId).future);
  return details.images
      .map((image) => urls[image.storagePath])
      .whereType<String>()
      .toList();
});
