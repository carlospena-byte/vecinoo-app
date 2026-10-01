import 'amenity_blackout.dart';
import 'amenity_booking.dart';
import 'amenity_card.dart';
import 'amenity_details.dart';

/// Thrown by [AmenitiesRepository.createBooking] when someone else booked
/// that slot first (the DB's `amenity_bookings_no_overlap` constraint).
class BookingConflictException implements Exception {
  const BookingConflictException();
}

/// Thrown by [AmenitiesRepository.createBooking] when the requested dates
/// fall inside an amenity blackout range (the DB's
/// `amenity_bookings_reject_blackout` trigger).
class AmenityBlackoutException implements Exception {
  const AmenityBlackoutException();
}

/// What the amenities feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions;
/// the only other exceptions are [BookingConflictException] and
/// [AmenityBlackoutException] from [createBooking].
abstract interface class AmenitiesRepository {
  /// Active amenities of the residential, each paired with its primary photo
  /// resolved to a signed URL.
  Future<List<AmenityCard>> fetchAmenities(String residentialId);

  /// The amenity plus its gallery, services, booking limits and blackouts.
  Future<AmenityDetails> fetchAmenityDetails(String amenityId);

  /// Resolves storage paths into short-lived signed URLs, keyed by path.
  Future<Map<String, String>> signImageUrls(List<String> storagePaths);

  Future<List<AmenityBlackout>> fetchBlackouts(String amenityId);

  /// The signed-in user's own bookings. Throws `AuthFailure` with no user.
  Future<List<AmenityBooking>> fetchMyBookings();

  /// Returns the row the backend actually persisted, including its status.
  /// Throws `AuthFailure` with no user.
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String residentialId,
    required String unitId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });

  Future<void> cancelBooking(String bookingId, {String? reason});
}
