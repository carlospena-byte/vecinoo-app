import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/bulletins/domain/bulletin.dart';
import 'package:gates_app/features/bulletins/presentation/bulletins_controller.dart';
import 'package:gates_app/features/home/home_shell.dart';
import 'package:gates_app/features/home/presentation/home_screen.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/profile/presentation/profile_controller.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../incidents/fakes.dart';
import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';

final _es = AppLocalizationsEs();

AmenityBooking _booking({
  required DateTime start,
  Duration length = const Duration(hours: 2),
  BookingStatus status = BookingStatus.confirmed,
  String name = 'Piscina',
}) => AmenityBooking(
  id: 'b-${start.microsecondsSinceEpoch}',
  amenityId: 'a1',
  amenityName: name,
  startTime: start,
  endTime: start.add(length),
  status: status,
);

Visit _visit({
  VisitStatus status = VisitStatus.scheduled,
  DateTime? from,
  DateTime? until,
}) {
  final now = DateTime.now();
  return Visit(
    id: 'v-${status.name}-${from?.microsecondsSinceEpoch}',
    unitId: 'unit-1',
    status: status,
    visitType: VisitType.frequent,
    validFrom: from ?? now.subtract(const Duration(hours: 1)),
    validUntil: until ?? now.add(const Duration(hours: 5)),
    createdAt: now,
  );
}

Incident _incident(IncidentStatus status, String id) => Incident(
  id: id,
  title: 'Fuga',
  priority: IncidentPriority.medium,
  status: status,
  createdAt: DateTime(2026, 1, 1),
);

List<Override> _data({
  Profile? profile,
  Object? profileError,
  VoidCallback? onProfileLoad,
  List<AmenityBooking> bookings = const [],
  Object? bookingsError,
  Future<List<AmenityBooking>>? bookingsGate,
  List<Visit> visits = const [],
  List<Incident> incidents = const [],
  List<Bulletin> bulletins = const [],
}) => [
  ...membershipOverrides(),
  myProfileProvider.overrideWith((ref) async {
    onProfileLoad?.call();
    if (profileError != null) throw profileError;
    return profile ??
        const Profile(userId: 'u', firstName: 'Ana María', lastName: 'Pérez');
  }),
  myBookingsProvider.overrideWith((ref) async {
    if (bookingsGate != null) return bookingsGate;
    if (bookingsError != null) throw bookingsError;
    return bookings;
  }),
  visitsListProvider.overrideWith((ref, unitId) => Stream.value(visits)),
  incidentsListProvider.overrideWith((ref, rid) async => incidents),
  incidentsRepositoryProvider.overrideWithValue(
    FakeIncidentsRepository()..incidents = incidents,
  ),
  bulletinsListProvider.overrideWith((ref, rid) async => bulletins),
];

Future<void> _pumpHome(
  WidgetTester tester, {
  required List<Override> overrides,
  ValueChanged<int>? onTab,
  List<String>? visited,
  ThemeMode mode = ThemeMode.light,
  bool settle = true,
}) => pumpApp(
  tester,
  HomeScreen(onNavigateToTab: onTab ?? (_) {}),
  overrides: overrides,
  visited: visited,
  mode: mode,
  settle: settle,
  routes: {
    '/profile': (_) => const Text('profile-route'),
    '/amenities': (_) => const Text('amenities-route'),
    '/visits/new': (_) => const Text('new-visit-route'),
    '/incidents/report': (_) => const Text('report-route'),
    '/bulletins': (_) => const Text('bulletins-route'),
  },
);

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  group('HomeScreen', () {
    testWidgets('greets by first name, shows unit header and tagline', (
      tester,
    ) async {
      await _pumpHome(tester, overrides: _data());
      expect(find.text(_es.homeGreetingNamed('Ana')), findsOneWidget);
      expect(find.text(_es.homeTagline), findsOneWidget);
      expect(find.text('LOS OLIVOS'), findsOneWidget);
      expect(find.text('A-204'), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // avatar letter
    });

    testWidgets('falls back to the generic greeting and "?" avatar', (
      tester,
    ) async {
      // displayName falls back to 'Residente' => letter R, no first name.
      await _pumpHome(
        tester,
        overrides: _data(profile: const Profile(userId: 'u')),
      );
      expect(find.text(_es.homeGreeting), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('shows a loading view while the membership is unresolved', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        overrides: [
          ..._data().skip(1),
          selectedMembershipProvider.overrideWith(_NullMembership.new),
        ],
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('profile loading then failure with retry', (tester) async {
      var attempts = 0;
      await _pumpHome(
        tester,
        overrides: [
          ...membershipOverrides(),
          myProfileProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw StateError('boom');
            return const Profile(userId: 'u', firstName: 'Luis');
          }),
          myBookingsProvider.overrideWith((ref) async => const []),
          visitsListProvider.overrideWith((ref, id) => Stream.value(const [])),
          incidentsListProvider.overrideWith((ref, id) async => const []),
        ],
      );
      expect(find.text(_es.profileLoadFailed), findsOneWidget);
      await tester.tap(find.text(_es.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text(_es.homeGreetingNamed('Luis')), findsOneWidget);
    });

    testWidgets('bell shows the coming soon toast', (tester) async {
      await _pumpHome(tester, overrides: _data());
      await tester.tap(find.bySemanticsLabel(_es.homeNotifications));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.homeComingSoon), findsOneWidget);
    });

    testWidgets('avatar opens the profile route', (tester) async {
      final visited = <String>[];
      await _pumpHome(tester, overrides: _data(), visited: visited);
      await tester.tap(find.bySemanticsLabel(_es.commonProfile));
      await tester.pumpAndSettle();
      expect(visited, ['/profile']);
      expect(find.text('profile-route'), findsOneWidget);
    });

    group('reservation card', () {
      testWidgets('empty state', (tester) async {
        final visited = <String>[];
        await _pumpHome(tester, overrides: _data(), visited: visited);
        expect(find.text(_es.homeNoBookingsTitle), findsOneWidget);
        expect(find.text(_es.homeNoBookingsDetail), findsOneWidget);
        await tester.tap(find.text(_es.homeExploreAmenities));
        await tester.pumpAndSettle();
        expect(visited, ['/amenities']);
      });

      testWidgets('loading state shows a spinner', (tester) async {
        final gate = Completer<List<AmenityBooking>>();
        await pumpApp(
          tester,
          HomeScreen(onNavigateToTab: (_) {}),
          overrides: _data(bookingsGate: gate.future),
          settle: false,
        );
        await tester.pump();
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        gate.complete(const []);
        await tester.pumpAndSettle();
        expect(find.text(_es.homeNoBookingsTitle), findsOneWidget);
      });

      testWidgets('error state offers retry', (tester) async {
        await _pumpHome(
          tester,
          overrides: _data(bookingsError: StateError('boom')),
        );
        expect(find.text(_es.homeBookingsLoadFailed), findsOneWidget);
        await tester.tap(find.text(_es.commonRetry));
        await tester.pumpAndSettle();
        expect(find.text(_es.homeBookingsLoadFailed), findsOneWidget);
      });

      testWidgets('next booking today picks the earliest upcoming one', (
        tester,
      ) async {
        final now = DateTime.now();
        final soon = DateTime(now.year, now.month, now.day, 23, 0);
        await _pumpHome(
          tester,
          overrides: _data(
            bookings: [
              _booking(
                start: now.add(const Duration(days: 3)),
                name: 'Gimnasio',
              ),
              _booking(
                start: now.subtract(const Duration(days: 3)),
                name: 'Pasada',
              ),
              _booking(
                start: now.add(const Duration(minutes: 30)),
                status: BookingStatus.cancelled,
                name: 'Cancelada',
              ),
              _booking(
                start: soon.isAfter(now)
                    ? soon
                    : now.add(const Duration(minutes: 5)),
                length: const Duration(minutes: 30),
              ),
            ],
          ),
        );
        expect(find.textContaining('Piscina'), findsOneWidget);
        expect(find.textContaining('Gimnasio'), findsNothing);
        expect(find.textContaining('Cancelada'), findsNothing);
      });

      testWidgets('tomorrow and later dates are labelled', (tester) async {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1, 6, 0);
        await _pumpHome(
          tester,
          overrides: _data(
            bookings: [
              _booking(start: tomorrow, length: const Duration(hours: 4)),
            ],
          ),
        );
        expect(find.text('Piscina · ${_es.homeTomorrow}'), findsOneWidget);
        expect(find.text('6:00–10:00 ${_es.homeAm}'), findsOneWidget);
      });

      testWidgets('later dates use the short day format and pm', (
        tester,
      ) async {
        final now = DateTime.now();
        final later = DateTime(now.year, now.month, now.day + 5, 18, 0);
        await _pumpHome(
          tester,
          overrides: _data(
            bookings: [
              _booking(start: later, length: const Duration(hours: 4)),
            ],
          ),
          mode: ThemeMode.dark,
        );
        expect(find.text('6:00–10:00 ${_es.homePm}'), findsOneWidget);
      });

      testWidgets('today is labelled "Hoy"', (tester) async {
        final now = DateTime.now();
        // Pin to local noon..1pm only when it is still ahead; otherwise use
        // a booking that started a minute ago and ends in an hour.
        final start = now.subtract(const Duration(minutes: 1));
        final end = now.add(const Duration(hours: 1));
        final sameDay =
            DateTime(start.year, start.month, start.day) ==
            DateTime(end.year, end.month, end.day);
        await _pumpHome(
          tester,
          overrides: _data(
            bookings: [
              AmenityBooking(
                id: 'x',
                amenityId: 'a',
                amenityName: 'Salon',
                startTime: start,
                endTime: end,
                status: BookingStatus.pending,
              ),
            ],
          ),
        );
        if (sameDay) {
          expect(find.text('Salon · ${_es.homeToday}'), findsOneWidget);
        }
        expect(find.textContaining('Salon'), findsOneWidget);
      });
    });

    group('summary cards', () {
      testWidgets('empty: invite and report open the creation routes', (
        tester,
      ) async {
        final visited = <String>[];
        await _pumpHome(tester, overrides: _data(), visited: visited);
        expect(find.text(_es.homeInvite), findsOneWidget);
        expect(find.text(_es.homeReport), findsOneWidget);
        await tester.tap(find.text(_es.homeInvite));
        await tester.pumpAndSettle();
        expect(visited, ['/visits/new']);
      });

      testWidgets('empty incidents card opens the report route', (
        tester,
      ) async {
        final visited = <String>[];
        await _pumpHome(tester, overrides: _data(), visited: visited);
        await tester.ensureVisible(find.text(_es.homeReport));
        await tester.tap(find.text(_es.homeReport));
        await tester.pumpAndSettle();
        expect(visited, ['/incidents/report']);
      });

      testWidgets('counts today\'s planned visits and open incidents', (
        tester,
      ) async {
        final taps = <int>[];
        final now = DateTime.now();
        await _pumpHome(
          tester,
          onTab: taps.add,
          overrides: _data(
            visits: [
              _visit(),
              _visit(status: VisitStatus.inside),
              _visit(status: VisitStatus.completed),
              _visit(
                status: VisitStatus.active,
                from: now.add(const Duration(days: 2)),
                until: now.add(const Duration(days: 3)),
              ),
            ],
            incidents: [
              _incident(IncidentStatus.newIncident, '1'),
              _incident(IncidentStatus.inProgress, '2'),
              _incident(IncidentStatus.resolved, '3'),
              _incident(IncidentStatus.closed, '4'),
            ],
          ),
        );
        expect(find.text(_es.homeVisitsSummary(2)), findsOneWidget);
        expect(find.text(_es.homeIncidentsSummary(2)), findsOneWidget);
        expect(find.text(_es.homeViewVisits), findsOneWidget);
        await tester.tap(find.text(_es.homeViewVisits));
        await tester.tap(find.text(_es.homeViewReport));
        expect(taps, [3, 1]);
      });

      testWidgets('singular copy', (tester) async {
        await _pumpHome(
          tester,
          overrides: _data(
            visits: [_visit(status: VisitStatus.pendingRegistration)],
            incidents: [_incident(IncidentStatus.newIncident, '1')],
          ),
        );
        expect(find.text(_es.homeVisitsSummary(1)), findsOneWidget);
        expect(find.text(_es.homeIncidentsSummary(1)), findsOneWidget);
      });
    });

    group('bulletins card', () {
      testWidgets('empty: says so and opens the history', (tester) async {
        final visited = <String>[];
        await _pumpHome(tester, overrides: _data(), visited: visited);
        expect(find.text(_es.homeBulletins), findsOneWidget);
        expect(find.text(_es.homeBulletinsEmpty), findsOneWidget);
        await tester.tap(find.text(_es.homeViewBulletinsHistory));
        await tester.pumpAndSettle();
        expect(visited, ['/bulletins?tab=history']);
        expect(find.text('bulletins-route'), findsOneWidget);
      });

      testWidgets('counts the unread bulletins', (tester) async {
        await _pumpHome(
          tester,
          overrides: _data(
            bulletins: [
              Bulletin(
                id: 'b2',
                title: 'Asamblea general',
                publishedAt: DateTime(2026, 3, 5),
              ),
              Bulletin(
                id: 'b1',
                title: 'Corte de agua',
                publishedAt: DateTime(2026, 3, 1),
              ),
            ],
          ),
        );
        expect(find.text(_es.homeBulletinsSummary(2)), findsOneWidget);
        expect(find.text(_es.homeViewBulletins), findsOneWidget);
      });
    });

    testWidgets('pull to refresh reloads the profile', (tester) async {
      var loads = 0;
      await _pumpHome(tester, overrides: _data(onProfileLoad: () => loads++));
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(loads, 2);
    });
  });

  group('HomeShell', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      HomeTabRequest? request,
      ThemeMode mode = ThemeMode.light,
    }) => pumpApp(
      tester,
      HomeShell(tabRequest: request),
      overrides: _data(),
      mode: mode,
    );

    int index(WidgetTester tester) =>
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

    testWidgets('starts on home and switches tabs from the nav pill', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(index(tester), 0);
      final expected = {
        _es.homeIncidents: 1,
        _es.homeReservations: 2,
        _es.homeVisits: 3,
        _es.homeNavHome: 0,
      };
      for (final entry in expected.entries) {
        await tester.tap(
          find.descendant(
            of: find.byKey(HomeShell.navBarKey),
            matching: find.text(entry.key),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(index(tester), entry.value, reason: entry.key);
      }
    });

    testWidgets('a tab request selects the requested tab', (tester) async {
      await pumpShell(
        tester,
        request: const HomeTabRequest(HomeShell.visitsTab),
      );
      expect(index(tester), HomeShell.visitsTab);
    });

    testWidgets('home summary cards switch the shell tab (dark)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const HomeShell(),
        mode: ThemeMode.dark,
        overrides: _data(
          visits: [_visit()],
          incidents: [_incident(IncidentStatus.newIncident, '1')],
        ),
      );
      await tester.tap(find.text(_es.homeViewVisits));
      await tester.pump();
      expect(index(tester), HomeShell.visitsTab);
      await tester.tap(
        find.descendant(
          of: find.byKey(HomeShell.navBarKey),
          matching: find.text(_es.homeNavHome),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(_es.homeViewReport));
      await tester.pump();
      expect(index(tester), 1);
    });

    testWidgets('a new tab request replaces the current tab', (tester) async {
      final key = GlobalKey();
      late StateSetter update;
      var request = const HomeTabRequest(HomeShell.bookingsTab);
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return HomeShell(key: key, tabRequest: request);
          },
        ),
        overrides: _data(),
      );
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        HomeShell.bookingsTab,
      );
      update(() => request = const HomeTabRequest(HomeShell.visitsTab));
      await tester.pump();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        HomeShell.visitsTab,
      );
    });
  });
}

class _NullMembership extends SelectedMembershipController {
  @override
  Future<Membership?> build() async => null;
}
