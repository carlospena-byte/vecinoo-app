import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/router/app_router.dart';
import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/auth/presentation/otp_verify_controller.dart';
import 'package:gates_app/features/home/home_shell.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incident_edit_args.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/visit_details_controller.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/profile/presentation/profile_controller.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:gates_app/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart' show testMembership;
import '_fakes.dart';

final _es = AppLocalizationsEs();

const _second = Membership(
  residentialId: 'res-2',
  residentialName: 'Pinos',
  unitId: 'unit-2',
  unitName: 'B-7',
);

class _Harness {
  _Harness({SignedInUser? user, List<Membership> memberships = const []})
    : auth = FakeAuthRepo(user: user),
      session = FakeSessionRepo()..memberships = memberships;

  final FakeAuthRepo auth;
  final FakeSessionRepo session;
  late GoRouter router;

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(auth),
    sessionRepositoryProvider.overrideWithValue(session),
    myProfileProvider.overrideWith(
      (ref) async => const Profile(userId: 'u', firstName: 'Ana'),
    ),
    myBookingsProvider.overrideWith((ref) async => const []),
    visitsListProvider.overrideWith((ref, id) => Stream.value(const [])),
    incidentsListProvider.overrideWith((ref, id) async => const []),
  ];

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.light(),
              locale: const Locale('es'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String get location =>
      router.routerDelegate.currentConfiguration.uri.toString();
}

Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

void main() {
  setUpAll(loadManrope);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('redirect gate', () {
    testWidgets('signed out goes to /login', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      expect(h.location, '/login');
      expect(find.text(_es.authLoginTitle), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('signed out may open /register', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.router.go('/register');
      await tester.pumpAndSettle();
      expect(h.location, '/register');
      expect(find.text(_es.authValidateCodeTitle), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('signed out is bounced from protected routes', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.router.go('/profile');
      await tester.pumpAndSettle();
      expect(h.location, '/login');
      await _dispose(tester);
    });

    testWidgets('verify-otp without extra goes to /login when signed out', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.router.go('/verify-otp');
      await tester.pumpAndSettle();
      expect(h.location, '/login');
      await _dispose(tester);
    });

    testWidgets('verify-otp with extra opens the code screen', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.router.go(
        '/verify-otp',
        extra: const OtpVerifyArgs(
          identifier: 'a@b.c',
          channel: OtpChannel.email,
        ),
      );
      await tester.pumpAndSettle();
      expect(h.location, '/verify-otp');
      expect(find.text(_es.authCheckEmail), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('signed in without memberships goes to /pending-link', (
      tester,
    ) async {
      final h = _Harness(user: const SignedInUser(id: 'u'));
      await h.pump(tester);
      expect(h.location, '/pending-link');
      expect(find.text(_es.sessionPendingTitle), findsOneWidget);
      h.router.go('/login');
      await tester.pumpAndSettle();
      expect(h.location, '/pending-link');
      await _dispose(tester);
    });

    testWidgets('ambiguous units go to /select-unit', (tester) async {
      final h = _Harness(
        user: const SignedInUser(id: 'u'),
        memberships: [testMembership, _second],
      );
      await h.pump(tester);
      expect(h.location, '/select-unit');
      await tester.tap(find.text('B-7 · Pinos'));
      await tester.pumpAndSettle();
      expect(h.location, '/');
      expect(find.text('B-7'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('a single membership lands on home; gate screens bounce home', (
      tester,
    ) async {
      final h = _Harness(
        user: const SignedInUser(id: 'u'),
        memberships: [testMembership],
      );
      await h.pump(tester);
      expect(h.location, '/');
      expect(find.text(_es.homeGreetingNamed('Ana')), findsOneWidget);
      for (final path in [
        '/login',
        '/register',
        '/pending-link',
        '/select-unit',
      ]) {
        h.router.go(path);
        await tester.pumpAndSettle();
        expect(h.location, '/', reason: path);
      }
      await _dispose(tester);
    });

    testWidgets('verify-otp without extra goes home when signed in', (
      tester,
    ) async {
      final h = _Harness(
        user: const SignedInUser(id: 'u'),
        memberships: [testMembership],
      );
      await h.pump(tester);
      h.router.go('/verify-otp');
      await tester.pumpAndSettle();
      expect(h.location, '/');
      await _dispose(tester);
    });

    testWidgets('signing out redirects to /login', (tester) async {
      final h = _Harness(
        user: const SignedInUser(id: 'u'),
        memberships: [testMembership],
      );
      await h.pump(tester);
      expect(h.location, '/');
      await h.auth.signOut();
      await tester.pumpAndSettle();
      expect(h.location, '/login');
      await _dispose(tester);
    });
  });

  group('route table', () {
    Future<_Harness> signedIn(WidgetTester tester) async {
      final h = _Harness(
        user: const SignedInUser(id: 'u'),
        memberships: [testMembership],
      );
      await h.pump(tester);
      return h;
    }

    testWidgets('protected detail routes fall back without their extra', (
      tester,
    ) async {
      final h = await signedIn(tester);
      final cases = {
        '/amenities/a1/review': '/amenities/a1',
        '/amenities/a1/result': '/amenities/a1',
        '/incidents/i1/edit': '/incidents/i1',
        '/visits/v1/access/edit': '/visits/v1/access',
        '/visits/v1/edit': '/visits/v1',
      };
      for (final entry in cases.entries) {
        h.router.go(entry.key);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(h.location, entry.value, reason: entry.key);
      }
      await _dispose(tester);
    });

    testWidgets('the profile route builds', (tester) async {
      final h = await signedIn(tester);
      h.router.go('/profile');
      await tester.pumpAndSettle();
      expect(h.location, '/profile');
      expect(find.text('Ana'), findsWidgets);
      await _dispose(tester);
    });

    testWidgets('biometric setup route builds', (tester) async {
      final h = await signedIn(tester);
      h.router.go('/setup-biometrics');
      await tester.pumpAndSettle();
      expect(find.text(_es.authBiometricTitle), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('every feature route resolves and builds its screen', (
      tester,
    ) async {
      final h = await signedIn(tester);
      final visit = Visit(
        id: 'v1',
        unitId: 'unit-1',
        status: VisitStatus.scheduled,
        visitType: VisitType.frequent,
        validFrom: DateTime(2030),
        validUntil: DateTime(2030, 1, 2),
        createdAt: DateTime(2030),
      );
      final incident = Incident(
        id: 'i1',
        title: 'Fuga',
        priority: IncidentPriority.low,
        status: IncidentStatus.newIncident,
        createdAt: DateTime(2030),
      );
      final routes = <String, Object?>{
        '/amenities': null,
        '/amenities/a1': null,
        '/incidents/report': null,
        '/incidents/i1': null,
        '/incidents/i1/edit': IncidentEditArgs(
          incident: incident,
          attachments: const [],
        ),
        '/visits/new': null,
        '/visits/new/frequent': null,
        '/visits/new/delivery': null,
        '/visits/new/delivery/details': const VisitDetailsArgs(
          kind: ProviderKind.delivery,
        ),
        '/visits/new/fastlane': null,
        '/visits/v1/access/edit': visit,
        '/visits/v1/access': null,
        '/visits/v1': visit,
        '/visits/v1?created=1': null,
        '/visits/v1/edit': visit,
      };
      for (final entry in routes.entries) {
        h.router.go(entry.key, extra: entry.value);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final path = Uri.parse(entry.key).path;
        expect(h.location, entry.key, reason: path);
      }
      await _dispose(tester);
    });

    testWidgets('a home tab request selects a tab', (tester) async {
      final h = await signedIn(tester);
      h.router.go('/', extra: const HomeTabRequest(HomeShell.visitsTab));
      await tester.pumpAndSettle();
      expect(h.location, '/');
      await _dispose(tester);
    });
  });
}
