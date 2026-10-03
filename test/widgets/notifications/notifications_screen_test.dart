import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/notifications/presentation/notifications_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

final _es = AppLocalizationsEs();

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  testWidgets('empty inbox shows the empty state', (tester) async {
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: notificationOverrides(),
    );
    expect(find.text(_es.notificationsEmpty), findsOneWidget);
  });

  testWidgets('load failure offers a retry', (tester) async {
    final repo = FakeNotificationsRepository()
      ..listError = const NetworkFailure();
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: notificationOverrides(repo),
    );
    expect(find.text(_es.notificationsLoadError), findsOneWidget);
    expect(find.text(_es.commonRetry), findsOneWidget);
  });

  testWidgets('splits unread and read; tapping opens and moves to history', (
    tester,
  ) async {
    final now = DateTime.now();
    final repo = FakeNotificationsRepository()
      ..notifications = [
        makeNotification(id: 'a', title: 'Sin leer', createdAt: now),
        makeNotification(
          id: 'b',
          title: 'Ya leída',
          type: 'payment',
          data: {'type': 'payment'},
          createdAt: now.subtract(const Duration(days: 5)),
          readAt: now,
        ),
      ];
    final visited = <String>[];
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: notificationOverrides(repo),
      visited: visited,
      routes: {'/bulletins/:id': (_) => const Text('bulletin-route')},
    );

    expect(find.text('Sin leer'), findsOneWidget);
    expect(find.text('Ya leída'), findsNothing);

    await tester.tap(find.text(_es.notificationsTabHistory));
    await tester.pumpAndSettle();
    expect(find.text('Sin leer'), findsNothing);
    expect(find.text('Ya leída'), findsOneWidget);

    await tester.tap(find.text(_es.notificationsTabNew));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin leer'));
    await tester.pumpAndSettle();
    expect(visited, ['/bulletins/b1']);
    expect(repo.markedRead, ['a']);
  });

  testWidgets('everything read: Nuevas is empty, Historial lists them', (
    tester,
  ) async {
    final repo = FakeNotificationsRepository()
      ..notifications = [makeNotification(readAt: DateTime.now())];
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: notificationOverrides(repo),
    );
    expect(find.text(_es.notificationsEmptyNew), findsOneWidget);
    await tester.tap(find.text(_es.notificationsTabHistory));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo boletín'), findsOneWidget);
  });

  testWidgets('mark all read hides the action', (tester) async {
    final repo = FakeNotificationsRepository()
      ..notifications = [makeNotification()];
    await pumpApp(
      tester,
      const NotificationsScreen(),
      overrides: notificationOverrides(repo),
    );
    await tester.tap(find.text(_es.notificationsMarkAllRead));
    await tester.pumpAndSettle();
    expect(repo.markAllCalls, 1);
    expect(find.text(_es.notificationsMarkAllRead), findsNothing);
    expect(find.text(_es.notificationsEmptyNew), findsOneWidget);
  });
}
