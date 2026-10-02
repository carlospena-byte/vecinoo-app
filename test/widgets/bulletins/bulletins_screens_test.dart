// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/bulletins/domain/bulletin.dart';
import 'package:gates_app/features/bulletins/presentation/bulletin_detail_screen.dart';
import 'package:gates_app/features/bulletins/presentation/bulletin_media_screens.dart';
import 'package:gates_app/features/bulletins/presentation/bulletins_list_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';
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

  group('BulletinsListScreen', () {
    Future<FakeBulletinsRepository> pump(
      WidgetTester tester, {
      List<Bulletin> data = const [],
      Object? error,
      List<String>? visited,
      ThemeMode mode = ThemeMode.light,
      Set<String> read = const {},
    }) async {
      final repo = FakeBulletinsRepository()
        ..bulletins = data
        ..listError = error;
      await pumpApp(
        tester,
        const BulletinsListScreen(),
        overrides: bulletinOverrides(repo, FakeBulletinReadsRepository(read)),
        visited: visited,
        mode: mode,
        routes: {
          '/bulletins/:id': (s) => Text('DETAIL ${s.pathParameters['id']}'),
        },
      );
      return repo;
    }

    testWidgets('lists bulletins with date, excerpt and attachment counts', (
      tester,
    ) async {
      await pump(
        tester,
        data: [
          makeBulletin(
            id: 'a',
            title: 'Corte de agua',
            description: '<p>Mañana de <strong>8 a 12</strong></p>',
            imageCount: 2,
            pdfCount: 1,
          ),
          makeBulletin(id: 'b', title: 'Asamblea'),
        ],
      );
      expect(find.text(l10n.bulletinsTitle), findsOneWidget);
      expect(find.text('Corte de agua'), findsOneWidget);
      expect(find.text('Asamblea'), findsOneWidget);
      expect(find.text('Mañana de 8 a 12'), findsOneWidget);
      expect(find.text(l10n.bulletinsImageCount(2)), findsOneWidget);
      expect(find.text(l10n.bulletinsPdfCount(1)), findsOneWidget);
    });

    testWidgets('tapping a bulletin opens its detail', (tester) async {
      final visited = <String>[];
      await pump(
        tester,
        data: [makeBulletin(id: 'abc', title: 'Asamblea')],
        visited: visited,
      );
      await tester.tap(find.text('Asamblea'));
      await tester.pumpAndSettle();
      expect(visited, ['/bulletins/abc']);
      expect(find.text('DETAIL abc'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pump(tester);
      expect(find.text(l10n.bulletinsEmpty), findsOneWidget);
    });

    testWidgets('unread bulletins are "Nuevos", read ones "Historial"', (
      tester,
    ) async {
      await pump(
        tester,
        data: [
          makeBulletin(id: 'a', title: 'Sin leer'),
          makeBulletin(id: 'b', title: 'Ya leído'),
        ],
        read: {'b'},
      );
      expect(find.text(l10n.bulletinsTabNew), findsOneWidget);
      expect(find.text(l10n.bulletinsTabHistory), findsOneWidget);
      expect(find.text('Sin leer'), findsOneWidget);
      expect(find.text('Ya leído'), findsNothing);

      await tester.tap(find.text(l10n.bulletinsTabHistory));
      await tester.pumpAndSettle();
      expect(find.text('Ya leído'), findsOneWidget);
      expect(find.text('Sin leer'), findsNothing);
    });

    testWidgets('"Nuevos" says so when everything was read', (tester) async {
      await pump(
        tester,
        data: [makeBulletin(id: 'a')],
        read: {'a'},
      );
      expect(find.text(l10n.bulletinsEmptyNew), findsOneWidget);
    });

    testWidgets('"Historial" says so when nothing was read', (tester) async {
      await pump(tester, data: [makeBulletin(id: 'a')]);
      await tester.tap(find.text(l10n.bulletinsTabHistory));
      await tester.pumpAndSettle();
      expect(find.text(l10n.bulletinsEmptyHistory), findsOneWidget);
    });

    testWidgets('loads 10 at a time as the list scrolls', (tester) async {
      final repo = await pump(
        tester,
        data: [
          for (var i = 0; i < 25; i++)
            makeBulletin(id: 'b$i', title: 'Aviso $i'),
        ],
      );
      expect(repo.offsets, [0]);
      expect(find.text('Aviso 0'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(repo.offsets.take(2), [0, 10]);

      await tester.drag(find.byType(ListView).first, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(repo.offsets, [0, 10, 20]);

      // The short last page (5 of 10) ended the paging.
      await tester.drag(find.byType(ListView).first, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(repo.offsets, [0, 10, 20]);
    });

    testWidgets('a short tab pulls more pages until it fills', (tester) async {
      final repo = await pump(
        tester,
        data: [
          for (var i = 0; i < 25; i++)
            makeBulletin(id: 'b$i', title: 'Aviso $i'),
        ],
        read: {for (var i = 0; i < 20; i++) 'b$i'},
      );
      // The first two pages are all read, so "Nuevos" keeps asking.
      expect(repo.offsets, [0, 10, 20]);
      expect(find.text('Aviso 20'), findsOneWidget);
    });

    testWidgets('a failing next page shows a retry footer', (tester) async {
      final repo = await pump(
        tester,
        data: [
          for (var i = 0; i < 12; i++)
            makeBulletin(id: 'b$i', title: 'Aviso $i'),
        ],
      );
      repo.listError = const NetworkFailure();
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text(l10n.commonLoadMoreError), findsWidgets);

      repo.listError = null;
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonRetry).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.commonLoadMoreError), findsNothing);
    });

    testWidgets('load error offers a retry that refetches', (tester) async {
      final repo = await pump(tester, error: const NetworkFailure());
      expect(find.text(l10n.bulletinsListLoadError), findsOneWidget);
      repo.listError = null;
      repo.bulletins = [makeBulletin(title: 'Ya cargó')];
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('Ya cargó'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await pump(
        tester,
        data: [makeBulletin(imageCount: 1)],
        mode: ThemeMode.dark,
      );
      expect(find.text('Corte de agua'), findsOneWidget);
    });
  });

  group('BulletinDetailScreen', () {
    Future<void> pump(
      WidgetTester tester,
      Bulletin bulletin, {
      List<BulletinAttachment> attachments = const [],
      Object? detailError,
      FakeBulletinReadsRepository? reads,
    }) async {
      final repo = FakeBulletinsRepository()
        ..detail = bulletin
        ..detailError = detailError
        ..attachments = attachments;
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
        overrides: bulletinOverrides(repo, reads),
        routes: {
          '/detail': (_) => BulletinDetailScreen(bulletinId: bulletin.id),
        },
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows title, date and html description', (tester) async {
      await pump(
        tester,
        makeBulletin(description: '<p>Hola <strong>vecinos</strong></p>'),
      );
      expect(find.text(l10n.bulletinsDetailTitle), findsOneWidget);
      expect(find.text('Corte de agua'), findsOneWidget);
      expect(
        find.textContaining('vecinos', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(l10n.bulletinsDocumentsSection), findsNothing);
    });

    testWidgets('lists a PDF that opens in the in-app reader on tap', (
      tester,
    ) async {
      await pump(
        tester,
        makeBulletin(pdfCount: 1),
        attachments: const [
          BulletinAttachment(
            id: 'p1',
            kind: BulletinAttachmentKind.pdf,
            fileName: 'Reglamento.pdf',
            url: 'https://files.test/reglamento.pdf',
          ),
        ],
      );
      expect(find.text(l10n.bulletinsDocumentsSection), findsOneWidget);
      await tester.tap(find.text('Reglamento.pdf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BulletinPdfScreen), findsOneWidget);
      expect(launched, isEmpty);
    });

    testWidgets('opening a bulletin marks it as read', (tester) async {
      final reads = FakeBulletinReadsRepository();
      await pump(tester, makeBulletin(id: 'zz'), reads: reads);
      expect(reads.read, {'zz'});
    });

    testWidgets('a bulletin that fails to load stays unread', (tester) async {
      final reads = FakeBulletinReadsRepository();
      await pump(
        tester,
        makeBulletin(id: 'zz'),
        detailError: const NetworkFailure(),
        reads: reads,
      );
      expect(reads.read, isEmpty);
    });

    testWidgets('images render at the full screen width', (tester) async {
      await pump(
        tester,
        makeBulletin(imageCount: 1),
        attachments: const [
          BulletinAttachment(
            id: 'i1',
            kind: BulletinAttachmentKind.image,
            fileName: 'foto.png',
            url: 'https://files.test/foto.png',
          ),
        ],
      );
      expect(tester.getSize(find.byType(Image)).width, 390);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == l10n.bulletinsAttachedImage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('a bulletin that is gone shows the load error', (tester) async {
      await pump(tester, makeBulletin(), detailError: const NetworkFailure());
      expect(find.text(l10n.bulletinsDetailLoadError), findsOneWidget);
    });
  });
}
