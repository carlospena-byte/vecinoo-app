import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/domain/amenity.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking_limit.dart';
import 'package:gates_app/features/amenities/domain/amenity_image.dart';
import 'package:gates_app/features/amenities/domain/service.dart';
import 'package:gates_app/features/amenities/presentation/amenity_detail_screen.dart';
import 'package:gates_app/features/amenities/presentation/review_booking_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'amenities_test_support.dart';

AmenityImage _image(String id, {bool primary = false, int order = 0}) =>
    AmenityImage(
      id: id,
      amenityId: 'a1',
      storagePath: 'path/$id',
      isPrimary: primary,
      sortOrder: order,
    );

AmenityService _service(String name, {bool featured = false, String? icon}) =>
    AmenityService(
      service: Service(id: name, name: name, icon: icon),
      isFeatured: featured,
    );

/// Lets real image decoding (which runs outside fake async) finish.
Future<void> settleImages(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadManrope);
  final l10n = AppLocalizationsEs();

  late FakeAmenitiesRepository repository;
  setUp(() => repository = FakeAmenitiesRepository());
  tearDown(uninstallFakeImageHttp);

  Future<void> pump(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
    List<String>? visited,
    bool settle = true,
    Object? extraSink,
  }) => pumpApp(
    tester,
    const AmenityDetailScreen(amenityId: 'a1'),
    overrides: amenitiesOverrides(repository, clock: DateTime.now),
    mode: mode,
    visited: visited,
    settle: settle,
    routes: {'/amenities/:id/review': (_) => const Text('review step')},
  );

  Amenity rich() => makeAmenity(
    name: 'Salón de eventos',
    description: '<p>Un lugar <b>amplio</b> para fiestas</p>',
    location: 'Torre A, planta baja',
    capacity: 40,
    terms: '<p>No se permiten mascotas</p>',
    requiresPayment: true,
    price: 1250,
    paymentMethods: const ['cash', 'transfer', 'bitcoin'],
    duration: 120,
    schedule: const [
      AmenityScheduleBlock(
        days: ['mon', 'tue'],
        openTime: '08:00:00',
        closeTime: '20:00:00',
      ),
      AmenityScheduleBlock(
        days: ['sat', 'sun'],
        openTime: '10:00',
        closeTime: '14:00',
      ),
    ],
  );

  void seed(AmenityDetailsFactory f) => repository.details = {'a1': f()};

  group('states', () {
    testWidgets('loading spinner', (tester) async {
      seed(() => makeDetails());
      await pump(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('error with retry', (tester) async {
      repository.detailsError = const ServerFailure();
      await pump(tester);
      expect(find.text(l10n.amenitiesDetailLoadError), findsOneWidget);
      repository.detailsError = null;
      seed(() => makeDetails(amenity: makeAmenity(name: 'Gimnasio')));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('Gimnasio'), findsOneWidget);
    });
  });

  group('content', () {
    testWidgets('renders every section of a full amenity', (tester) async {
      seed(
        () => makeDetails(
          amenity: rich(),
          services: [
            _service('WiFi', featured: true, icon: 'IconWifi'),
            _service('Alberca', featured: true, icon: 'IconPool'),
            _service('Toallas'),
          ],
          limits: const [
            AmenityBookingLimit(maxCount: 2, period: BookingLimitPeriod.week),
            AmenityBookingLimit(maxCount: 1, period: BookingLimitPeriod.day),
          ],
          blackouts: [
            AmenityBlackout(
              id: 'b',
              amenityId: 'a1',
              startDate: DateTime(2030, 10, 12),
              endDate: DateTime(2030, 10, 14),
              reason: 'Mantenimiento',
            ),
            AmenityBlackout(
              id: 'c',
              amenityId: 'a1',
              startDate: DateTime(2030, 12, 25),
              endDate: DateTime(2030, 12, 25),
            ),
          ],
        ),
      );
      await pump(tester);

      expect(find.text(l10n.amenitiesDetailTitle), findsOneWidget);
      expect(find.text('Salón de eventos'), findsOneWidget);
      expect(find.text('Torre A, planta baja'), findsOneWidget);
      expect(
        find.text(
          '${l10n.amenitiesCapacity(40)} · ${l10n.amenitiesBookingRequired}',
        ),
        findsOneWidget,
      );
      // Featured services only, with their icons.
      expect(find.text(l10n.amenitiesOffersHeading), findsOneWidget);
      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('Alberca'), findsOneWidget);
      expect(find.text('Toallas'), findsNothing);
      expect(find.byIcon(TablerIcons.wifi), findsOneWidget);
      expect(find.byIcon(TablerIcons.pool), findsOneWidget);
      // Description is rendered HTML.
      expect(find.text(l10n.amenitiesAboutHeading), findsOneWidget);
      expect(find.textContaining('Un lugar', findRichText: true), findsOne);
      // Schedule, one line per block.
      expect(find.text(l10n.amenitiesScheduleHeading), findsOneWidget);
      expect(
        find.text(
          '${l10n.amenitiesDayMon}, ${l10n.amenitiesDayTue} 08:00-20:00',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.amenitiesDaySat}, ${l10n.amenitiesDaySun} 10:00-14:00',
        ),
        findsOneWidget,
      );

      // Booking rules.
      await tester.ensureVisible(find.text(l10n.amenitiesClosedDates));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesBeforeBookingHeading), findsOneWidget);
      expect(find.text(l10n.amenitiesDurationPerBooking), findsOneWidget);
      expect(find.text(l10n.amenitiesDurationHours(2)), findsWidgets);
      expect(find.text(l10n.amenitiesLimitPerResident), findsOneWidget);
      expect(
        find.text(l10n.amenitiesBookingLimit(2, l10n.amenitiesPeriodWeek)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.amenitiesBookingLimit(1, l10n.amenitiesPeriodDay)),
        findsOneWidget,
      );
      expect(find.textContaining('Mantenimiento'), findsOneWidget);

      // Cost.
      await tester.ensureVisible(find.text(l10n.amenitiesAcceptedMethods));
      await tester.pumpAndSettle();
      expect(find.text(r'$1,250.00'), findsWidgets);
      expect(
        find.text(l10n.amenitiesPerBookingOf(l10n.amenitiesDurationHours(2))),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.amenitiesPaymentCash} · ${l10n.amenitiesPaymentTransfer} · bitcoin',
        ),
        findsOneWidget,
      );
      // Fixed action bar.
      expect(find.text(l10n.amenitiesPickDate), findsOneWidget);
      expect(
        find.text(
          l10n.amenitiesPerBookingDuration(l10n.amenitiesDurationHours(2)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"view all services" opens the full list sheet', (
      tester,
    ) async {
      seed(
        () => makeDetails(
          services: [
            _service('WiFi', featured: true, icon: 'IconWifi'),
            _service('Toallas'),
            _service('Sillas', icon: 'IconArmchair'),
          ],
        ),
      );
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesViewAllServices));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesAllServices), findsOneWidget);
      expect(find.text('Toallas'), findsOneWidget);
      expect(find.text('Sillas'), findsOneWidget);
      expect(find.byIcon(TablerIcons.armchair), findsOneWidget);
      expect(find.byIcon(TablerIcons.tag), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesAllServices), findsNothing);
    });

    testWidgets('without featured services all of them are listed', (
      tester,
    ) async {
      seed(
        () => makeDetails(services: [_service('Toallas'), _service('Sillas')]),
      );
      await pump(tester);
      expect(find.text('Toallas'), findsOneWidget);
      expect(find.text('Sillas'), findsOneWidget);
      expect(find.text(l10n.amenitiesViewAllServices), findsNothing);
    });

    testWidgets('free-access amenity has no booking rules, cost or CTA', (
      tester,
    ) async {
      seed(
        () => makeDetails(
          amenity: makeAmenity(
            name: 'Jardín',
            requiresBooking: false,
            terms: '<p>Respeta el césped</p>',
          ),
        ),
      );
      await pump(tester);
      expect(find.text(l10n.amenitiesFreeAccess), findsOneWidget);
      expect(find.text(l10n.amenitiesBeforeBookingHeading), findsNothing);
      expect(find.text(l10n.amenitiesCostHeading), findsNothing);
      expect(find.text(l10n.amenitiesPickDate), findsNothing);
      expect(find.text(l10n.amenitiesTerms), findsOneWidget);
    });

    testWidgets('free bookable amenity says there is no cost', (tester) async {
      seed(() => makeDetails(amenity: makeAmenity(duration: null)));
      await pump(tester);
      expect(find.text(l10n.amenitiesNoCost), findsNWidgets(2));
      expect(find.text(l10n.amenitiesPerBooking), findsOneWidget);
      expect(find.text(l10n.amenitiesDurationPerBooking), findsNothing);
      expect(find.text(l10n.amenitiesLimitPerResident), findsNothing);
      expect(find.text(l10n.amenitiesClosedDates), findsNothing);
    });

    testWidgets('terms button opens the terms sheet', (tester) async {
      seed(() => makeDetails(amenity: rich()));
      await pump(tester);
      await tester.ensureVisible(find.text(l10n.amenitiesTerms));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.amenitiesTerms));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se permiten mascotas', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.textContaining('mascotas', findRichText: true), findsNothing);
    });

    testWidgets('dark theme smoke', (tester) async {
      seed(
        () => makeDetails(
          amenity: rich(),
          services: [_service('WiFi', featured: true)],
        ),
      );
      await pump(tester, mode: ThemeMode.dark);
      expect(find.text('Salón de eventos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('gallery', () {
    testWidgets('no photos shows the placeholder', (tester) async {
      seed(() => makeDetails());
      await pump(tester);
      expect(find.byIcon(TablerIcons.buildingCommunity), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('photos that fail to sign show the placeholder', (
      tester,
    ) async {
      seed(() => makeDetails(images: [_image('i1', primary: true)]));
      repository.signed = {};
      await pump(tester);
      expect(find.byIcon(TablerIcons.buildingCommunity), findsOneWidget);
    });

    testWidgets('a signing error shows the broken-image placeholder', (
      tester,
    ) async {
      seed(() => makeDetails(images: [_image('i1')]));
      repository.signError = const NetworkFailure();
      await pump(tester);
      expect(find.byIcon(TablerIcons.photoOff), findsOneWidget);
    });

    testWidgets('pages through photos and opens the full-screen viewer', (
      tester,
    ) async {
      installFakeImageHttp();
      seed(
        () => makeDetails(
          images: [_image('i1', primary: true), _image('i2', order: 1)],
        ),
      );
      repository.signed = {
        'path/i1': 'https://img.test/1.png',
        'path/i2': 'https://img.test/2.png',
      };
      final handle = tester.ensureSemantics();
      await pump(tester, settle: false);
      await settleImages(tester);

      expect(find.text('1 / 2'), findsOneWidget);
      expect(
        find.bySemanticsLabel(l10n.amenitiesPhotoLabel(1, 2)),
        findsOneWidget,
      );

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await settleImages(tester);
      expect(find.text('2 / 2'), findsOneWidget);

      await tester.tap(find.byType(Image).last);
      await settleImages(tester);
      expect(find.byType(InteractiveViewer), findsWidgets);
      expect(find.text(l10n.amenitiesDetailTitle), findsNothing);

      // Back from the viewer returns to the detail.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesDetailTitle), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a single photo has no page counter', (tester) async {
      installFakeImageHttp();
      seed(() => makeDetails(images: [_image('i1')]));
      repository.signed = {'path/i1': 'https://img.test/1.png'};
      await pump(tester, settle: false);
      await settleImages(tester);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1 / 1'), findsNothing);
    });
  });

  group('booking CTA', () {
    testWidgets('picking a date forwards to the review step', (tester) async {
      seed(() => makeDetails());
      final visited = <String>[];
      await pump(tester, visited: visited);
      await tester.tap(find.text(l10n.amenitiesPickDate));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesDateTimeTitle), findsOneWidget);
      await tester.tap(find.text(l10n.amenitiesContinue));
      await tester.pumpAndSettle();
      expect(visited, ['/amenities/a1/review']);
      expect(find.text('review step'), findsOneWidget);
    });

    testWidgets('dismissing the picker stays on the detail', (tester) async {
      seed(() => makeDetails());
      final visited = <String>[];
      await pump(tester, visited: visited);
      await tester.tap(find.text(l10n.amenitiesPickDate));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();
      expect(visited, isEmpty);
      expect(find.text(l10n.amenitiesPickDate), findsOneWidget);
    });

    testWidgets('the review route receives the details and selection', (
      tester,
    ) async {
      seed(() => makeDetails());
      Object? extra;
      usePhoneSurface(tester);
      await pumpApp(
        tester,
        const AmenityDetailScreen(amenityId: 'a1'),
        overrides: amenitiesOverrides(repository, clock: DateTime.now),
        routes: {
          '/amenities/:id/review': (state) {
            extra = state.extra;
            return const Text('review step');
          },
        },
      );
      await tester.tap(find.text(l10n.amenitiesPickDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.amenitiesContinue));
      await tester.pumpAndSettle();
      final args = extra! as ReviewBookingArgs;
      expect(args.details.amenity.id, 'a1');
      expect(args.selection.start, const TimeOfDay(hour: 9, minute: 0));
      expect(args.selection.end, const TimeOfDay(hour: 10, minute: 0));
    });
  });

  testWidgets('the back button pops the screen', (tester) async {
    seed(() => makeDetails());
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AmenityDetailScreen(amenityId: 'a1'),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
      overrides: amenitiesOverrides(repository, clock: DateTime.now),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.amenitiesDetailTitle), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.amenitiesBack));
    await tester.pumpAndSettle();
    expect(find.text('go'), findsOneWidget);
  });
}

typedef AmenityDetailsFactory = dynamic Function();
