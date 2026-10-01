import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/domain/amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/presentation/booking_result_screen.dart';
import 'package:gates_app/features/amenities/presentation/review_booking_screen.dart';
import 'package:gates_app/features/amenities/presentation/booking_selection.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'amenities_test_support.dart';

void main() {
  setUpAll(loadManrope);
  final l10n = AppLocalizationsEs();

  late FakeAmenitiesRepository repository;
  // Args are provider-family keys (identity equality): keep one instance.
  late ReviewBookingArgs defaultArgs;
  setUp(() {
    repository = FakeAmenitiesRepository()..details = {'a1': makeDetails()};
    defaultArgs = ReviewBookingArgs(
      details: makeDetails(),
      selection: BookingSelection(
        day: DateTime(2030, 6, 12),
        start: const TimeOfDay(hour: 15, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
      ),
    );
  });

  BookingSelection selection({
    DateTime? day,
    TimeOfDay start = const TimeOfDay(hour: 15, minute: 0),
    TimeOfDay end = const TimeOfDay(hour: 16, minute: 0),
  }) => BookingSelection(
    day: day ?? DateTime(2030, 6, 12),
    start: start,
    end: end,
  );

  Future<void> pump(
    WidgetTester tester, {
    ReviewBookingArgs? args,
    ThemeMode mode = ThemeMode.light,
    DateTime Function()? clock,
    List<String>? visited,
    void Function(Object?)? onResult,
  }) => pumpApp(
    tester,
    // The app has the membership loaded long before this screen opens.
    Consumer(
      builder: (context, ref, _) {
        ref.watch(selectedMembershipProvider);
        return ReviewBookingScreen(args: args ?? defaultArgs);
      },
    ),
    overrides: amenitiesOverrides(repository, clock: clock),
    mode: mode,
    visited: visited,
    routes: {
      '/amenities/:id/result': (state) {
        onResult?.call(state.extra);
        return const Text('result screen');
      },
    },
  );

  ReviewBookingArgs argsFor({
    double? price,
    String? terms,
    String? location,
    BookingSelection? sel,
    int? duration = 60,
  }) => ReviewBookingArgs(
    details: makeDetails(
      amenity: makeAmenity(
        price: price,
        requiresPayment: price != null,
        terms: terms,
        location: location,
        duration: duration,
      ),
    ),
    selection: sel ?? selection(),
  );

  group('summary', () {
    testWidgets('shows amenity, date, schedule, cost and notes rows', (
      tester,
    ) async {
      await pump(tester, args: argsFor(location: 'Torre A'));
      expect(find.text(l10n.amenitiesReviewTitle), findsOneWidget);
      expect(find.text('Salón de eventos'), findsOneWidget);
      expect(find.text('Torre A'), findsOneWidget);
      expect(find.textContaining('12 jun 2030'), findsOneWidget);
      expect(find.text('15:00–16:00 · 1 hora'), findsOneWidget);
      expect(find.text(l10n.amenitiesNoCost), findsOneWidget);
      expect(find.text(l10n.amenitiesNoNotes), findsOneWidget);
      expect(find.text(l10n.amenitiesCancelFutureHint), findsOneWidget);
      expect(find.text(l10n.amenitiesTerms), findsNothing);
      expect(find.byIcon(TablerIcons.buildingCommunity), findsOneWidget);
    });

    testWidgets('paid amenity shows its price; 90 minutes label', (
      tester,
    ) async {
      await pump(
        tester,
        args: argsFor(
          price: 99.5,
          sel: selection(end: const TimeOfDay(hour: 16, minute: 30)),
        ),
      );
      expect(find.text(r'$99.50'), findsOneWidget);
      expect(
        find.text('15:00–16:30 · ${l10n.amenitiesDurationMinutes(90)}'),
        findsOneWidget,
      );
    });

    testWidgets('dark theme smoke', (tester) async {
      await pump(
        tester,
        mode: ThemeMode.dark,
        args: argsFor(terms: 'x'),
      );
      expect(find.text(l10n.amenitiesReviewTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('terms button opens the terms sheet', (tester) async {
      await pump(tester, args: argsFor(terms: '<p>Sin fiestas ruidosas</p>'));
      await tester.tap(find.text(l10n.amenitiesTerms));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sin fiestas ruidosas', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('notes', () {
    testWidgets('saving a note shows it and sends it', (tester) async {
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesEdit));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesNotesHint), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Cumpleaños  ');
      await tester.tap(find.text(l10n.amenitiesSave));
      await tester.pumpAndSettle();
      expect(find.text('Cumpleaños'), findsOneWidget);
      expect(find.text(l10n.amenitiesNoNotes), findsNothing);

      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(repository.created.single.notes, 'Cumpleaños');
    });

    testWidgets('cancelling the sheet keeps the notes unchanged', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'descartada');
      await tester.tap(find.text(l10n.amenitiesCancel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesNoNotes), findsOneWidget);
    });

    testWidgets('clearing existing notes goes back to "no notes"', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'algo');
      await tester.tap(find.text(l10n.amenitiesSave));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.amenitiesEdit));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'algo'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text(l10n.amenitiesSave));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesNoNotes), findsOneWidget);
    });
  });

  group('change date and time', () {
    testWidgets('the new selection replaces the summary', (tester) async {
      // The calendar range follows the real clock.
      final day = DateTime.now().add(const Duration(days: 3));
      await pump(
        tester,
        clock: DateTime.now,
        args: ReviewBookingArgs(
          details: makeDetails(),
          selection: selection(day: DateTime(day.year, day.month, day.day)),
        ),
      );
      await tester.tap(find.text(l10n.amenitiesChange).first);
      await tester.pumpAndSettle();
      // Sheet opens with "Guardar" as its primary action.
      expect(find.text(l10n.amenitiesDateTimeTitle), findsOneWidget);
      await tester.tap(find.text(l10n.amenitiesStart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.amenitiesSave));
      await tester.pumpAndSettle();
      // 15:00 start was re-picked unchanged and the 1h duration persists.
      expect(find.text('15:00–16:00 · 1 hora'), findsOneWidget);
    });

    testWidgets('closing the sheet leaves the selection', (tester) async {
      final day = DateTime.now().add(const Duration(days: 3));
      await pump(
        tester,
        clock: DateTime.now,
        args: ReviewBookingArgs(
          details: makeDetails(),
          selection: selection(day: DateTime(day.year, day.month, day.day)),
        ),
      );
      await tester.tap(find.text(l10n.amenitiesChange).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.amenitiesClose));
      await tester.pumpAndSettle();
      expect(find.text('15:00–16:00 · 1 hora'), findsOneWidget);
    });
  });

  group('confirm', () {
    testWidgets('success moves to the result screen with the booking', (
      tester,
    ) async {
      Object? extra;
      final visited = <String>[];
      await pump(tester, visited: visited, onResult: (e) => extra = e);
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(repository.created.single.unitId, 'unit-1');
      expect(repository.created.single.start, DateTime(2030, 6, 12, 15));
      expect(repository.created.single.end, DateTime(2030, 6, 12, 16));
      expect(visited, ['/amenities/a1/result']);
      expect(find.text('result screen'), findsOneWidget);
      final args = extra! as BookingResultArgs;
      expect(args.booking.id, 'new-1');
      expect(args.amenity.id, 'a1');
    });

    testWidgets('past dates show an inline error and call nothing', (
      tester,
    ) async {
      await pump(
        tester,
        args: ReviewBookingArgs(
          details: makeDetails(),
          selection: selection(day: DateTime(2030, 6, 9)),
        ),
      );
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorPastDateTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesErrorPastDateMessage), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('end not after start shows the schedule error', (tester) async {
      await pump(
        tester,
        args: argsFor(
          sel: selection(end: const TimeOfDay(hour: 15, minute: 0)),
        ),
      );
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorScheduleTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesEndAfterStartError), findsOneWidget);
    });

    testWidgets('slot conflict keeps the screen with a conflict banner', (
      tester,
    ) async {
      repository.createError = const BookingConflictException();
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorConflictTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesErrorConflictMessage), findsOneWidget);
      expect(find.text('result screen'), findsNothing);
    });

    testWidgets('blackout rejection shows the closed-date banner', (
      tester,
    ) async {
      repository.createError = const AmenityBlackoutException();
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorBlackoutTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesErrorBlackoutMessage), findsOneWidget);
    });

    testWidgets('network failure includes its cause; retry works', (
      tester,
    ) async {
      repository.createError = const NetworkFailure();
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorSubmitTitle), findsOneWidget);
      expect(
        find.text(
          '${l10n.commonErrorNetwork} ${l10n.amenitiesErrorSubmitMessage}',
        ),
        findsOneWidget,
      );

      repository.createError = null;
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text('result screen'), findsOneWidget);
    });

    testWidgets('unknown failure falls back to the generic message', (
      tester,
    ) async {
      repository.createError = StateError('boom');
      await pump(tester);
      await tester.tap(find.text(l10n.amenitiesConfirmBooking));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesErrorSubmitMessage), findsOneWidget);
    });
  });

  group('BookingResultScreen', () {
    Future<void> pumpResult(
      WidgetTester tester,
      BookingStatus status, {
      String? notes,
      ThemeMode mode = ThemeMode.light,
    }) async {
      final amenity = makeAmenity(location: 'Torre B');
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/result'),
              child: const Text('home'),
            ),
          ),
        ),
        routes: {
          '/result': (_) => BookingResultScreen(
            args: BookingResultArgs(
              amenity: amenity,
              booking: makeBooking(
                'r1',
                start: DateTime(2030, 6, 12, 15),
                status: status,
                notes: notes,
              ),
            ),
          ),
        },
        mode: mode,
        overrides: amenitiesOverrides(repository),
      );
      await tester.tap(find.text('home'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirmed copy, summary and dismissable banner', (
      tester,
    ) async {
      await pumpResult(tester, BookingStatus.confirmed, notes: 'Piñata');
      expect(find.text(l10n.amenitiesResultConfirmedTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesResultConfirmedHeading), findsOneWidget);
      expect(find.text(l10n.amenitiesResultConfirmedSubtext), findsOneWidget);
      expect(find.text(l10n.amenitiesBannerConfirmedMessage), findsOneWidget);
      expect(find.text('Salón de eventos'), findsOneWidget);
      expect(find.text('Torre B'), findsOneWidget);
      expect(find.text('Miércoles 12 de junio'), findsOneWidget);
      expect(find.text('15:00–16:00 · 1 hora'), findsOneWidget);
      expect(find.text(l10n.amenitiesNotesValue('Piñata')), findsOneWidget);

      await tester.tap(find.byIcon(TablerIcons.x));
      await tester.pumpAndSettle();
      expect(find.text(l10n.amenitiesBannerConfirmedMessage), findsNothing);
    });

    testWidgets('pending copy, no notes line', (tester) async {
      await pumpResult(tester, BookingStatus.pending);
      expect(find.text(l10n.amenitiesResultPendingTitle), findsOneWidget);
      expect(find.text(l10n.amenitiesPendingConfirmation), findsOneWidget);
      expect(find.text(l10n.amenitiesResultPendingSubtext), findsOneWidget);
      expect(find.text(l10n.amenitiesBannerPendingMessage), findsOneWidget);
      expect(find.textContaining('Notas:'), findsNothing);
    });

    testWidgets('"view my bookings" returns to the home route', (tester) async {
      await pumpResult(tester, BookingStatus.pending);
      await tester.tap(find.text(l10n.amenitiesViewMyBookings));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.text(l10n.amenitiesViewMyBookings), findsNothing);
    });

    testWidgets('dark theme smoke', (tester) async {
      await pumpResult(tester, BookingStatus.confirmed, mode: ThemeMode.dark);
      expect(find.text(l10n.amenitiesResultConfirmedTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
