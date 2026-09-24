import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/amenities_repository.dart';
import '../domain/amenity.dart';
import '../domain/amenity_booking.dart';

final amenitiesRepositoryProvider = Provider<AmenitiesRepository>((ref) {
  return AmenitiesRepository(ref.watch(supabaseClientProvider));
});

final amenitiesListProvider = FutureProvider.family<List<Amenity>, String>(
  (ref, residentialId) => ref.watch(amenitiesRepositoryProvider).fetchAmenities(residentialId),
);

final myBookingsProvider = FutureProvider<List<AmenityBooking>>(
  (ref) => ref.watch(amenitiesRepositoryProvider).fetchMyBookings(),
);
