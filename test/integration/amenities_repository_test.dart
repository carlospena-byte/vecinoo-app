@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/data/supabase_amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking_limit.dart';

import 'support/local_supabase.dart';

const _bucket = 'amenity-images';

void main() {
  late TestResident resident;
  late SupabaseAmenitiesRepository repository;
  final storagePaths = <String>[];
  final serviceIds = <String>[];

  setUp(() async {
    resident = await TestResident.create();
    repository = SupabaseAmenitiesRepository(resident.client);
  });

  tearDown(() async {
    if (storagePaths.isNotEmpty) {
      try {
        await resident.service.storage.from(_bucket).remove(storagePaths);
      } catch (_) {}
      storagePaths.clear();
    }
    await resident.dispose();
    // Throwaway catalog services (amenity_services rows cascade with the
    // amenity, which dispose() deleted above).
    final cleanup = newServiceClient();
    for (final id in serviceIds) {
      try {
        await cleanup.from('services').delete().eq('id', id);
      } catch (_) {}
    }
    serviceIds.clear();
    await cleanup.dispose();
  });

  var counter = 0;
  Future<String> newAmenity({
    String? name,
    bool active = true,
    Map<String, dynamic> extra = const {},
  }) async {
    counter++;
    final row = await resident.service
        .from('amenities')
        .insert({
          'residential_id': resident.residentialId,
          'name':
              name ??
              'Test: amenidad ${DateTime.now().microsecondsSinceEpoch}-$counter',
          'is_active': active,
          'requires_booking': true,
          ...extra,
        })
        .select('id')
        .single();
    final id = row['id'] as String;
    resident.track('amenities', id);
    return id;
  }

  Future<String> addImage(
    String amenityId, {
    required String file,
    bool primary = false,
    int sortOrder = 0,
    bool upload = true,
  }) async {
    final path = '${resident.residentialId}/$amenityId/$file';
    if (upload) {
      await resident.service.storage
          .from(_bucket)
          .uploadBinary(path, Uint8List.fromList(List.filled(32, 7)));
      storagePaths.add(path);
    }
    await resident.service.from('amenity_images').insert({
      'amenity_id': amenityId,
      'residential_id': resident.residentialId,
      'storage_path': path,
      'is_primary': primary,
      'sort_order': sortOrder,
    });
    return path;
  }

  DateTime utc(int y, int m, int d, int h) => DateTime.utc(y, m, d, h);

  group('fetchAmenities', () {
    test(
      'lists active amenities with signed primary photo, none when absent',
      () async {
        final withPhoto = await newAmenity(name: 'Test: con foto');
        final noPhoto = await newAmenity(name: 'Test: sin foto');
        final inactive = await newAmenity(
          name: 'Test: inactiva',
          active: false,
        );
        final broken = await newAmenity(name: 'Test: foto rota');
        await addImage(withPhoto, file: 'b.png', sortOrder: 2);
        final primary = await addImage(withPhoto, file: 'a.png', primary: true);
        // Image row whose object does not exist: signing fails -> no URL.
        await addImage(broken, file: 'missing.png', upload: false);

        final cards = await repository.fetchAmenities(resident.residentialId);
        final byId = {for (final c in cards) c.amenity.id: c};

        expect(byId.containsKey(inactive), isFalse);
        expect(byId[noPhoto]!.imageUrl, isNull);
        expect(byId[noPhoto]!.amenity.name, 'Test: sin foto');
        expect(byId[withPhoto]!.imageUrl, startsWith('http'));
        expect(byId[withPhoto]!.imageUrl, contains(primary.split('/').last));
        expect(byId[broken]!.imageUrl, isNull);
        // Seeded amenities are still listed, ordered by name.
        final names = cards.map((c) => c.amenity.name).toList();
        expect(names, containsAll(['Business Center', 'Rooftop Pool']));
        expect(names, [...names]..sort());
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'an unknown residential yields an empty list',
      () async {
        final cards = await repository.fetchAmenities(
          '00000000-0000-4000-8000-000000000000',
        );
        expect(cards, isEmpty);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });

  group('fetchAmenityDetails', () {
    test(
      'returns schedule, terms, services, limits, images and blackouts',
      () async {
        final id = await newAmenity(
          name: 'Test: detalle',
          extra: {
            'description': '<p>Salon</p>',
            'terms': 'Sin mascotas',
            'location': 'Torre A',
            'capacity': 12,
            'requires_payment': true,
            'price': 150.5,
            'payment_methods': ['cash', 'card'],
            'booking_duration_minutes': 120,
            'requires_cleaning': true,
            'cleanup_minutes': 30,
            'available_days': ['mon', 'tue'],
            'opening_time': '08:00:00',
            'closing_time': '20:00:00',
            'schedule': [
              {
                'days': ['mon', 'tue'],
                'openTime': '08:00',
                'closeTime': '20:00',
              },
            ],
          },
        );
        final service = await resident.service
            .from('services')
            .insert({
              'residential_id': resident.residentialId,
              'name': 'Test: servicio ${DateTime.now().microsecondsSinceEpoch}',
              'icon': 'IconWifi',
            })
            .select('id')
            .single();
        serviceIds.add(service['id'] as String);
        await resident.service.from('amenity_services').insert({
          'amenity_id': id,
          'service_id': service['id'],
          'is_featured': true,
        });
        await resident.service.from('amenity_booking_limits').insert([
          {'amenity_id': id, 'max_count': 2, 'period': 'day'},
          {'amenity_id': id, 'max_count': 5, 'period': 'month'},
        ]);
        await resident.service.from('amenity_blackouts').insert({
          'amenity_id': id,
          'residential_id': resident.residentialId,
          'start_date': '2031-06-01',
          'end_date': '2031-06-03',
          'reason': 'Test: mantenimiento',
        });
        await addImage(id, file: 'x.png', sortOrder: 1);
        await addImage(id, file: 'p.png', primary: true);

        final details = await repository.fetchAmenityDetails(id);
        final a = details.amenity;
        expect(a.name, 'Test: detalle');
        expect(a.terms, 'Sin mascotas');
        expect(a.capacity, 12);
        expect(a.price, 150.5);
        expect(a.paymentMethods, ['cash', 'card']);
        expect(a.bookingDurationMinutes, 120);
        expect(a.cleanupMinutes, 30);
        expect(a.effectiveSchedule.single.days, ['mon', 'tue']);
        expect(a.effectiveSchedule.single.openLabel, '08:00');
        expect(a.effectiveSchedule.single.closeLabel, '20:00');
        expect(details.services.single.service.icon, 'IconWifi');
        expect(details.featuredServices, hasLength(1));
        expect(details.bookingLimits, hasLength(2));
        expect(
          details.bookingLimits.map((l) => l.maxCount),
          unorderedEquals([2, 5]),
        );
        expect(
          details.bookingLimits.map((l) => l.period),
          contains(isA<BookingLimitPeriod>()),
        );
        expect(details.images.first.isPrimary, isTrue);
        expect(details.images, hasLength(2));
        expect(details.blackouts.single.reason, 'Test: mantenimiento');
        expect(details.blackouts.single.startDate, DateTime(2031, 6, 1));
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'an unknown amenity is a ServerFailure',
      () async {
        await expectLater(
          repository.fetchAmenityDetails(
            '00000000-0000-4000-8000-000000000000',
          ),
          throwsA(isA<ServerFailure>()),
        );
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });

  group('signImageUrls', () {
    test(
      'empty list, real paths and missing paths',
      () async {
        expect(await repository.signImageUrls(const []), isEmpty);
        final id = await newAmenity();
        final path = await addImage(id, file: 's.png', primary: true);
        final urls = await repository.signImageUrls([
          path,
          '${resident.residentialId}/$id/nope.png',
        ]);
        expect(urls.keys, [path]);
        expect(urls[path], startsWith('http'));
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });

  group('fetchBlackouts', () {
    test(
      'returns an amenity blackouts ordered by start date',
      () async {
        final id = await newAmenity();
        await resident.service.from('amenity_blackouts').insert([
          {
            'amenity_id': id,
            'residential_id': resident.residentialId,
            'start_date': '2031-08-10',
            'end_date': '2031-08-12',
          },
          {
            'amenity_id': id,
            'residential_id': resident.residentialId,
            'start_date': '2031-07-01',
            'end_date': '2031-07-01',
            'reason': 'Test: uno',
          },
        ]);
        final blackouts = await repository.fetchBlackouts(id);
        expect(blackouts.map((b) => b.startDate), [
          DateTime(2031, 7, 1),
          DateTime(2031, 8, 10),
        ]);
        expect(blackouts.first.reason, 'Test: uno');
        expect(blackouts.last.reason, isNull);
        expect(blackouts.first.amenityId, id);
        expect(await repository.fetchBlackouts(await newAmenity()), isEmpty);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });

  group('bookings', () {
    test(
      'createBooking persists a row, fetchMyBookings returns it with image',
      () async {
        final id = await newAmenity(name: 'Test: reservable');
        final path = await addImage(id, file: 'c.png', primary: true);
        final start = utc(2031, 4, 1, 10);
        final end = utc(2031, 4, 1, 12);

        final booking = await repository.createBooking(
          amenityId: id,
          residentialId: resident.residentialId,
          unitId: resident.unitId,
          startTime: start,
          endTime: end,
          notes: 'Test: cumpleanos',
        );
        resident.track('amenity_bookings', booking.id);

        expect(booking.amenityId, id);
        expect(booking.amenityName, 'Test: reservable');
        expect(booking.status, BookingStatus.pending);
        expect(booking.notes, 'Test: cumpleanos');
        expect(booking.startTime.toUtc(), start);

        final row = await resident.service
            .from('amenity_bookings')
            .select()
            .eq('id', booking.id)
            .single();
        expect(row['user_id'], resident.userId);
        expect(row['unit_id'], resident.unitId);
        expect(row['residential_id'], resident.residentialId);
        expect(DateTime.parse(row['end_time'] as String).toUtc(), end);
        expect(row['status'], 'pending');

        // A second booking for an amenity without photo.
        final other = await newAmenity(name: 'Test: otra');
        final second = await repository.createBooking(
          amenityId: other,
          residentialId: resident.residentialId,
          unitId: resident.unitId,
          startTime: utc(2031, 5, 1, 10),
          endTime: utc(2031, 5, 1, 11),
        );
        resident.track('amenity_bookings', second.id);

        final mine = await repository.fetchMyBookings();
        expect(mine.map((b) => b.id), [second.id, booking.id]);
        final first = mine.firstWhere((b) => b.id == booking.id);
        expect(first.imageUrl, startsWith('http'));
        expect(first.imageUrl, contains(path.split('/').last));
        expect(first.amenityName, 'Test: reservable');
        expect(mine.firstWhere((b) => b.id == second.id).imageUrl, isNull);
        expect(mine.firstWhere((b) => b.id == second.id).notes, isNull);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'fetchMyBookings is empty for a resident without bookings',
      () async {
        expect(await repository.fetchMyBookings(), isEmpty);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'an overlapping booking throws BookingConflictException',
      () async {
        final id = await newAmenity();
        final first = await repository.createBooking(
          amenityId: id,
          residentialId: resident.residentialId,
          unitId: resident.unitId,
          startTime: utc(2031, 4, 2, 10),
          endTime: utc(2031, 4, 2, 12),
        );
        resident.track('amenity_bookings', first.id);

        await expectLater(
          repository.createBooking(
            amenityId: id,
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 4, 2, 11),
            endTime: utc(2031, 4, 2, 13),
          ),
          throwsA(isA<BookingConflictException>()),
        );

        // Adjacent slot is fine.
        final adjacent = await repository.createBooking(
          amenityId: id,
          residentialId: resident.residentialId,
          unitId: resident.unitId,
          startTime: utc(2031, 4, 2, 12),
          endTime: utc(2031, 4, 2, 13),
        );
        resident.track('amenity_bookings', adjacent.id);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'a blackout day throws AmenityBlackoutException and persists nothing',
      () async {
        final id = await newAmenity();
        await resident.service.from('amenity_blackouts').insert({
          'amenity_id': id,
          'residential_id': resident.residentialId,
          'start_date': '2031-03-10',
          'end_date': '2031-03-12',
        });

        await expectLater(
          repository.createBooking(
            amenityId: id,
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 3, 11, 10),
            endTime: utc(2031, 3, 11, 12),
          ),
          throwsA(isA<AmenityBlackoutException>()),
        );
        final rows = await resident.service
            .from('amenity_bookings')
            .select('id')
            .eq('amenity_id', id);
        expect(rows, isEmpty);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'rejections that are not conflicts map to typed Failures',
      () async {
        final id = await newAmenity();
        // Not a member of that residential: RLS rejects the insert.
        await expectLater(
          repository.createBooking(
            amenityId: id,
            residentialId: '00000000-0000-4000-8000-000000000000',
            unitId: resident.unitId,
            startTime: utc(2031, 4, 3, 10),
            endTime: utc(2031, 4, 3, 11),
          ),
          throwsA(isA<AuthFailure>()),
        );
        // Unknown amenity: foreign key violation.
        await expectLater(
          repository.createBooking(
            amenityId: '00000000-0000-4000-8000-000000000000',
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 4, 3, 10),
            endTime: utc(2031, 4, 3, 11),
          ),
          throwsA(isA<ServerFailure>()),
        );
        // end before start: tstzrange error, not a conflict.
        await expectLater(
          repository.createBooking(
            amenityId: id,
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 4, 3, 12),
            endTime: utc(2031, 4, 3, 10),
          ),
          throwsA(isA<ServerFailure>()),
        );
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );

    test(
      'cancelBooking changes the status and stores a trimmed reason',
      () async {
        final id = await newAmenity();
        Future<String> book(int day) async {
          final b = await repository.createBooking(
            amenityId: id,
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 4, day, 10),
            endTime: utc(2031, 4, day, 11),
          );
          resident.track('amenity_bookings', b.id);
          return b.id;
        }

        Future<Map<String, dynamic>> read(String bookingId) => resident.service
            .from('amenity_bookings')
            .select()
            .eq('id', bookingId)
            .single();

        final a = await book(5);
        await repository.cancelBooking(a, reason: '  Ya no puedo  ');
        var row = await read(a);
        expect(row['status'], 'cancelled');
        expect(row['rejection_reason'], 'Ya no puedo');

        final b = await book(6);
        await repository.cancelBooking(b);
        row = await read(b);
        expect(row['status'], 'cancelled');
        expect(row['rejection_reason'], isNull);

        final c = await book(7);
        await repository.cancelBooking(c, reason: '   ');
        expect((await read(c))['rejection_reason'], isNull);

        final mine = await repository.fetchMyBookings();
        final cancelled = mine.firstWhere((x) => x.id == a);
        expect(cancelled.status, BookingStatus.cancelled);
        expect(cancelled.rejectionReason, 'Ya no puedo');
        expect(cancelled.isCancellable, isFalse);

        // The slot is free again once cancelled.
        final again = await book(5);
        expect(again, isNotEmpty);
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });

  group('without a signed-in user', () {
    test(
      'fetchMyBookings and createBooking throw AuthFailure',
      () async {
        final anon = newAnonClient();
        addTearDown(anon.dispose);
        final anonRepo = SupabaseAmenitiesRepository(anon);
        await expectLater(
          anonRepo.fetchMyBookings(),
          throwsA(isA<AuthFailure>()),
        );
        await expectLater(
          anonRepo.createBooking(
            amenityId: await newAmenity(),
            residentialId: resident.residentialId,
            unitId: resident.unitId,
            startTime: utc(2031, 4, 9, 10),
            endTime: utc(2031, 4, 9, 11),
          ),
          throwsA(isA<AuthFailure>()),
        );
      },
      skip: localSupabaseSkipReason,
      tags: 'integration',
    );
  });
}
