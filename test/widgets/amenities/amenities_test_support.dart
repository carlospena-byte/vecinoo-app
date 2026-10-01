import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gates_app/features/amenities/domain/amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenity.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking_limit.dart';
import 'package:gates_app/features/amenities/domain/amenity_card.dart';
import 'package:gates_app/features/amenities/domain/amenity_details.dart';
import 'package:gates_app/features/amenities/domain/amenity_image.dart';
import 'package:gates_app/features/amenities/domain/service.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';

import '../../helpers/pump_app.dart';

/// "Now" used by every amenities widget test (the clock override).
final amenitiesTestNow = DateTime(2030, 6, 10, 12);

class CreatedBooking {
  CreatedBooking(this.amenityId, this.unitId, this.start, this.end, this.notes);
  final String amenityId;
  final String unitId;
  final DateTime start;
  final DateTime end;
  final String? notes;
}

/// In-memory [AmenitiesRepository]. Set the public fields to script it.
class FakeAmenitiesRepository implements AmenitiesRepository {
  List<AmenityCard> cards = const [];
  Map<String, AmenityDetails> details = {};
  List<AmenityBooking> bookings = const [];
  Map<String, String> signed = const {};
  Object? listError;
  Object? signError;
  Object? detailsError;
  Object? bookingsError;
  Object? createError;
  Object? cancelError;
  BookingStatus createStatus = BookingStatus.pending;

  final created = <CreatedBooking>[];
  final cancelled = <(String, String?)>[];
  int listFetches = 0;
  int bookingFetches = 0;

  @override
  Future<List<AmenityCard>> fetchAmenities(String residentialId) async {
    listFetches++;
    if (listError != null) throw listError!;
    return cards;
  }

  @override
  Future<AmenityDetails> fetchAmenityDetails(String amenityId) async {
    if (detailsError != null) throw detailsError!;
    return details[amenityId]!;
  }

  @override
  Future<Map<String, String>> signImageUrls(List<String> storagePaths) async {
    if (signError != null) throw signError!;
    return {
      for (final p in storagePaths)
        if (signed.containsKey(p)) p: signed[p]!,
    };
  }

  @override
  Future<List<AmenityBlackout>> fetchBlackouts(String amenityId) async =>
      details[amenityId]?.blackouts ?? const [];

  @override
  Future<List<AmenityBooking>> fetchMyBookings() async {
    bookingFetches++;
    if (bookingsError != null) throw bookingsError!;
    return bookings;
  }

  @override
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String residentialId,
    required String unitId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    if (createError != null) throw createError!;
    created.add(CreatedBooking(amenityId, unitId, startTime, endTime, notes));
    return AmenityBooking(
      id: 'new-1',
      amenityId: amenityId,
      amenityName: 'Salón',
      startTime: startTime,
      endTime: endTime,
      status: createStatus,
      notes: notes,
    );
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    // A little latency so the UI renders its "cancelling" state.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (cancelError != null) throw cancelError!;
    cancelled.add((bookingId, reason));
  }
}

List<Override> amenitiesOverrides(
  FakeAmenitiesRepository repository, {
  DateTime Function()? clock,
}) => [
  ...membershipOverrides(),
  amenitiesRepositoryProvider.overrideWithValue(repository),
  amenitiesClockProvider.overrideWithValue(clock ?? () => amenitiesTestNow),
];

Amenity makeAmenity({
  String id = 'a1',
  String name = 'Salón de eventos',
  String? description,
  String? location,
  int? capacity,
  bool requiresBooking = true,
  String? terms,
  bool requiresPayment = false,
  double? price,
  List<String> paymentMethods = const [],
  int? duration = 60,
  List<AmenityScheduleBlock> schedule = const [],
}) => Amenity(
  id: id,
  residentialId: 'res-1',
  name: name,
  description: description,
  location: location,
  capacity: capacity,
  requiresBooking: requiresBooking,
  terms: terms,
  requiresPayment: requiresPayment,
  price: price,
  paymentMethods: paymentMethods,
  bookingDurationMinutes: duration,
  schedule: schedule,
);

AmenityDetails makeDetails({
  Amenity? amenity,
  List<AmenityImage> images = const [],
  List<AmenityService> services = const [],
  List<AmenityBookingLimit> limits = const [],
  List<AmenityBlackout> blackouts = const [],
}) => AmenityDetails(
  amenity: amenity ?? makeAmenity(),
  images: images,
  services: services,
  bookingLimits: limits,
  blackouts: blackouts,
);

AmenityBooking makeBooking(
  String id, {
  String name = 'Salón de eventos',
  DateTime? start,
  Duration length = const Duration(hours: 1),
  BookingStatus status = BookingStatus.pending,
  String? reason,
  String? notes,
}) {
  final s = start ?? DateTime.now().add(const Duration(days: 3));
  return AmenityBooking(
    id: id,
    amenityId: 'a1',
    amenityName: name,
    startTime: s,
    endTime: s.add(length),
    status: status,
    rejectionReason: reason,
    notes: notes,
  );
}

// A valid 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Replaces the HTTP stack so `Image.network` gets a 1x1 PNG instead of
/// hitting the network. Call `HttpOverrides.global = null` in tearDown.
void installFakeImageHttp() {
  HttpOverrides.global = _FakeHttpOverrides();
}

void uninstallFakeImageHttp() {
  HttpOverrides.global = null;
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeClient();
}

class _FakeClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _png.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_png).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
