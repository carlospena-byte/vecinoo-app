// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incident_detail_screen.dart';
import 'package:gates_app/features/incidents/presentation/incident_edit_args.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeLauncher(this.launched);
  final List<String> launched;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  final l10n = AppLocalizationsEs();
  final launched = <String>[];

  setUp(() {
    launched.clear();
    UrlLauncherPlatform.instance = _FakeLauncher(launched);
  });

  Future<FakeIncidentsRepository> pump(
    WidgetTester tester,
    Incident incident, {
    List<IncidentAttachment> attachments = const [],
    Object? detailError,
    String? userId = 'u1',
    ThemeMode mode = ThemeMode.light,
    List<String>? visited,
    Object? cancelError,
  }) async {
    final repo = FakeIncidentsRepository()
      ..detail = incident
      ..detailError = detailError
      ..attachments = attachments
      ..cancelError = cancelError;
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => context.push('/detail'),
            child: const Text('OPEN'),
          ),
        ),
      ),
      overrides: incidentOverrides(repo, userId: userId),
      mode: mode,
      visited: visited,
      routes: {
        '/detail': (_) => IncidentDetailScreen(incidentId: incident.id),
        '/incidents/:id/edit': (s) {
          final args = s.extra as IncidentEditArgs;
          return Text('EDIT ${args.incident.id} ${args.attachments.length}');
        },
      },
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('shows summary, status, type and html description', (
    tester,
  ) async {
    await pump(
      tester,
      makeIncident(
        title: 'Foco roto',
        typeName: 'Mantenimiento',
        description: '<p>Hola <strong>mundo</strong></p><ul><li>uno</li></ul>',
        status: IncidentStatus.inProgress,
      ),
    );
    expect(find.text(l10n.incidentsDetailTitle), findsOneWidget);
    expect(find.text('Foco roto'), findsOneWidget);
    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.text(l10n.incidentsStatusInProgress), findsOneWidget);
    expect(find.text(l10n.incidentsDetailDescription), findsOneWidget);
    expect(find.textContaining('mundo', findRichText: true), findsOneWidget);
    // In progress: no edit / cancel.
    expect(find.text(l10n.incidentsEditAction), findsNothing);
    expect(find.text(l10n.incidentsCancelAction), findsNothing);
  });

  testWidgets('no description / photos sections when empty', (tester) async {
    await pump(tester, makeIncident(description: '   '));
    expect(find.text(l10n.incidentsDetailDescription), findsNothing);
    expect(find.text(l10n.incidentsDetailPhotos), findsNothing);
  });

  testWidgets('tapping a link in the description launches it', (tester) async {
    await pump(
      tester,
      makeIncident(
        description: '<p><a href="https://example.com/x">enlace</a></p>',
        status: IncidentStatus.resolved,
      ),
    );
    final rt = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText() == 'enlace',
    );
    // The paragraph spans the full width; the link text is at its start.
    await tester.tapAt(tester.getTopLeft(rt) + const Offset(10, 8));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(launched, ['https://example.com/x']);
  });

  testWidgets('history statuses are read only', (tester) async {
    for (final s in [
      IncidentStatus.resolved,
      IncidentStatus.closed,
      IncidentStatus.cancelled,
    ]) {
      await pump(tester, makeIncident(status: s));
      expect(find.text(l10n.incidentsEditAction), findsNothing);
    }
  });

  testWidgets('another reporter cannot manage a new incident', (tester) async {
    await pump(tester, makeIncident(reportedBy: 'someone-else'));
    expect(find.text(l10n.incidentsEditAction), findsNothing);
  });

  testWidgets('attachments render and open a preview dialog', (tester) async {
    await pump(
      tester,
      makeIncident(),
      attachments: const [
        IncidentAttachment(id: 'a1', storagePath: 'p/1.jpg', url: 'http://x/1'),
        IncidentAttachment(id: 'a2', storagePath: 'p/2.jpg', url: 'http://x/2'),
      ],
    );
    expect(find.text(l10n.incidentsDetailPhotos), findsOneWidget);
    final thumbs = find.bySemanticsLabel(l10n.incidentsAttachedPhoto);
    expect(thumbs, findsNWidgets(2));
    // Test HTTP returns an error, so the fallback icon is shown.
    expect(find.byIcon(TablerIcons.photoOff), findsNWidgets(2));

    await tester.tap(thumbs.first);
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    tester.takeException();
  });

  testWidgets('load error offers retry', (tester) async {
    final repo = await pump(
      tester,
      makeIncident(),
      detailError: const NetworkFailure(),
    );
    expect(find.text(l10n.incidentsDetailLoadError), findsOneWidget);
    repo.detailError = null;
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('Fuga en el pasillo'), findsOneWidget);
  });

  testWidgets('edit passes the incident and attachments to the edit route', (
    tester,
  ) async {
    final visited = <String>[];
    await pump(
      tester,
      makeIncident(),
      attachments: const [
        IncidentAttachment(id: 'a1', storagePath: 'p', url: 'http://x/1'),
      ],
      visited: visited,
    );
    await tester.tap(find.text(l10n.incidentsEditAction));
    await tester.pumpAndSettle();
    expect(visited, contains('/incidents/i1/edit'));
    expect(find.text('EDIT i1 1'), findsOneWidget);
  });

  testWidgets('cancel flow confirms in a sheet, cancels and toasts', (
    tester,
  ) async {
    final repo = await pump(tester, makeIncident());
    await tester.tap(find.text(l10n.incidentsCancelAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsCancelSheetBody), findsOneWidget);

    await tester.tap(find.text(l10n.incidentsCancelConfirm));
    await tester.pumpAndSettle();

    expect(repo.calls, ['cancel:i1']);
    expect(find.text(l10n.incidentsCancelledToast), findsOneWidget);
    // Back on the previous page.
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('dismissing the sheet does not cancel', (tester) async {
    final repo = await pump(tester, makeIncident());
    await tester.tap(find.text(l10n.incidentsCancelAction));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(find.text(l10n.incidentsCancelSheetBody), findsNothing);
  });

  testWidgets('cancel failure shows the cause in a toast', (tester) async {
    final repo = await pump(
      tester,
      makeIncident(),
      cancelError: const NetworkFailure(),
    );
    await tester.tap(find.text(l10n.incidentsCancelAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.incidentsCancelConfirm));
    await tester.pumpAndSettle();

    expect(repo.calls, ['cancel:i1']);
    expect(find.text(l10n.incidentsCancelFailedTitle), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorNetwork} ${l10n.incidentsTryAgain}'),
      findsOneWidget,
    );
    // Still on the detail.
    expect(find.text(l10n.incidentsCancelAction), findsOneWidget);
  });

  testWidgets('unknown cancel failure falls back to the generic message', (
    tester,
  ) async {
    await pump(tester, makeIncident(), cancelError: StateError('boom'));
    await tester.tap(find.text(l10n.incidentsCancelAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.incidentsCancelConfirm));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsTryAgain), findsOneWidget);
  });

  testWidgets('dark theme smoke', (tester) async {
    await pump(
      tester,
      makeIncident(description: '<p>texto</p>', typeName: 'Ruido'),
      mode: ThemeMode.dark,
    );
    expect(find.text(l10n.incidentsEditAction), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
