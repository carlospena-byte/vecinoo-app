import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/amenities/domain/amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenity.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking_limit.dart';
import 'package:gates_app/features/amenities/domain/amenity_card.dart';
import 'package:gates_app/features/amenities/domain/amenity_details.dart';
import 'package:gates_app/features/amenities/domain/amenity_image.dart';
import 'package:gates_app/features/amenities/domain/service.dart';
import 'package:gates_app/features/amenities/presentation/service_icons.dart';

Map<String, dynamic> _amenityMap([Map<String, dynamic> extra = const {}]) => {
  'id': 'a1',
  'residential_id': 'r1',
  'name': 'Alberca',
  ...extra,
};

void main() {
  group('Amenity.fromMap', () {
    test('minimal row applies defaults', () {
      final a = Amenity.fromMap(_amenityMap());
      expect(a.id, 'a1');
      expect(a.residentialId, 'r1');
      expect(a.name, 'Alberca');
      expect(a.requiresBooking, isFalse);
      expect(a.requiresPayment, isFalse);
      expect(a.requiresCleaning, isFalse);
      expect(a.availableDays, isEmpty);
      expect(a.schedule, isEmpty);
      expect(a.paymentMethods, isEmpty);
      expect(a.price, isNull);
      expect(a.capacity, isNull);
      expect(a.effectiveSchedule, isEmpty);
    });

    test('full row parses every column', () {
      final a = Amenity.fromMap(
        _amenityMap({
          'description': '<p>hola</p>',
          'location': 'Torre A',
          'capacity': 20,
          'requires_booking': true,
          'terms': 'T',
          'opening_time': '08:00:00',
          'closing_time': '20:00:00',
          'available_days': ['mon', 'tue'],
          'schedule': [
            {
              'days': ['sat'],
              'openTime': '10:00:00',
              'closeTime': '12:30',
            },
          ],
          'requires_payment': true,
          'price': 150, // int from JSON must become double
          'payment_methods': ['cash', 'card'],
          'booking_duration_minutes': 90,
          'requires_cleaning': true,
          'cleanup_minutes': 30,
        }),
      );
      expect(a.description, '<p>hola</p>');
      expect(a.location, 'Torre A');
      expect(a.capacity, 20);
      expect(a.requiresBooking, isTrue);
      expect(a.terms, 'T');
      expect(a.price, 150.0);
      expect(a.paymentMethods, ['cash', 'card']);
      expect(a.bookingDurationMinutes, 90);
      expect(a.requiresCleaning, isTrue);
      expect(a.cleanupMinutes, 30);
      expect(a.schedule.single.days, ['sat']);
    });

    test('schedule block labels drop the seconds', () {
      final block = AmenityScheduleBlock.fromMap({
        'days': ['mon'],
        'openTime': '08:00:00',
        'closeTime': '09:30',
      });
      expect(block.openLabel, '08:00');
      expect(block.closeLabel, '09:30');
      const short = AmenityScheduleBlock(
        days: [],
        openTime: '8',
        closeTime: '9',
      );
      expect(short.openLabel, '8');
    });

    test('effectiveSchedule prefers schedule over legacy columns', () {
      final a = Amenity.fromMap(
        _amenityMap({
          'available_days': ['mon'],
          'opening_time': '08:00',
          'closing_time': '09:00',
          'schedule': [
            {
              'days': ['sun'],
              'openTime': '10:00',
              'closeTime': '11:00',
            },
          ],
        }),
      );
      expect(a.effectiveSchedule.single.days, ['sun']);
    });

    test('effectiveSchedule synthesizes a block from legacy columns', () {
      final a = Amenity.fromMap(
        _amenityMap({
          'available_days': ['mon', 'tue'],
          'opening_time': '08:00:00',
          'closing_time': '09:00:00',
        }),
      );
      final block = a.effectiveSchedule.single;
      expect(block.days, ['mon', 'tue']);
      expect(block.openLabel, '08:00');
      expect(block.closeLabel, '09:00');
    });

    test('effectiveSchedule is empty when legacy data is incomplete', () {
      expect(
        Amenity.fromMap(
          _amenityMap({
            'available_days': ['mon'],
            'opening_time': '08:00',
          }),
        ).effectiveSchedule,
        isEmpty,
      );
      expect(
        Amenity.fromMap(
          _amenityMap({'opening_time': '08:00', 'closing_time': '09:00'}),
        ).effectiveSchedule,
        isEmpty,
      );
    });
  });

  group('AmenityImage', () {
    AmenityImage image(String id, {bool primary = false, int order = 0}) =>
        AmenityImage.fromMap({
          'id': id,
          'amenity_id': 'a1',
          'storage_path': 'p/$id',
          'is_primary': primary,
          'sort_order': order,
        });

    test('fromMap defaults', () {
      final i = AmenityImage.fromMap({
        'id': 'i',
        'amenity_id': 'a',
        'storage_path': 'x',
      });
      expect(i.isPrimary, isFalse);
      expect(i.sortOrder, 0);
    });

    test('sorted puts primary first then by sortOrder, without mutating', () {
      final input = [
        image('c', order: 2),
        image('b', order: 1),
        image('p', primary: true, order: 9),
        image('a', order: 0),
      ];
      final sorted = AmenityImage.sorted(input);
      expect(sorted.map((i) => i.id), ['p', 'a', 'b', 'c']);
      expect(input.first.id, 'c');
    });
  });

  group('AmenityBooking.fromMap', () {
    Map<String, dynamic> map({Object? status = 'confirmed', Object? amenity}) =>
        {
          'id': 'b1',
          'amenity_id': 'a1',
          'amenities': amenity ?? {'name': 'Salón'},
          'start_time': '2030-06-12T15:00:00Z',
          'end_time': '2030-06-12T16:00:00Z',
          'status': status,
          'notes': 'n',
          'rejection_reason': 'r',
        };

    test('parses fields and converts to local time', () {
      final b = AmenityBooking.fromMap(map(), imageUrl: 'http://x');
      expect(b.amenityName, 'Salón');
      expect(b.status, BookingStatus.confirmed);
      expect(b.startTime, DateTime.utc(2030, 6, 12, 15).toLocal());
      expect(b.endTime.difference(b.startTime), const Duration(hours: 1));
      expect(b.notes, 'n');
      expect(b.rejectionReason, 'r');
      expect(b.imageUrl, 'http://x');
    });

    test('unknown status falls back to pending, missing amenity name too', () {
      final b = AmenityBooking.fromMap({
        ...map(status: 'weird'),
        'amenities': null,
      });
      expect(b.status, BookingStatus.pending);
      expect(b.amenityName, 'Amenidad');
    });

    test('every known status round-trips', () {
      for (final s in BookingStatus.values) {
        expect(AmenityBooking.fromMap(map(status: s.name)).status, s);
      }
    });

    test('isUpcoming / isCancellable depend on end time and status', () {
      AmenityBooking b(Duration fromNow, BookingStatus status) =>
          AmenityBooking(
            id: 'x',
            amenityId: 'a',
            amenityName: 'n',
            startTime: DateTime.now().add(fromNow - const Duration(hours: 1)),
            endTime: DateTime.now().add(fromNow),
            status: status,
          );
      expect(
        b(const Duration(hours: 2), BookingStatus.pending).isUpcoming,
        isTrue,
      );
      expect(
        b(const Duration(hours: 2), BookingStatus.confirmed).isCancellable,
        isTrue,
      );
      expect(
        b(const Duration(hours: 2), BookingStatus.cancelled).isUpcoming,
        isFalse,
      );
      expect(
        b(const Duration(hours: 2), BookingStatus.expired).isCancellable,
        isFalse,
      );
      expect(
        b(const Duration(hours: -2), BookingStatus.confirmed).isUpcoming,
        isFalse,
      );
    });
  });

  group('AmenityBookingLimit.fromMap', () {
    test('parses known periods', () {
      for (final p in BookingLimitPeriod.values) {
        final l = AmenityBookingLimit.fromMap({
          'max_count': 2,
          'period': p.name,
        });
        expect(l.period, p);
        expect(l.maxCount, 2);
      }
    });

    test('unknown period defaults to week', () {
      final l = AmenityBookingLimit.fromMap({'max_count': 1, 'period': 'year'});
      expect(l.period, BookingLimitPeriod.week);
    });
  });

  group('AmenityBlackout', () {
    final blackout = AmenityBlackout.fromMap({
      'id': 'x',
      'amenity_id': 'a1',
      'start_date': '2030-06-20',
      'end_date': '2030-06-22',
      'reason': 'Mantenimiento',
    });

    test('fromMap parses dates and reason', () {
      expect(blackout.startDate, DateTime(2030, 6, 20));
      expect(blackout.endDate, DateTime(2030, 6, 22));
      expect(blackout.reason, 'Mantenimiento');
      expect(
        AmenityBlackout.fromMap({
          'id': 'y',
          'amenity_id': 'a',
          'start_date': '2030-01-01',
          'end_date': '2030-01-01',
        }).reason,
        isNull,
      );
    });

    test('covers is inclusive on both ends and ignores the time of day', () {
      expect(blackout.covers(DateTime(2030, 6, 19, 23, 59)), isFalse);
      expect(blackout.covers(DateTime(2030, 6, 20)), isTrue);
      expect(blackout.covers(DateTime(2030, 6, 21, 13, 30)), isTrue);
      expect(blackout.covers(DateTime(2030, 6, 22, 23, 59)), isTrue);
      expect(blackout.covers(DateTime(2030, 6, 23)), isFalse);
    });
  });

  group('Service / AmenityService', () {
    test('Service.fromMap with and without icon', () {
      expect(
        Service.fromMap({'id': 's', 'name': 'WiFi', 'icon': 'IconWifi'}).icon,
        'IconWifi',
      );
      expect(Service.fromMap({'id': 's', 'name': 'WiFi'}).icon, isNull);
    });

    test('AmenityService.fromMap reads the joined service', () {
      final s = AmenityService.fromMap({
        'is_featured': true,
        'services': {'id': 's', 'name': 'WiFi'},
      });
      expect(s.isFeatured, isTrue);
      expect(s.service.name, 'WiFi');
      expect(
        AmenityService.fromMap({
          'services': {'id': 's', 'name': 'WiFi'},
        }).isFeatured,
        isFalse,
      );
    });
  });

  group('AmenityDetails.fromMap', () {
    test('empty relations default to empty lists', () {
      final d = AmenityDetails.fromMap(_amenityMap());
      expect(d.images, isEmpty);
      expect(d.services, isEmpty);
      expect(d.bookingLimits, isEmpty);
      expect(d.blackouts, isEmpty);
      expect(d.featuredServices, isEmpty);
    });

    test('parses relations, sorts images and filters featured services', () {
      final d = AmenityDetails.fromMap(
        _amenityMap({
          'amenity_images': [
            {
              'id': 'i2',
              'amenity_id': 'a1',
              'storage_path': 'p2',
              'sort_order': 1,
            },
            {
              'id': 'i1',
              'amenity_id': 'a1',
              'storage_path': 'p1',
              'is_primary': true,
              'sort_order': 5,
            },
          ],
          'amenity_services': [
            {
              'is_featured': true,
              'services': {'id': 's1', 'name': 'WiFi'},
            },
            {
              'is_featured': false,
              'services': {'id': 's2', 'name': 'Toallas'},
            },
          ],
          'amenity_booking_limits': [
            {'max_count': 2, 'period': 'month'},
          ],
          'amenity_blackouts': [
            {
              'id': 'b',
              'amenity_id': 'a1',
              'start_date': '2030-01-01',
              'end_date': '2030-01-02',
            },
          ],
        }),
      );
      expect(d.images.map((i) => i.id), ['i1', 'i2']);
      expect(d.services, hasLength(2));
      expect(d.featuredServices.single.service.name, 'WiFi');
      expect(d.bookingLimits.single.period, BookingLimitPeriod.month);
      expect(d.blackouts.single.id, 'b');
    });
  });

  test('AmenityCard keeps the optional image url', () {
    final amenity = Amenity.fromMap(_amenityMap());
    expect(AmenityCard(amenity: amenity).imageUrl, isNull);
    expect(AmenityCard(amenity: amenity, imageUrl: 'u').imageUrl, 'u');
  });

  test('repository exceptions are plain exceptions', () {
    expect(const BookingConflictException(), isA<Exception>());
    expect(const AmenityBlackoutException(), isA<Exception>());
  });

  group('serviceIconFor', () {
    test('maps known names and falls back for unknown/null', () {
      expect(serviceIconFor('IconWifi'), TablerIcons.wifi);
      expect(serviceIconFor('IconPool'), TablerIcons.pool);
      expect(serviceIconFor('IconNope'), TablerIcons.tag);
      expect(serviceIconFor(null), TablerIcons.tag);
    });
  });
}
