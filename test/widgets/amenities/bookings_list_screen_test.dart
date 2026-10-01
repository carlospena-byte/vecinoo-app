import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/presentation/bookings_list_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'amenities_test_support.dart';

void main() {
  setUpAll(loadManrope);
  final l10n = AppLocalizationsEs();

  late FakeAmenitiesRepository repository;
  setUp(() => repository = FakeAmenitiesRepository());

  Future<void> pump(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
    List<String>? visited,
    bool settle = true,
  }) => pumpApp(
    tester,
    const BookingsListScreen(),
    overrides: amenitiesOverrides(repository),
    mode: mode,
    visited: visited,
    settle: settle,
    routes: {'/amenities': (_) => const Text('new booking flow')},
  );

  final soon = DateTime.now().add(const Duration(days: 3));
  final past = DateTime.now().subtract(const Duration(days: 5));

  List<AmenityBooking> sample() => [
    makeBooking('p', name: 'Pendiente A', start: soon),
    makeBooking(
      'c',
      name: 'Confirmada B',
      start: soon,
      status: BookingStatus.confirmed,
    ),
    makeBooking(
      'x',
      name: 'Cancelada C',
      start: soon,
      status: BookingStatus.cancelled,
    ),
    makeBooking(
      'e',
      name: 'Expirada D',
      start: past,
      status: BookingStatus.expired,
    ),
    makeBooking(
      'o',
      name: 'Pasada E',
      start: past,
      status: BookingStatus.confirmed,
    ),
  ];

  testWidgets('loading then error with retry', (tester) async {
    repository.bookingsError = const ServerFailure();
    await pump(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(l10n.amenitiesBookingsLoadError), findsOneWidget);
    expect(find.text(l10n.amenitiesTabPending), findsNothing);

    repository.bookingsError = null;
    repository.bookings = sample();
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('Pendiente A'), findsOneWidget);
  });

  testWidgets('empty state per tab', (tester) async {
    await pump(tester);
    expect(find.text(l10n.amenitiesEmptyPending), findsOneWidget);
    await tester.tap(find.text(l10n.amenitiesTabConfirmed));
    await tester.pumpAndSettle();
    expect(find.text(l10n.amenitiesEmptyConfirmed), findsOneWidget);
    await tester.tap(find.text(l10n.amenitiesTabHistory));
    await tester.pumpAndSettle();
    expect(find.text(l10n.amenitiesEmptyHistory), findsOneWidget);
  });

  testWidgets('tabs filter pending / confirmed / history', (tester) async {
    repository.bookings = sample();
    await pump(tester);
    expect(find.text('Pendiente A'), findsOneWidget);
    expect(find.text('Confirmada B'), findsNothing);
    expect(find.text(l10n.amenitiesStatusPending), findsOneWidget);

    await tester.tap(find.text(l10n.amenitiesTabConfirmed));
    await tester.pumpAndSettle();
    expect(find.text('Confirmada B'), findsOneWidget);
    expect(find.text('Pendiente A'), findsNothing);

    await tester.tap(find.text(l10n.amenitiesTabHistory));
    await tester.pumpAndSettle();
    expect(find.text('Cancelada C'), findsOneWidget);
    expect(find.text('Expirada D'), findsOneWidget);
    expect(find.text('Pasada E'), findsOneWidget);
    expect(find.text(l10n.amenitiesStatusCancelled), findsOneWidget);
    expect(find.text(l10n.amenitiesStatusExpired), findsOneWidget);
  });

  testWidgets('cards show a formatted date and time range', (tester) async {
    repository.bookings = [
      makeBooking('p', start: DateTime.now().add(const Duration(days: 400))),
    ];
    // Fixed far-future day so the Spanish label is predictable.
    repository.bookings = [
      makeBooking('p', start: DateTime(2099, 10, 17, 9, 30)),
    ];
    await pump(tester);
    expect(find.textContaining('Sáb 17 oct 2099'), findsOneWidget);
    expect(find.textContaining('09:30–10:30'), findsOneWidget);
  });

  testWidgets('the add button opens the new booking flow', (tester) async {
    final visited = <String>[];
    await pump(tester, visited: visited);
    await tester.tap(find.bySemanticsLabel(l10n.amenitiesNewBooking));
    await tester.pumpAndSettle();
    expect(visited, ['/amenities']);
  });

  testWidgets('pull to refresh refetches', (tester) async {
    repository.bookings = sample();
    await pump(tester);
    expect(repository.bookingFetches, 1);
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repository.bookingFetches, 2);
  });

  testWidgets('dark theme smoke', (tester) async {
    repository.bookings = sample();
    await pump(tester, mode: ThemeMode.dark);
    expect(find.text('Pendiente A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('booking detail sheet', () {
    Future<void> open(WidgetTester tester, String name) async {
      await pump(tester);
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    testWidgets('pending booking shows details, reason field and swipe', (
      tester,
    ) async {
      repository.bookings = [
        makeBooking(
          'p',
          name: 'Pendiente A',
          start: DateTime(2099, 10, 17, 9, 30),
          length: const Duration(minutes: 90),
        ),
      ];
      await open(tester, 'Pendiente A');
      expect(find.text(l10n.amenitiesBookingDetailTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesPendingConfirmation), findsOneWidget);
      expect(find.text(l10n.amenitiesSpace), findsOneWidget);
      expect(find.text('Sábado 17 de octubre de 2099'), findsOneWidget);
      expect(find.text('09:30–11:00 · 90 minutos'), findsOneWidget);
      expect(find.text(l10n.amenitiesReasonOptional), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.amenitiesSwipeToCancel), findsOne);

      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesBookingDetailTitle), findsNothing);
    });

    testWidgets('swiping cancels with the typed reason and closes', (
      tester,
    ) async {
      repository.bookings = [makeBooking('p', name: 'Pendiente A')];
      await open(tester, 'Pendiente A');
      await tester.enterText(find.byType(TextField), 'Ya no puedo');
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(600, 0),
      );
      await tester.pumpAndSettle();
      expect(repository.cancelled, [('p', 'Ya no puedo')]);
      expect(find.text(l10n.amenitiesBookingDetailTitle), findsNothing);
      // The list was refreshed after the cancellation.
      expect(repository.bookingFetches, 2);
    });

    testWidgets('semantics tap on the swipe track also cancels', (
      tester,
    ) async {
      repository.bookings = [makeBooking('p', name: 'Pendiente A')];
      final handle = tester.ensureSemantics();
      await open(tester, 'Pendiente A');
      tester.semantics.tap(find.semantics.byLabel(l10n.amenitiesSwipeToCancel));
      await tester.pumpAndSettle();
      expect(repository.cancelled, [('p', '')]);
      handle.dispose();
    });

    testWidgets('a failed cancel shows a toast with the cause and recovers', (
      tester,
    ) async {
      repository.bookings = [makeBooking('p', name: 'Pendiente A')];
      repository.cancelError = const NetworkFailure();
      await open(tester, 'Pendiente A');
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(600, 0),
      );
      // Render the in-flight frame: the thumb locks and shows a spinner.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesCancelFailedTitle), findsOneWidget);
      expect(
        find.text('${l10n.commonErrorNetwork} ${l10n.amenitiesTryAgain}'),
        findsOneWidget,
      );
      // Let the toast expire so it no longer covers the sheet.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // Sheet is still open and the thumb is usable again.
      expect(find.text(l10n.amenitiesBookingDetailTitle), findsOneWidget);

      repository.cancelError = null;
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(600, 0),
      );
      await tester.pumpAndSettle();
      expect(repository.cancelled, hasLength(1));
    });

    testWidgets('unknown failures fall back to the plain retry hint', (
      tester,
    ) async {
      repository.bookings = [makeBooking('p', name: 'Pendiente A')];
      repository.cancelError = StateError('x');
      await open(tester, 'Pendiente A');
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesTryAgain), findsOneWidget);
    });

    testWidgets('cancelled booking shows the reason and cannot be cancelled', (
      tester,
    ) async {
      repository.bookings = [
        makeBooking(
          'x',
          name: 'Cancelada C',
          status: BookingStatus.cancelled,
          reason: 'Mantenimiento imprevisto',
        ),
      ];
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesTabHistory));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelada C'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesPillCancelled), findsOneWidget);
      expect(find.text(l10n.amenitiesReason), findsOneWidget);
      expect(find.text('Mantenimiento imprevisto'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.bySemanticsLabel(l10n.amenitiesSwipeToCancel), findsNothing);
    });

    testWidgets('confirmed upcoming / past / expired pills', (tester) async {
      repository.bookings = [
        makeBooking('c', name: 'Conf', status: BookingStatus.confirmed),
        makeBooking(
          'o',
          name: 'Pasada',
          start: past,
          status: BookingStatus.confirmed,
        ),
        makeBooking(
          'e',
          name: 'Exp',
          start: past.subtract(const Duration(days: 1)),
          status: BookingStatus.expired,
        ),
      ];
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesTabConfirmed));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conf'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesPillConfirmed), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.amenitiesTabHistory));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasada'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesPillPast), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exp'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesPillExpired), findsOneWidget);
    });
  });
}
