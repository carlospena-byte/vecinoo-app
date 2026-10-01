import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

export 'package:gates_app/features/session/domain/membership.dart';

const testMembership = Membership(
  residentialId: 'res-1',
  residentialName: 'Los Olivos',
  unitId: 'unit-1',
  unitName: 'A-204',
);

class FakeSelectedMembership extends SelectedMembershipController {
  FakeSelectedMembership([this.membership = testMembership]);
  final Membership? membership;

  @override
  Future<Membership?> build() async => membership;
}

/// Overrides that make the screen think a resident of [testMembership] is
/// signed in and has selected their unit.
List<Override> membershipOverrides([Membership? membership]) => [
  selectedMembershipProvider.overrideWith(
    () => FakeSelectedMembership(membership ?? testMembership),
  ),
];

/// Phone-sized surface, restored after the test.
void usePhoneSurface(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [home] inside the real theme + localization stack and a
/// ProviderScope. [routes] adds stub destinations (path -> label) so
/// `context.push/go` calls can be observed instead of crashing; the pushed
/// locations are appended to [visited].
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  ThemeMode mode = ThemeMode.light,
  Map<String, Widget Function(GoRouterState state)> routes = const {},
  List<String>? visited,
  bool settle = true,
}) async {
  usePhoneSurface(tester);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      for (final entry in routes.entries)
        GoRoute(
          path: entry.key,
          builder: (context, state) {
            visited?.add(state.uri.toString());
            return Scaffold(body: entry.value(state));
          },
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
