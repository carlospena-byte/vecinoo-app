import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/amenities/presentation/booking_date_time_sheet.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'amenities_test_support.dart';

void main() {
  setUpAll(loadManrope);
  final l10n = AppLocalizationsEs();

  // The calendar's range is based on the real clock, so the sheet's clock
  // must be close to it.
  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1);

  BookingSelection? result;
  var closed = false;

  Future<void> open(
    WidgetTester tester, {
    int? duration = 60,
    List<AmenityBlackout> blackouts = const [],
    BookingSelection? initial,
    String? primaryLabel,
    ThemeMode mode = ThemeMode.light,
  }) async {
    result = null;
    closed = false;
    final amenity = makeAmenity(duration: duration);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showBookingDateTimeSheet(
                  context,
                  amenity: amenity,
                  blackouts: blackouts,
                  initial: initial,
                  primaryLabel: primaryLabel,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      mode: mode,
      overrides: [amenitiesClockProvider.overrideWithValue(() => now)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> goToNextMonth(WidgetTester tester) async {
    await tester.tap(find.byIcon(TablerIcons.chevronRight));
    await tester.pumpAndSettle();
  }

  Future<void> tapDay(WidgetTester tester, int day) async {
    await tester.tap(find.text('$day').last);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, [String? label]) async {
    final button = find.text(label ?? l10n.amenitiesContinue);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('fixed duration: shows computed end and confirms selection', (
    tester,
  ) async {
    await open(tester, duration: 90);
    expect(find.text(l10n.amenitiesDateTimeTitle), findsOneWidget);
    expect(find.text(l10n.amenitiesStart), findsOneWidget);
    expect(find.text(l10n.amenitiesEnd), findsNothing);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:30 · ${l10n.amenitiesDurationMinutes(90)}'), findsOne);
    expect(
      find.text(
        l10n.amenitiesEachBookingLasts(l10n.amenitiesDurationMinutes(90)),
      ),
      findsOneWidget,
    );

    await goToNextMonth(tester);
    await tapDay(tester, 15);
    await submit(tester);

    expect(closed, isTrue);
    final selection = result!;
    expect(selection.day.year, nextMonth.year);
    expect(selection.day.month, nextMonth.month);
    expect(selection.day.day, 15);
    expect(selection.start, const TimeOfDay(hour: 9, minute: 0));
    expect(selection.end, const TimeOfDay(hour: 10, minute: 30));
  });

  testWidgets('flexible duration shows both fields and the initial values', (
    tester,
  ) async {
    await open(
      tester,
      duration: null,
      initial: BookingSelection(
        day: now,
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 30),
      ),
      primaryLabel: l10n.amenitiesSave,
    );
    expect(find.text(l10n.amenitiesEnd), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
    expect(find.text(l10n.amenitiesContinue), findsNothing);

    await submit(tester, l10n.amenitiesSave);
    expect(result!.start, const TimeOfDay(hour: 14, minute: 0));
    expect(result!.end, const TimeOfDay(hour: 18, minute: 30));
  });

  testWidgets('blackout days cannot be selected and the banner lists them', (
    tester,
  ) async {
    final blackouts = [
      AmenityBlackout(
        id: 'b1',
        amenityId: 'a1',
        startDate: DateTime(nextMonth.year, nextMonth.month, 14),
        endDate: DateTime(nextMonth.year, nextMonth.month, 16),
        reason: 'Mantenimiento',
      ),
      AmenityBlackout(
        id: 'b2',
        amenityId: 'a1',
        startDate: DateTime(nextMonth.year, nextMonth.month, 25),
        endDate: DateTime(nextMonth.year, nextMonth.month, 25),
      ),
    ];
    await open(tester, blackouts: blackouts);
    // First entry carries the "Cerrado" prefix, later ones do not.
    expect(find.textContaining('Cerrado'), findsOneWidget);
    expect(find.textContaining('Mantenimiento'), findsOneWidget);

    await goToNextMonth(tester);
    await tapDay(tester, 15); // blacked out: ignored
    await tapDay(tester, 20);
    await submit(tester);
    expect(result!.day.day, 20);
  });

  testWidgets('flexible duration rejects end before start and recovers', (
    tester,
  ) async {
    await open(
      tester,
      duration: null,
      initial: BookingSelection(
        day: now,
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 14, minute: 0),
      ),
    );
    await submit(tester);
    expect(closed, isFalse);
    expect(find.text(l10n.amenitiesEndAfterStartError), findsOneWidget);

    // Moving the end time wheel forward clears the error.
    await tester.tap(find.text(l10n.amenitiesEnd));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();
    expect(find.text(l10n.amenitiesEndAfterStartError), findsNothing);
    expect(find.text('14:00'), findsOneWidget); // only the start remains
  });

  testWidgets('time picker cancel keeps the value; done applies it', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(l10n.amenitiesStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsOneWidget);

    await tester.tap(find.text(l10n.amenitiesStart));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsNothing);
  });

  testWidgets('the close button dismisses without a selection', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip(l10n.amenitiesClose));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('dark theme smoke', (tester) async {
    await open(tester, mode: ThemeMode.dark, duration: null);
    expect(find.text(l10n.amenitiesDateTimeTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
