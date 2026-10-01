import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/create_visit_type_screen.dart';
import 'package:gates_app/features/visits/presentation/providers_catalog_controller.dart';
import 'package:gates_app/features/visits/presentation/select_provider_screen.dart';
import 'package:gates_app/features/visits/presentation/visit_details_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'visits_test_helpers.dart';

void main() {
  setUpAll(loadManrope);

  final l10n = AppLocalizationsEs();

  group('CreateVisitTypeScreen', () {
    Future<List<String>> pump(
      WidgetTester tester, {
      ThemeMode mode = ThemeMode.light,
      bool withMembership = true,
    }) async {
      final visited = <String>[];
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateVisitTypeScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        mode: mode,
        visited: visited,
        overrides: withMembership
            ? membershipOverrides()
            : [
                selectedMembershipProvider.overrideWith(
                  () => FakeSelectedMembership(null),
                ),
              ],
        routes: {
          '/visits/new/fastlane': (_) => const Text('FASTLANE'),
          '/visits/new/delivery': (_) => const Text('DELIVERY'),
          '/visits/new/frequent': (_) => const Text('FREQUENT'),
        },
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return visited;
    }

    testWidgets('lists the three visit kinds for the selected unit', (
      tester,
    ) async {
      await pump(tester, mode: ThemeMode.dark);
      expect(find.text(l10n.visitsNewTypeTitle), findsOneWidget);
      expect(find.text(l10n.visitsNewTypeAccessFor), findsOneWidget);
      expect(find.text('A-204 · Los Olivos'), findsOneWidget);
      expect(find.text(l10n.visitsNewTypeGuest), findsOneWidget);
      expect(find.text(l10n.visitsDeliveryOrProvider), findsOneWidget);
      expect(find.text(l10n.visitsFrequentAccess), findsOneWidget);
    });

    testWidgets('each row pushes its create route', (tester) async {
      final visited = await pump(tester);
      for (final entry in {
        l10n.visitsNewTypeGuest: '/visits/new/fastlane',
        l10n.visitsDeliveryOrProvider: '/visits/new/delivery',
        l10n.visitsFrequentAccess: '/visits/new/frequent',
      }.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(visited.last, entry.value);
        // Back to the type screen.
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('back arrow pops the screen', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip(l10n.visitsBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsNewTypeTitle), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('SelectProviderScreen', () {
    Future<List<String>> pump(
      WidgetTester tester,
      FakeCatalogRepository catalog, {
      ProviderKind kind = ProviderKind.delivery,
      ThemeMode mode = ThemeMode.light,
      bool settle = true,
    }) async {
      final visited = <String>[];
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SelectProviderScreen(initialKind: kind),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        mode: mode,
        settle: settle,
        visited: visited,
        overrides: [
          ...membershipOverrides(),
          providersCatalogRepositoryProvider.overrideWithValue(catalog),
        ],
        routes: {
          '/visits/new/delivery/details': (s) {
            final args = s.extra as VisitDetailsArgs;
            return Text('DETAILS ${args.kind.name} ${args.provider?.name}');
          },
        },
      );
      await tester.tap(find.text('open'));
      settle
          ? await tester.pumpAndSettle()
          : await tester.pump(const Duration(milliseconds: 300));
      return visited;
    }

    testWidgets('lists the catalog of the initial kind', (tester) async {
      final catalog = defaultCatalog();
      await pump(tester, catalog, mode: ThemeMode.dark);
      expect(find.text(l10n.visitsCatalogTitleCompany), findsOneWidget);
      expect(find.text('Rappi'), findsOneWidget);
      expect(find.text('Uber Eats'), findsOneWidget);
      expect(find.text('UE'), findsOneWidget);
      expect(catalog.requested, [ProviderKind.delivery]);
    });

    testWidgets('kind tabs reload the catalog and retitle the screen', (
      tester,
    ) async {
      final catalog = defaultCatalog();
      await pump(tester, catalog);
      await tester.tap(
        find.text(providerKindLabel(l10n, ProviderKind.proveedor)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsCatalogTitleService), findsOneWidget);
      expect(find.text('Control de plagas'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
      expect(find.text('Rappi'), findsNothing);
      await tester.tap(
        find.text(providerKindLabel(l10n, ProviderKind.paqueteria)),
      );
      await tester.pumpAndSettle();
      expect(find.text('DHL Express'), findsOneWidget);
      expect(find.text(l10n.visitsCatalogTitleCompany), findsOneWidget);
    });

    testWidgets('search filters case-insensitively and offers a custom entry', (
      tester,
    ) async {
      await pump(tester, defaultCatalog());
      await tester.enterText(find.byType(TextField), '  UBER ');
      await tester.pumpAndSettle();
      expect(find.text('Uber Eats'), findsOneWidget);
      expect(find.text('Rappi'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsCatalogNoResultsTitle), findsOneWidget);
      expect(find.text(l10n.visitsCatalogNoResultsBody), findsOneWidget);
      expect(find.text(l10n.visitsCatalogRegisterCustom), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Rappi'), findsOneWidget);
    });

    testWidgets('tapping an item opens details with that provider', (
      tester,
    ) async {
      final visited = await pump(tester, defaultCatalog());
      await tester.tap(find.text('Rappi'));
      await tester.pumpAndSettle();
      expect(visited.last, '/visits/new/delivery/details');
      expect(find.text('DETAILS delivery Rappi'), findsOneWidget);
    });

    testWidgets('"Otro" and the no-results button open details without one', (
      tester,
    ) async {
      final visited = await pump(tester, defaultCatalog());
      await tester.tap(find.text(l10n.visitsCatalogOther));
      await tester.pumpAndSettle();
      expect(find.text('DETAILS delivery null'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsCatalogRegisterCustom));
      await tester.pumpAndSettle();
      expect(visited, hasLength(2));
    });

    testWidgets('error shows the cause; retry refetches', (tester) async {
      final catalog = defaultCatalog()..error = const AuthFailure();
      await pump(tester, catalog);
      expect(
        find.text('${l10n.commonErrorSession} ${l10n.visitsCatalogLoadError}'),
        findsOneWidget,
      );
      catalog.error = null;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('Rappi'), findsOneWidget);
    });

    testWidgets('loading state before the catalog arrives', (tester) async {
      await pump(tester, defaultCatalog(), settle: false);
      // First frame after opening: spinner while the future resolves.
      await tester.pump();
      expect(find.text(l10n.visitsCatalogSearchLabel), findsWidgets);
    });

    testWidgets('proveedor start kind uses the service title', (tester) async {
      await pump(tester, defaultCatalog(), kind: ProviderKind.proveedor);
      expect(find.text(l10n.visitsCatalogTitleService), findsOneWidget);
    });

    testWidgets('back arrow pops', (tester) async {
      await pump(tester, defaultCatalog());
      await tester.tap(find.byTooltip(l10n.visitsBack));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });
  });
}
