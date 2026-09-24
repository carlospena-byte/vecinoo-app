import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/amenity.dart';
import '../domain/amenity_booking.dart';

/// Thrown when a booking insert is rejected by the DB's
/// `amenity_bookings_no_overlap` exclusion constraint (Postgres code
/// 23P01) — i.e. someone else booked that slot first.
class BookingConflictException implements Exception {
  const BookingConflictException();
}

class AmenitiesRepository {
  AmenitiesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Amenity>> fetchAmenities(String residentialId) async {
    final rows = await _client
        .from('amenities')
        .select()
        .eq('residential_id', residentialId)
        .eq('is_active', true)
        .order('name');
    return (rows as List).map((row) => Amenity.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// The current user's own bookings — RLS only exposes a resident's own
  /// rows (or an admin's), so this can't show what other residents booked.
  Future<List<AmenityBooking>> fetchMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('fetchMyBookings called with no signed-in user');
    final rows = await _client
        .from('amenity_bookings')
        .select('*, amenities(name)')
        .eq('user_id', userId)
        .order('start_time', ascending: false);
    return (rows as List)
        .map((row) => AmenityBooking.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createBooking({
    required String amenityId,
    required String residentialId,
    required String unitId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('createBooking called with no signed-in user');
    try {
      await _client.from('amenity_bookings').insert({
        'amenity_id': amenityId,
        'residential_id': residentialId,
        'unit_id': unitId,
        'user_id': userId,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'notes': notes,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23P01') {
        throw const BookingConflictException();
      }
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await _client.from('amenity_bookings').update({'status': 'cancelled'}).eq('id', bookingId);
  }
}
