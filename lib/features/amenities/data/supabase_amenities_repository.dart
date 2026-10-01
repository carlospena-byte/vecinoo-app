import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/amenities_repository.dart';
import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';
import '../domain/amenity_booking.dart';
import '../domain/amenity_card.dart';
import '../domain/amenity_details.dart';
import '../domain/amenity_image.dart';

/// Same private bucket gates-admin uploads amenity photos to.
const _amenityImagesBucket = 'amenity-images';

/// How long a signed image URL stays valid — mirrors gates-admin's
/// `createSignedUrl(path, 60 * 60)`.
const _signedUrlTtlSeconds = 60 * 60;

/// Supabase-backed [AmenitiesRepository]; every call surfaces `Failure`s.
class SupabaseAmenitiesRepository implements AmenitiesRepository {
  SupabaseAmenitiesRepository(this._client);

  final SupabaseClient _client;

  /// The list screen's amenities, each paired with its primary photo
  /// (`amenity_images.is_primary`) resolved to a signed URL in one batch.
  @override
  Future<List<AmenityCard>> fetchAmenities(String residentialId) =>
      guardFailure(() => _fetchAmenities(residentialId));

  Future<List<AmenityCard>> _fetchAmenities(String residentialId) async {
    final rows = await _client
        .from('amenities')
        .select('*, amenity_images(*)')
        .eq('residential_id', residentialId)
        .eq('is_active', true)
        .order('name', ascending: true);
    final amenityRows = (rows as List).cast<Map<String, dynamic>>();

    final primaryPathByAmenityId = <String, String>{};
    for (final row in amenityRows) {
      final images = AmenityImage.sorted(
        (row['amenity_images'] as List? ?? const [])
            .map((r) => AmenityImage.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
      if (images.isNotEmpty) {
        primaryPathByAmenityId[row['id'] as String] = images.first.storagePath;
      }
    }
    final signedUrls = await _signImageUrls(
      primaryPathByAmenityId.values.toList(),
    );

    return amenityRows.map((row) {
      final amenity = Amenity.fromMap(row);
      final path = primaryPathByAmenityId[amenity.id];
      return AmenityCard(
        amenity: amenity,
        imageUrl: path == null ? null : signedUrls[path],
      );
    }).toList();
  }

  /// The amenity plus its gallery, services, booking limits and blackouts —
  /// everything the extended detail screen needs, in one round trip. Mirrors
  /// gates-admin's `WITH_DETAILS_SELECT`.
  @override
  Future<AmenityDetails> fetchAmenityDetails(String amenityId) =>
      guardFailure(() async {
        final row = await _client
            .from('amenities')
            .select(
              '*, amenity_images(*), amenity_services(*, services(*)), '
              'amenity_booking_limits(*), amenity_blackouts(*)',
            )
            .eq('id', amenityId)
            .single();
        return AmenityDetails.fromMap(row);
      });

  /// Resolves storage paths from `amenity_images.storage_path` into
  /// short-lived signed URLs (the bucket is private), keyed by path.
  @override
  Future<Map<String, String>> signImageUrls(List<String> storagePaths) =>
      guardFailure(() => _signImageUrls(storagePaths));

  Future<Map<String, String>> _signImageUrls(List<String> storagePaths) async {
    if (storagePaths.isEmpty) return const {};
    final results = await _client.storage
        .from(_amenityImagesBucket)
        .createSignedUrlsResult(storagePaths, _signedUrlTtlSeconds);
    return {
      for (final result in results)
        if (result is SignedUrlSuccess) result.path: result.signedUrl,
    };
  }

  @override
  Future<List<AmenityBlackout>> fetchBlackouts(String amenityId) =>
      guardFailure(() async {
        final rows = await _client
            .from('amenity_blackouts')
            .select()
            .eq('amenity_id', amenityId)
            .order('start_date', ascending: true);
        return (rows as List)
            .map((row) => AmenityBlackout.fromMap(row as Map<String, dynamic>))
            .toList();
      });

  /// The current user's own bookings — RLS only exposes a resident's own
  /// rows (or an admin's), so this can't show what other residents booked.
  /// Each booking is paired with its amenity's primary photo, resolved to a
  /// signed URL in one batch (mirrors [fetchAmenities]).
  @override
  Future<List<AmenityBooking>> fetchMyBookings() =>
      guardFailure(_fetchMyBookings);

  Future<List<AmenityBooking>> _fetchMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final rows = await _client
        .from('amenity_bookings')
        .select('*, amenities(name, amenity_images(*))')
        .eq('user_id', userId)
        .order('start_time', ascending: false);
    final bookingRows = (rows as List).cast<Map<String, dynamic>>();

    final primaryPathByBookingId = <String, String>{};
    for (final row in bookingRows) {
      final amenity = row['amenities'] as Map<String, dynamic>?;
      final images = AmenityImage.sorted(
        (amenity?['amenity_images'] as List? ?? const [])
            .map((r) => AmenityImage.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
      if (images.isNotEmpty) {
        primaryPathByBookingId[row['id'] as String] = images.first.storagePath;
      }
    }
    final signedUrls = await _signImageUrls(
      primaryPathByBookingId.values.toSet().toList(),
    );

    return bookingRows.map((row) {
      final path = primaryPathByBookingId[row['id'] as String];
      return AmenityBooking.fromMap(
        row,
        imageUrl: path == null ? null : signedUrls[path],
      );
    }).toList();
  }

  /// Returns the row Postgres actually persisted — in particular its
  /// `status`, which is never assumed to be `confirmed` just because the
  /// insert succeeded (it defaults to `pending`; nothing here auto-confirms
  /// it).
  @override
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String residentialId,
    required String unitId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      return await guardFailure(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw const AuthFailure();
        final row = await _client
            .from('amenity_bookings')
            .insert({
              'amenity_id': amenityId,
              'residential_id': residentialId,
              'unit_id': unitId,
              'user_id': userId,
              'start_time': startTime.toUtc().toIso8601String(),
              'end_time': endTime.toUtc().toIso8601String(),
              'notes': notes,
            })
            .select('*, amenities(name)')
            .single();
        return AmenityBooking.fromMap(row);
      });
    } on Failure catch (failure) {
      // Domain-specific rejections (see the interface) beat the generic
      // ServerFailure the guard produced.
      final cause = failure.cause;
      if (cause is PostgrestException) {
        if (cause.code == '23P01') throw const BookingConflictException();
        if (cause.code == 'AM001') throw const AmenityBlackoutException();
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) =>
      guardFailure(() async {
        await _client
            .from('amenity_bookings')
            .update({
              'status': 'cancelled',
              'rejection_reason': reason?.trim().isNotEmpty == true
                  ? reason!.trim()
                  : null,
            })
            .eq('id', bookingId);
      });
}
