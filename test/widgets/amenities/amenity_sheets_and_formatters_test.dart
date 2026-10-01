import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/amenities/domain/amenity.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking_limit.dart';
import 'package:gates_app/features/amenities/domain/amenity_image.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/amenities/presentation/amenity_bottom_sheets.dart';
import 'package:gates_app/features/amenities/presentation/amenity_formatters.dart';
import 'package:gates_app/features/amenities/presentation/booking_result_screen.dart';
import 'package:gates_app/features/amenities/presentation/review_booking_screen.dart';
import 'package:gates_app/features/amenities/presentation/booking_selection.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'amenities_test_support.dart';

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });
  tearDown(uninstallFakeImageHttp);
  final l10n = AppLocalizationsEs();

  group('formatters', () {
    test('amenityDurationLabel uses hours when exact, minutes otherwise', () {
      expect(amenityDurationLabel(l10n, 60), l10n.amenitiesDurationHours(1));
      expect(amenityDurationLabel(l10n, 180), l10n.amenitiesDurationHours(3));
      expect(amenityDurationLabel(l10n, 90), l10n.amenitiesDurationMinutes(90));
      expect(amenityDurationLabel(l10n, 45), l10n.amenitiesDurationMinutes(45));
    });

    test('payment method labels, with passthrough for unknown values', () {
      expect(
        amenityPaymentMethodLabel(l10n, 'cash'),
        l10n.amenitiesPaymentCash,
      );
      expect(
        amenityPaymentMethodLabel(l10n, 'card'),
        l10n.amenitiesPaymentCard,
      );
      expect(
        amenityPaymentMethodLabel(l10n, 'transfer'),
        l10n.amenitiesPaymentTransfer,
      );
      expect(amenityPaymentMethodLabel(l10n, 'crypto'), 'crypto');
    });

    test('booking limit label for each period', () {
      expect(
        amenityBookingLimitLabel(
          l10n,
          const AmenityBookingLimit(
            maxCount: 3,
            period: BookingLimitPeriod.month,
          ),
        ),
        l10n.amenitiesBookingLimit(3, l10n.amenitiesPeriodMonth),
      );
      expect(
        amenityBookingLimitLabel(
          l10n,
          const AmenityBookingLimit(
            maxCount: 1,
            period: BookingLimitPeriod.day,
          ),
        ),
        l10n.amenitiesBookingLimit(1, l10n.amenitiesPeriodDay),
      );
    });

    test('schedule block label maps every weekday and keeps unknown ones', () {
      final label = amenityScheduleBlockLabel(
        l10n,
        const AmenityScheduleBlock(
          days: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', 'xyz'],
          openTime: '08:00:00',
          closeTime: '09:00',
        ),
      );
      expect(
        label,
        '${l10n.amenitiesDayMon}, ${l10n.amenitiesDayTue}, '
        '${l10n.amenitiesDayWed}, ${l10n.amenitiesDayThu}, '
        '${l10n.amenitiesDayFri}, ${l10n.amenitiesDaySat}, '
        '${l10n.amenitiesDaySun}, xyz 08:00-09:00',
      );
    });

    group('blackout labels', () {
      AmenityBlackout blackout({DateTime? end, String? reason}) =>
          AmenityBlackout(
            id: 'b',
            amenityId: 'a',
            startDate: DateTime(2030, 10, 12),
            endDate: end ?? DateTime(2030, 10, 14),
            reason: reason,
          );

      test('range without reason', () {
        expect(
          amenityBlackoutLabel(l10n, blackout()),
          anyOf('12 oct – 14 oct', '12 oct. – 14 oct.'),
        );
      });

      test('single day collapses the range', () {
        final label = amenityBlackoutLabel(
          l10n,
          blackout(end: DateTime(2030, 10, 12)),
        );
        expect(label, isNot(contains('–')));
        expect(label, contains('12'));
      });

      test('reason variants (empty reason counts as none)', () {
        final range = amenityBlackoutLabel(l10n, blackout());
        expect(
          amenityBlackoutLabel(l10n, blackout(reason: 'Pintura')),
          l10n.amenitiesBlackoutWithReason(range, 'Pintura'),
        );
        expect(amenityBlackoutLabel(l10n, blackout(reason: '')), range);
      });

      test('sheet label with and without the "Cerrado" prefix', () {
        final plain = blackout();
        final range = amenityBlackoutLabel(l10n, plain);
        expect(
          amenityBlackoutSheetLabel(l10n, plain),
          l10n.amenitiesBlackoutClosed(range),
        );
        expect(
          amenityBlackoutSheetLabel(l10n, plain, withPrefix: false),
          range,
        );
        final withReason = blackout(reason: 'Pintura');
        expect(
          amenityBlackoutSheetLabel(l10n, withReason),
          l10n.amenitiesBlackoutClosedWithReason(range, 'Pintura'),
        );
        expect(
          amenityBlackoutSheetLabel(l10n, withReason, withPrefix: false),
          l10n.amenitiesBlackoutRangeWithReason(range, 'Pintura'),
        );
      });
    });
  });

  group('providers', () {
    test('blackouts and gallery urls come from the repository', () async {
      final repository = FakeAmenitiesRepository()
        ..details = {
          'a1': makeDetails(
            images: const [
              AmenityImage(
                id: 'i1',
                amenityId: 'a1',
                storagePath: 'p1',
                isPrimary: true,
                sortOrder: 0,
              ),
              AmenityImage(
                id: 'i2',
                amenityId: 'a1',
                storagePath: 'unsigned',
                isPrimary: false,
                sortOrder: 1,
              ),
            ],
            blackouts: [
              AmenityBlackout(
                id: 'b',
                amenityId: 'a1',
                startDate: DateTime(2030, 1, 1),
                endDate: DateTime(2030, 1, 2),
              ),
            ],
          ),
        }
        ..signed = {'p1': 'https://img.test/1.png'};
      final container = ProviderContainer(
        overrides: [amenitiesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(amenityBlackoutsProvider('a1').future)).single.id,
        'b',
      );
      // Images whose URL could not be signed are skipped.
      expect(await container.read(amenityGalleryUrlsProvider('a1').future), [
        'https://img.test/1.png',
      ]);
    });
  });

  group('cost details sheet', () {
    Future<void> open(
      WidgetTester tester,
      Future<void> Function(BuildContext) show,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('paid amenity lists price, duration and methods', (
      tester,
    ) async {
      final amenity = makeAmenity(
        requiresPayment: true,
        price: 80,
        paymentMethods: const ['card', 'cash'],
        duration: 120,
      );
      await open(tester, (c) => showCostDetailsSheet(c, amenity));
      expect(find.text(l10n.amenitiesCostHeading), findsOneWidget);
      expect(find.text(r'$80.00'), findsOneWidget);
      expect(
        find.text(l10n.amenitiesPerBookingOf(l10n.amenitiesDurationHours(2))),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.amenitiesPaymentCard} · ${l10n.amenitiesPaymentCash}',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.amenitiesCostInfoNote), findsOneWidget);
    });

    testWidgets('free amenity only says there is no cost', (tester) async {
      final amenity = makeAmenity(
        price: 80, // ignored without requiresPayment
        paymentMethods: const ['cash'],
      );
      await open(tester, (c) => showCostDetailsSheet(c, amenity));
      expect(find.text(l10n.amenitiesNoCost), findsOneWidget);
      expect(find.text(l10n.amenitiesAcceptedMethods), findsNothing);
      expect(find.text(r'$80.00'), findsNothing);
    });

    testWidgets('amenity without any price', (tester) async {
      await open(tester, (c) => showCostDetailsSheet(c, makeAmenity()));
      expect(find.text(l10n.amenitiesNoCost), findsOneWidget);
    });
  });

  group('thumbnails with a signed photo', () {
    testWidgets('review and result screens render the amenity photo', (
      tester,
    ) async {
      installFakeImageHttp();
      final repository = FakeAmenitiesRepository()
        ..details = {
          'a1': makeDetails(
            images: const [
              AmenityImage(
                id: 'i1',
                amenityId: 'a1',
                storagePath: 'p1',
                isPrimary: true,
                sortOrder: 0,
              ),
            ],
          ),
        }
        ..signed = {'p1': 'https://img.test/1.png'};
      final args = ReviewBookingArgs(
        details: repository.details['a1']!,
        selection: BookingSelection(
          day: DateTime(2030, 6, 12),
          start: const TimeOfDay(hour: 15, minute: 0),
          end: const TimeOfDay(hour: 16, minute: 0),
        ),
      );
      await pumpApp(
        tester,
        ReviewBookingScreen(args: args),
        overrides: amenitiesOverrides(repository),
        settle: false,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsOneWidget);

      await pumpApp(
        tester,
        BookingResultScreen(
          args: BookingResultArgs(
            amenity: args.details.amenity,
            booking: makeBooking('r', status: BookingStatus.confirmed),
          ),
        ),
        overrides: amenitiesOverrides(repository),
        settle: false,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsOneWidget);
      expect(HttpOverrides.current, isNotNull);
    });
  });
}
