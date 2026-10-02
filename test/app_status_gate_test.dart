import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/app_info.dart';
import 'package:gates_app/core/connectivity/connectivity_providers.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/app_status/domain/app_status.dart';
import 'package:gates_app/features/app_status/domain/app_status_repository.dart';
import 'package:gates_app/features/app_status/presentation/app_status_controller.dart';
import 'package:gates_app/features/app_status/presentation/app_status_gate.dart';

import 'helpers/pump_app.dart';

class _FakeRepo implements AppStatusRepository {
  _FakeRepo(this.result);

  Object result; // AppStatus or Failure
  int calls = 0;
  String? lastPlatform;
  String? lastVersion;

  @override
  Future<AppStatus> fetch({
    required String platform,
    required String version,
  }) async {
    calls++;
    lastPlatform = platform;
    lastVersion = version;
    final r = result;
    if (r is Failure) throw r;
    return r as AppStatus;
  }
}

const _optional = UpdateInfo(
  version: '1.2.0',
  isForced: false,
  storeUrl: 'https://example.com/store',
);
const _forced = UpdateInfo(
  version: '1.3.0',
  isForced: true,
  storeUrl: 'https://example.com/store',
);

final changes = StreamController<void>.broadcast();

List<Override> _overrides(_FakeRepo repo, {bool online = true}) => [
  appStatusRepositoryProvider.overrideWithValue(repo),
  appVersionProvider.overrideWith((_) async => '1.0.0'),
  appPlatformProvider.overrideWithValue('ios'),
  isOnlineProvider.overrideWith((_) => Stream.value(online)),
  appConfigChangesProvider.overrideWith((_) => changes.stream),
];

Future<void> _pump(WidgetTester tester, _FakeRepo repo, {bool online = true}) =>
    pumpApp(
      tester,
      const AppStatusGate(child: Scaffold(body: Text('APP'))),
      overrides: _overrides(repo, online: online),
    );

void main() {
  group('AppStatus.fromMap', () {
    test('parses maintenance and update, blank text becomes null', () {
      final status = AppStatus.fromMap({
        'maintenance': {'enabled': true, 'title': '  ', 'message': 'Vuelve pronto'},
        'update': {
          'version': '1.2.0',
          'is_forced': true,
          'title': null,
          'message': null,
          'store_url': 'https://x',
        },
      });
      expect(status.maintenance.enabled, isTrue);
      expect(status.maintenance.title, isNull);
      expect(status.maintenance.message, 'Vuelve pronto');
      expect(status.update!.isForced, isTrue);
      expect(status.update!.storeUrl, 'https://x');
    });

    test('no update and missing maintenance map means operational', () {
      final status = AppStatus.fromMap({'maintenance': null, 'update': null});
      expect(status.maintenance.enabled, isFalse);
      expect(status.update, isNull);
    });
  });

  group('AppStatusGate', () {
    testWidgets('shows the app when nothing is pending', (tester) async {
      final repo = _FakeRepo(AppStatus.operational);
      await _pump(tester, repo);
      expect(find.text('APP'), findsOneWidget);
      expect(repo.lastPlatform, 'ios');
      expect(repo.lastVersion, '1.0.0');
    });

    testWidgets('maintenance covers the app with the admin message', (
      tester,
    ) async {
      final repo = _FakeRepo(
        const AppStatus(
          maintenance: MaintenanceInfo(
            enabled: true,
            title: 'Volvemos pronto',
            message: 'Estamos actualizando',
          ),
        ),
      );
      await _pump(tester, repo);
      expect(find.text('Volvemos pronto'), findsOneWidget);
      expect(find.text('Estamos actualizando'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('maintenance beats an update', (tester) async {
      final repo = _FakeRepo(
        const AppStatus(
          maintenance: MaintenanceInfo(enabled: true),
          update: _forced,
        ),
      );
      await _pump(tester, repo);
      expect(find.text('Estamos en mantenimiento'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
    });

    testWidgets('optional update can be dismissed with Continuar', (
      tester,
    ) async {
      final repo = _FakeRepo(
        const AppStatus(
          maintenance: MaintenanceInfo(enabled: false),
          update: _optional,
        ),
      );
      await _pump(tester, repo);
      expect(find.text('Hay una nueva versión'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Hay una nueva versión'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('forced update has no way to continue', (tester) async {
      final repo = _FakeRepo(
        const AppStatus(
          maintenance: MaintenanceInfo(enabled: false),
          update: _forced,
        ),
      );
      await _pump(tester, repo);
      expect(find.text('Actualiza para continuar'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
    });

    testWidgets('offline device shows the connection screen', (tester) async {
      final repo = _FakeRepo(AppStatus.operational);
      await _pump(tester, repo, online: false);
      expect(find.text('Revisa tu conexión a internet'), findsOneWidget);
    });

    testWidgets('unreachable server shows the connection screen and retries', (
      tester,
    ) async {
      final repo = _FakeRepo(const NetworkFailure());
      await _pump(tester, repo);
      expect(find.text('Revisa tu conexión a internet'), findsOneWidget);

      repo.result = AppStatus.operational;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('maintenance switched on while the app is open blocks it', (
      tester,
    ) async {
      final repo = _FakeRepo(AppStatus.operational);
      await _pump(tester, repo);
      expect(find.text('APP'), findsOneWidget);

      repo.result = const AppStatus(maintenance: MaintenanceInfo(enabled: true));
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Estamos en mantenimiento'), findsOneWidget);

      repo.result = AppStatus.operational;
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('a backend error fails open instead of blocking the app', (
      tester,
    ) async {
      final repo = _FakeRepo(const ServerFailure());
      await _pump(tester, repo);
      expect(find.text('APP'), findsOneWidget);
    });
  });
}
