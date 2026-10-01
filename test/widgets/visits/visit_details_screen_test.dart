import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/data/providers_catalog_repository.dart';
import 'package:gates_app/features/visits/domain/provider_catalog_item.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/providers_catalog_controller.dart';
import 'package:gates_app/features/visits/presentation/visit_details_screen.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'visits_test_helpers.dart';

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  final l10n = AppLocalizationsEs();

  Future<void> open(
    WidgetTester tester,
    FakeVisitsRepository repo, {
    ProviderCatalogItem? provider = rappi,
    ProviderKind kind = ProviderKind.delivery,
    FakeCatalogRepository? catalog,
    ThemeMode mode = ThemeMode.light,
  }) async {
    await pumpApp(
      tester,
      // The membership provider is auto-disposed; in the app something else
      // keeps watching it, so do the same here.
      Consumer(
        builder: (context, ref, _) {
          ref.watch(selectedMembershipProvider);
          return Scaffold(
            body: TextButton(
              onPressed: () => context.push('/details'),
              child: const Text('open'),
            ),
          );
        },
      ),
      mode: mode,
      overrides: [
        ...membershipOverrides(),
        visitsRepositoryProvider.overrideWithValue(repo),
        providersCatalogRepositoryProvider.overrideWithValue(
          catalog ?? defaultCatalog(),
        ),
      ],
      routes: {
        '/details': (_) => VisitDetailsScreen(
          args: VisitDetailsArgs(kind: kind, provider: provider),
        ),
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> authorize(WidgetTester tester) async {
    await tester.tap(find.text(l10n.visitsDetailsAuthorize));
    await tester.pumpAndSettle();
  }

  testWidgets('prefilled delivery shows provider, date, time and notes', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository());
    expect(find.text(l10n.visitsDetailsTitle), findsOneWidget);
    expect(find.text(l10n.visitsNewTypeTitle), findsOneWidget);
    expect(find.text('Rappi'), findsOneWidget);
    expect(find.textContaining('Hoy,'), findsOneWidget);
    expect(find.text(l10n.visitsDetailsDateHelper), findsOneWidget);
    expect(find.text(l10n.visitsFrequentScheduleLabel), findsOneWidget);
    expect(find.text(l10n.visitsFrequentScheduleLabel), findsOneWidget);
  });

  testWidgets('authorizing creates the delivery and returns with a toast', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo);
    await tester.enterText(find.byType(TextField).last, '  Dejar en portería ');
    await authorize(tester);
    expect(repo.deliveries, hasLength(1));
    expect(repo.deliveries.single.name, 'Rappi');
    expect(repo.deliveries.single.kind, ProviderKind.delivery);
    expect(repo.deliveries.single.notes, 'Dejar en portería');
    expect(find.text('open'), findsOneWidget);
    expect(find.text(l10n.visitsDetailsAuthorizedToast), findsOneWidget);
  });

  testWidgets('failed authorization toasts the cause and stays', (
    tester,
  ) async {
    final repo = FakeVisitsRepository()..error = const NetworkFailure();
    await open(tester, repo);
    await authorize(tester);
    expect(find.text(l10n.visitsDetailsAuthorizeError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorNetwork} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    expect(find.text(l10n.visitsDetailsTitle), findsOneWidget);

    // Unknown errors only show the retry hint.
    repo.error = StateError('x');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await authorize(tester);
    expect(find.text(l10n.visitsTryAgain), findsOneWidget);
  });

  testWidgets('date picker updates the visit date', (tester) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.text(l10n.visitsFastlaneVisitDate));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsFastlaneVisitDate), findsWidgets);
    final picked = await pickNextMonthDay15(tester, l10n.commonContinue);
    expect(find.textContaining('15 '), findsWidgets);
    expect(find.textContaining('${picked.year}'), findsOneWidget);
    expect(find.textContaining('Hoy,'), findsNothing);
  });

  testWidgets('closing the date picker keeps the date', (tester) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.text(l10n.visitsFastlaneVisitDate));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hoy,'), findsOneWidget);
  });

  testWidgets('time picker: done keeps a rounded time, cancel keeps it', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.text(l10n.visitsFrequentScheduleLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsDetailsPickTime), findsNothing);

    await tester.tap(find.text(l10n.visitsFrequentScheduleLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsDetailsAuthorize), findsOneWidget);
  });

  testWidgets('proveedor has no arrival time and uses the service label', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await open(
      tester,
      repo,
      provider: plomero,
      kind: ProviderKind.proveedor,
      mode: ThemeMode.dark,
    );
    expect(find.text(l10n.visitsDetailsService), findsOneWidget);
    expect(find.text(l10n.visitsFrequentScheduleLabel), findsNothing);
    await authorize(tester);
    expect(repo.deliveries.single.kind, ProviderKind.proveedor);
    expect(repo.deliveries.single.name, 'Control de plagas');
  });

  group('provider sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Rappi'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the kind catalog, marks the current pick', (
      tester,
    ) async {
      await open(tester, FakeVisitsRepository());
      await openSheet(tester);
      expect(find.text(l10n.visitsDetailsChange), findsOneWidget);
      expect(find.text('Uber Eats'), findsOneWidget);
      expect(find.text(l10n.visitsCatalogOther), findsOneWidget);
      // "Otro" starts collapsed when something from the catalog is selected.
      expect(find.text(l10n.visitsDetailsUseName), findsNothing);
    });

    testWidgets('picking another catalog item changes the provider', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await openSheet(tester);
      await tester.tap(find.text('Uber Eats'));
      await tester.pumpAndSettle();
      expect(find.text('Uber Eats'), findsOneWidget);
      await authorize(tester);
      expect(repo.deliveries.single.name, 'Uber Eats');
    });

    testWidgets('kind tabs switch the catalog; switching kind sticks', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await openSheet(tester);
      await tester.tap(
        find.text(providerKindLabel(l10n, ProviderKind.proveedor)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Uber Eats'), findsNothing);
      await tester.tap(find.text('Control de plagas'));
      await tester.pumpAndSettle();
      // Proveedor: time field gone, label switches to service.
      expect(find.text(l10n.visitsFrequentScheduleLabel), findsNothing);
      expect(find.text(l10n.visitsDetailsService), findsOneWidget);
      await authorize(tester);
      expect(repo.deliveries.single.kind, ProviderKind.proveedor);
    });

    testWidgets('"Otro" takes a custom name', (tester) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await openSheet(tester);
      await tester.tap(find.text(l10n.visitsCatalogOther).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsDetailsUseName), findsOneWidget);
      // The confirm button is disabled until a name is typed.
      await tester.tap(find.text(l10n.visitsDetailsUseName));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsDetailsChange), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '  Mi vecino ');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsDetailsUseName));
      await tester.pumpAndSettle();
      expect(find.text('Mi vecino'), findsOneWidget);

      await authorize(tester);
      expect(repo.deliveries.single.name, 'Mi vecino');
    });

    testWidgets('"Otro" can be collapsed again', (tester) async {
      await open(tester, FakeVisitsRepository(), provider: null);
      // Opens by itself with the name entry expanded.
      expect(find.text(l10n.visitsDetailsUseName), findsOneWidget);
      await tester.tap(find.text(l10n.visitsCatalogOther).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsDetailsUseName), findsNothing);
    });

    testWidgets('catalog error shows a message and retry reloads', (
      tester,
    ) async {
      final catalog = defaultCatalog()..error = const AuthFailure();
      await open(tester, FakeVisitsRepository(), catalog: catalog);
      await openSheet(tester);
      expect(find.text(l10n.visitsCatalogLoadError), findsOneWidget);
      catalog.error = null;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('Uber Eats'), findsOneWidget);
    });
  });

  group('arrived through "Otro"', () {
    testWidgets('the sheet opens by itself and dismissing leaves "Otro"', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo, provider: null);
      expect(find.text(l10n.visitsDetailsChange), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsCatalogOther), findsOneWidget);

      // Authorizing without a name reopens the sheet.
      await authorize(tester);
      expect(find.text(l10n.visitsDetailsChange), findsOneWidget);
      expect(repo.deliveries, isEmpty);
    });

    testWidgets('typed name flows into the created visit', (tester) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo, provider: null);
      await tester.enterText(find.byType(TextField).last, 'Plomero Juan');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsDetailsUseName));
      await tester.pumpAndSettle();
      expect(find.text('Plomero Juan'), findsOneWidget);
      await authorize(tester);
      expect(repo.deliveries.single.name, 'Plomero Juan');
    });
  });

  testWidgets('back arrow pops', (tester) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.byTooltip(l10n.visitsBack));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  test('catalog fake implements the repository type', () {
    expect(defaultCatalog(), isA<ProvidersCatalogRepository>());
  });
}
