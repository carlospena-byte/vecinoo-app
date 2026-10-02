import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/app_info.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/theme/theme_mode_controller.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/profile/presentation/profile_controller.dart';
import 'package:gates_app/features/profile/presentation/profile_screen.dart';
import 'package:gates_app/features/session/presentation/pending_link_screen.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/session/presentation/unit_selector_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import '_fakes.dart';

final _es = AppLocalizationsEs();

const _second = Membership(
  residentialId: 'res-2',
  residentialName: 'Pinos',
  unitId: 'unit-2',
  unitName: 'B-7',
);

void main() {
  setUpAll(loadManrope);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('UnitSelectorScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;

    setUp(() {
      auth = FakeAuthRepo(user: const SignedInUser(id: 'u1'));
      session = FakeSessionRepo()..memberships = [testMembership, _second];
    });

    Future<void> pump(WidgetTester tester, {ThemeMode? mode}) => pumpApp(
      tester,
      const UnitSelectorScreen(),
      mode: mode ?? ThemeMode.light,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
    );

    testWidgets('lists every unit and persists the chosen one', (tester) async {
      await pump(tester, mode: ThemeMode.dark);
      expect(find.text(_es.sessionSelectUnitTitle), findsOneWidget);
      expect(find.text('A-204 · Los Olivos'), findsOneWidget);
      await tester.tap(find.text('B-7 · Pinos'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_unit_id'), 'unit-2');
    });

    testWidgets('logout signs out', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip(_es.commonLogout));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signOut']);
    });

    testWidgets('a failed logout shows an error toast', (tester) async {
      auth.signOutError = const NetworkFailure();
      await pump(tester);
      await tester.tap(find.byTooltip(_es.commonLogout));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.commonErrorNetwork), findsOneWidget);
    });
  });

  group('PendingLinkScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;

    setUp(() {
      auth = FakeAuthRepo(user: const SignedInUser(id: 'u1'));
      session = FakeSessionRepo();
    });

    Future<void> pump(WidgetTester tester, {ThemeMode? mode}) => pumpApp(
      tester,
      const PendingLinkScreen(),
      mode: mode ?? ThemeMode.light,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
    );

    testWidgets('renders the pending copy', (tester) async {
      await pump(tester, mode: ThemeMode.dark);
      expect(find.text(_es.sessionPendingTitle), findsOneWidget);
      expect(find.text(_es.sessionCodeDigitsHelper), findsOneWidget);
    });

    testWidgets('typing a code redeems it, filtering non digits', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), '12ab34567');
      await tester.tap(find.text(_es.sessionUseCode));
      await tester.pumpAndSettle();
      expect(session.calls, ['accept:123456']);
    });

    testWidgets('an empty code does nothing', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_es.sessionUseCode));
      await tester.pumpAndSettle();
      expect(session.calls, isEmpty);
    });

    testWidgets('a rejected code shows the invalid message', (tester) async {
      session.acceptResult = false;
      await pump(tester);
      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.text(_es.sessionUseCode));
      await tester.pumpAndSettle();
      expect(find.text(_es.authInvitationInvalid), findsOneWidget);
    });

    testWidgets('a failing redeem shows detail plus invalid copy', (
      tester,
    ) async {
      session.acceptError = const NetworkFailure();
      await pump(tester);
      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.text(_es.sessionUseCode));
      await tester.pumpAndSettle();
      expect(
        find.text('${_es.commonErrorNetwork} ${_es.authInvitationInvalid}'),
        findsOneWidget,
      );
    });

    testWidgets('a code saved during registration is redeemed on open', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'pending_invitation_code': '654321',
      });
      await pump(tester);
      expect(session.calls, ['accept:654321']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('pending_invitation_code'), isFalse);
    });

    testWidgets('retry refreshes memberships; logout signs out', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_es.sessionAlreadyLinkedRetry));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_es.commonLogout));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signOut']);
    });
  });

  group('ProfileScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;
    late FakeProfileRepo profiles;

    setUp(() {
      auth = FakeAuthRepo(user: const SignedInUser(id: 'u1'));
      session = FakeSessionRepo()..memberships = [testMembership];
      profiles = FakeProfileRepo();
    });

    Future<void> pump(
      WidgetTester tester, {
      ThemeMode mode = ThemeMode.light,
    }) => pumpApp(
      tester,
      const ProfileScreen(),
      mode: mode,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
        profileRepositoryProvider.overrideWithValue(profiles),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
      ],
    );

    testWidgets('shows contact data and the selected unit', (tester) async {
      await pump(tester);
      expect(find.text('Ana Perez'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text('+50499999999'), findsOneWidget);
      expect(find.text('A-204'), findsOneWidget);
      expect(find.text('Los Olivos'), findsOneWidget);
      expect(find.text(_es.profileChangeUnit), findsNothing);
      expect(find.text(_es.profileUnitManagedNote), findsOneWidget);
    });

    testWidgets('hides absent contact rows', (tester) async {
      profiles.profile = const Profile(userId: 'u');
      await pump(tester, mode: ThemeMode.dark);
      expect(find.byIcon(TablerIcons.phone), findsNothing);
      // The email row stays, as the way to add/change it.
      expect(find.text(_es.profileChangeEmail), findsOneWidget);
      expect(find.text('Residente'), findsOneWidget);
    });

    testWidgets('with several units, change unit clears the selection', (
      tester,
    ) async {
      session.memberships = [testMembership, _second];
      SharedPreferences.setMockInitialValues({'selected_unit_id': 'unit-1'});
      await pump(tester);
      await tester.tap(find.text(_es.profileChangeUnit));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('selected_unit_id'), isFalse);
    });

    testWidgets('appearance selector persists the choice', (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.text(_es.profileThemeDark));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profileThemeDark));
      await tester.pumpAndSettle();
      expect(await ThemeModeStorage.read(), ThemeMode.dark);
      await tester.ensureVisible(find.text(_es.profileThemeSystem));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profileThemeSystem));
      await tester.pumpAndSettle();
      expect(await ThemeModeStorage.read(), ThemeMode.system);
      await tester.ensureVisible(find.text(_es.profileThemeLight));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profileThemeLight));
      await tester.pumpAndSettle();
      expect(await ThemeModeStorage.read(), ThemeMode.light);
    });

    testWidgets('sign out calls the repository', (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(find.text(_es.commonLogout), 200);
      await tester.tap(find.text(_es.commonLogout));
      await tester.pumpAndSettle();
      expect(auth.calls, isEmpty, reason: 'asks for confirmation first');
      await tester.tap(find.text(_es.commonLogout).last);
      await tester.pumpAndSettle();
      expect(auth.calls, ['signOut']);
    });

    testWidgets('sign out failure toasts the cause', (tester) async {
      auth.signOutError = const ServerFailure();
      await pump(tester);
      await tester.scrollUntilVisible(find.text(_es.commonLogout), 200);
      await tester.tap(find.text(_es.commonLogout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.commonLogout).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.commonErrorServer), findsOneWidget);
    });

    testWidgets('load failure shows detail and retries', (tester) async {
      profiles.error = StateError('x');
      await pump(tester);
      expect(find.text(_es.profileLoadFailed), findsOneWidget);
      profiles.error = null;
      await tester.tap(find.text(_es.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('Ana Perez'), findsOneWidget);
    });

    testWidgets('network failure detail is prefixed', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: [
          ...membershipOverrides(),
          myMembershipsProvider.overrideWith((ref) async => [testMembership]),
          myProfileProvider.overrideWith(
            (ref) =>
                Future<Profile>.error(const NetworkFailure(), StackTrace.empty),
          ),
        ],
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(minutes: 10));
      await tester.pump();
      expect(
        find.text('${_es.commonErrorNetwork} ${_es.profileLoadFailed}'),
        findsOneWidget,
      );
    });
  });

  test('theme mode initial provider default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(initialThemeModeProvider), ThemeMode.system);
  });
}
