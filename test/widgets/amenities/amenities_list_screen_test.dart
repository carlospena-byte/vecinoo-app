import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/domain/amenity_card.dart';
import 'package:gates_app/features/amenities/presentation/amenities_list_screen.dart';
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
    const AmenitiesListScreen(),
    overrides: amenitiesOverrides(repository),
    mode: mode,
    visited: visited,
    settle: settle,
    routes: {'/amenities/:id': (s) => Text('detail ${s.pathParameters['id']}')},
  );

  testWidgets('shows a spinner while loading', (tester) async {
    await pump(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders empty state', (tester) async {
    await pump(tester);
    expect(find.text(l10n.amenitiesListEmpty), findsOneWidget);
    expect(find.text(l10n.amenitiesNewBooking), findsOneWidget);
  });

  testWidgets('error state offers retry which refetches', (tester) async {
    repository.listError = const NetworkFailure();
    await pump(tester);
    expect(find.text(l10n.amenitiesListLoadError), findsOneWidget);
    final before = repository.listFetches;

    repository.listError = null;
    repository.cards = [AmenityCard(amenity: makeAmenity(name: 'Gimnasio'))];
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('Gimnasio'), findsOneWidget);
    expect(repository.listFetches, before + 1);
  });

  testWidgets('lists amenities with capacity and booking badges', (
    tester,
  ) async {
    repository.cards = [
      AmenityCard(amenity: makeAmenity(name: 'Salón', capacity: 30)),
      AmenityCard(
        amenity: makeAmenity(id: 'a2', name: 'Jardín', requiresBooking: false),
      ),
    ];
    await pump(tester);
    expect(find.text(l10n.amenitiesListHeading), findsOneWidget);
    expect(find.text('Salón'), findsOneWidget);
    expect(find.text(l10n.amenitiesCapacity(30)), findsOneWidget);
    expect(find.text(l10n.amenitiesBookingRequiredBadge), findsOneWidget);
    expect(find.text('Jardín'), findsOneWidget);
    expect(find.text(l10n.amenitiesNoBookingBadge), findsOneWidget);
    // Cards without a photo fall back to the placeholder tile.
    expect(find.byIcon(TablerIcons.photo), findsNWidgets(2));
  });

  testWidgets('tapping a card opens its detail route', (tester) async {
    repository.cards = [AmenityCard(amenity: makeAmenity(id: 'abc'))];
    final visited = <String>[];
    await pump(tester, visited: visited);
    await tester.tap(find.text('Salón de eventos'));
    await tester.pumpAndSettle();
    expect(visited, ['/amenities/abc']);
    expect(find.text('detail abc'), findsOneWidget);
  });

  testWidgets('pull to refresh refetches', (tester) async {
    repository.cards = [AmenityCard(amenity: makeAmenity())];
    await pump(tester);
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repository.listFetches, 2);
  });

  testWidgets('dark theme smoke', (tester) async {
    repository.cards = [AmenityCard(amenity: makeAmenity(capacity: 5))];
    await pump(tester, mode: ThemeMode.dark);
    expect(find.text('Salón de eventos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
