import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gates_app/core/widgets/gates_button.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/widgets/amenity_thumbnail.dart';
import 'package:gates_app/core/widgets/gates_add_button.dart';
import 'package:gates_app/core/widgets/gates_segmented_tabs.dart';
import 'package:gates_app/core/widgets/gates_svg_icon.dart';
import 'package:gates_app/core/widgets/gates_switch_row.dart';
import 'package:gates_app/core/widgets/gates_tap_field.dart';
import 'package:gates_app/core/widgets/gates_text_action.dart';
import 'package:gates_app/core/widgets/gates_toast.dart';
import 'package:gates_app/core/widgets/gates_upload_card.dart';
import 'package:gates_app/core/widgets/keyboard_safe_column.dart';
import 'package:gates_app/core/widgets/nav_clearance.dart';
import 'package:gates_app/core/widgets/state_views.dart';
import 'package:gates_app/core/widgets/vecinoo_brand.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '_host.dart';

final _es = AppLocalizationsEs();

void main() {
  setUpAll(loadManrope);

  testWidgets('GatesAddButton taps and exposes its semantic label', (
    tester,
  ) async {
    var taps = 0;
    await pumpHosted(
      tester,
      Center(
        child: GatesAddButton(onTap: () => taps++, semanticLabel: 'Nueva'),
      ),
    );
    await tester.tap(find.byType(GatesAddButton));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Nueva'), findsOneWidget);
  });

  group('GatesSegmentedTabs', () {
    testWidgets('selects options and marks the selected one', (tester) async {
      var selected = 'a';
      await pumpHosted(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: GatesSegmentedTabs<String>(
              selected: selected,
              onSelect: (v) => setState(() => selected = v),
              options: const [
                GatesSegmentedTabOption(value: 'a', label: 'Uno'),
                GatesSegmentedTabOption(value: 'b', label: 'Dos'),
              ],
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Uno'))
          .getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      await tester.tap(find.text('Dos'));
      await tester.pump();
      expect(selected, 'b');
    });
  });

  group('GatesSwitchRow', () {
    for (final compact in [false, true]) {
      testWidgets('toggles (compact: $compact)', (tester) async {
        bool? last;
        await pumpHosted(
          tester,
          Center(
            child: GatesSwitchRow(
              label: 'Alerta',
              description: compact ? null : 'Descripcion',
              compact: compact,
              value: false,
              onChanged: (v) => last = v,
            ),
          ),
        );
        expect(find.text('−'), findsOneWidget);
        await tester.tap(find.text('Alerta'));
        expect(last, isTrue);
        expect(find.text('Descripcion'), compact ? findsNothing : findsOne);
      });
    }

    testWidgets('on state shows a check', (tester) async {
      await pumpHosted(
        tester,
        Center(
          child: GatesSwitchRow(label: 'X', value: true, onChanged: (_) {}),
        ),
        mode: ThemeMode.dark,
      );
      expect(find.text('✓'), findsOneWidget);
    });
  });

  group('GatesUploadCard', () {
    Future<void> pump(
      WidgetTester tester,
      GatesUploadState state, {
      VoidCallback? onPick,
      VoidCallback? onRemove,
      String? fileLabel,
      String? errorDescription,
    }) => pumpHosted(
      tester,
      Center(
        child: GatesUploadCard(
          title: 'Documento',
          state: state,
          onPick: onPick ?? () {},
          onRemove: onRemove ?? () {},
          fileLabel: fileLabel,
          errorDescription: errorDescription,
        ),
      ),
      settle: false,
    );

    testWidgets('empty picks', (tester) async {
      var picked = 0;
      await pump(tester, GatesUploadState.empty, onPick: () => picked++);
      expect(find.text('Documento'), findsOneWidget);
      expect(find.text(_es.commonUploadFormats), findsOneWidget);
      await tester.tap(find.text(_es.commonUploadDocument));
      expect(picked, 1);
    });

    testWidgets('ready removes', (tester) async {
      var removed = 0;
      await pump(
        tester,
        GatesUploadState.ready,
        onRemove: () => removed++,
        fileLabel: 'a.jpg · 2 MB',
      );
      expect(find.text(_es.commonUploadReady), findsOneWidget);
      expect(find.text('a.jpg · 2 MB'), findsOneWidget);
      await tester.tap(find.text(_es.commonRemove));
      expect(removed, 1);
    });

    testWidgets('uploading shows a spinner and no action', (tester) async {
      await pump(tester, GatesUploadState.uploading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(_es.commonUploadUploading), findsOneWidget);
      expect(find.text(_es.commonUploadPreparing), findsOneWidget);
    });

    testWidgets('error offers choosing another file', (tester) async {
      var picked = 0;
      await pump(
        tester,
        GatesUploadState.error,
        onPick: () => picked++,
        errorDescription: 'Muy grande',
      );
      expect(find.text('Muy grande'), findsOneWidget);
      await tester.tap(find.text(_es.commonChooseFile));
      expect(picked, 1);
    });

    testWidgets('error default description', (tester) async {
      await pump(tester, GatesUploadState.error);
      expect(find.text(_es.commonUploadErrorDefault), findsOneWidget);
    });
  });

  group('showGatesToast', () {
    for (final type in GatesToastType.values) {
      testWidgets('renders $type with glyph and message', (tester) async {
        late BuildContext ctx;
        await pumpHosted(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox();
              },
            ),
          ),
        );
        showGatesToast(ctx, type: type, title: 'Titulo', message: 'Detalle');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Titulo'), findsOneWidget);
        expect(find.text('Detalle'), findsOneWidget);
        expect(
          find.text(switch (type) {
            GatesToastType.success => '✓',
            GatesToastType.error => '!',
            _ => 'i',
          }),
          findsOneWidget,
        );
        await tester.tap(find.text('×'));
        await tester.pumpAndSettle();
        expect(find.text('Titulo'), findsNothing);
      });
    }

    testWidgets('toast without message and dark theme', (tester) async {
      late BuildContext ctx;
      await pumpHosted(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
        mode: ThemeMode.dark,
      );
      showGatesToast(ctx, type: GatesToastType.error, title: 'Solo titulo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Solo titulo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Solo titulo'), findsNothing);
    });
  });

  group('state views', () {
    testWidgets('LoadingView shows a spinner', (tester) async {
      await pumpHosted(tester, const LoadingView(), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorView retries', (tester) async {
      var retries = 0;
      await pumpHosted(
        tester,
        ErrorView(message: 'Fallo', onRetry: () => retries++),
      );
      expect(find.text('Fallo'), findsOneWidget);
      await tester.tap(find.text(_es.commonRetry));
      expect(retries, 1);
    });

    testWidgets('ErrorView without onRetry hides the button', (tester) async {
      await pumpHosted(tester, const ErrorView(message: 'Fallo'));
      expect(find.text(_es.commonRetry), findsNothing);
    });

    testWidgets('EmptyView shows message and icon', (tester) async {
      await pumpHosted(
        tester,
        const EmptyView(message: 'Nada', icon: TablerIcons.plus),
        mode: ThemeMode.dark,
      );
      expect(find.text('Nada'), findsOneWidget);
      expect(find.byIcon(TablerIcons.plus), findsOneWidget);
    });
  });

  group('brand', () {
    testWidgets('wordmark, mark and background render in both modes', (
      tester,
    ) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpHosted(
          tester,
          const GatesBackground(
            child: Column(children: [VecinooWordmark(), VecinooMark()]),
          ),
          mode: mode,
        );
        expect(find.text('vecinoo'), findsOneWidget);
        expect(find.byType(AmbientGlow), findsOneWidget);
      }
    });

    testWidgets('GatesBackground without a child', (tester) async {
      await pumpHosted(tester, const GatesBackground(child: null));
      expect(find.byType(AmbientGlow), findsOneWidget);
    });
  });

  testWidgets('homeNavClearance adds the safe area', (tester) async {
    late double value;
    await pumpHosted(
      tester,
      Builder(
        builder: (context) {
          value = homeNavClearance(context);
          return const SizedBox();
        },
      ),
    );
    expect(value, 120);
  });

  group('KeyboardSafeColumn', () {
    testWidgets('pushes content to the bottom when it fits', (tester) async {
      await pumpHosted(
        tester,
        const Scaffold(
          body: KeyboardSafeColumn(
            padding: EdgeInsets.all(8),
            children: [Text('top'), Spacer(), Text('bottom')],
          ),
        ),
      );
      final top = tester.getTopLeft(find.text('top')).dy;
      final bottom = tester.getTopLeft(find.text('bottom')).dy;
      expect(bottom - top, greaterThan(500));
    });

    testWidgets('scrolls when content is taller than the viewport', (
      tester,
    ) async {
      await pumpHosted(
        tester,
        Scaffold(
          body: KeyboardSafeColumn(
            children: [for (var i = 0; i < 30; i++) const SizedBox(height: 60)],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('AmenityThumbnail', () {
    testWidgets('placeholder when no url', (tester) async {
      await pumpHosted(
        tester,
        const AmenityThumbnail(imageUrl: null, size: 60),
      );
      expect(find.byIcon(TablerIcons.photo), findsOneWidget);
    });

    testWidgets('falls back to the placeholder when the image fails', (
      tester,
    ) async {
      await pumpHosted(
        tester,
        const AmenityThumbnail(imageUrl: 'http://invalid.test/x.png'),
        settle: false,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(TablerIcons.photo), findsOneWidget);
    });
  });

  testWidgets('GatesSvgIcon renders an asset tinted with a token', (
    tester,
  ) async {
    await pumpHosted(
      tester,
      const GatesSvgIcon('assets/icons/home/home.svg', size: 24),
      settle: false,
    );
    expect(find.byType(GatesSvgIcon), findsOneWidget);
  });

  group('GatesTapField', () {
    testWidgets('taps, shows helper and icon', (tester) async {
      var taps = 0;
      await pumpHosted(
        tester,
        Center(
          child: GatesTapField(
            label: 'Fecha',
            value: '12 oct',
            helper: 'Ayuda',
            icon: TablerIcons.calendar,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Ayuda'), findsOneWidget);
      expect(find.byIcon(TablerIcons.calendar), findsOneWidget);
      await tester.tap(find.text('12 oct'));
      expect(taps, 1);
    });

    testWidgets('without icon or helper', (tester) async {
      await pumpHosted(
        tester,
        Center(
          child: GatesTapField(label: 'L', value: 'V', onTap: () {}),
        ),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('GatesTextAction', () {
    testWidgets('fires and renders filled/plain', (tester) async {
      var taps = 0;
      await pumpHosted(
        tester,
        Column(
          children: [
            GatesTextAction(label: 'Plano', onPressed: () => taps++),
            GatesTextAction(
              label: 'Lleno',
              filled: true,
              color: Colors.red,
              onPressed: () => taps++,
            ),
            const GatesTextAction(label: 'Off', onPressed: null),
          ],
        ),
      );
      await tester.tap(find.text('Plano'));
      await tester.tap(find.text('Lleno'));
      await tester.tap(find.text('Off'), warnIfMissed: false);
      expect(taps, 2);
    });
  });

  group('GatesButton interaction states', () {
    testWidgets('pressed primary and secondary buttons repaint', (
      tester,
    ) async {
      await pumpHosted(
        tester,
        Column(
          children: [
            GatesButton(label: 'Uno', onPressed: () {}),
            GatesButton(
              label: 'Dos',
              style: GatesButtonStyle.secondary,
              onPressed: () {},
            ),
          ],
        ),
      );
      for (final label in ['Uno', 'Dos']) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text(label)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('keyboard focus outlines the secondary button', (tester) async {
      await pumpHosted(
        tester,
        GatesButton(
          label: 'Dos',
          style: GatesButtonStyle.secondary,
          onPressed: () {},
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final side = button.style!.side!.resolve({WidgetState.focused});
      expect(side!.width, 2);
    });

    testWidgets('disabled secondary has a subtle border', (tester) async {
      await pumpHosted(
        tester,
        const GatesButton(
          label: 'Off',
          style: GatesButtonStyle.secondary,
          onPressed: null,
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(button.style!.side!.resolve({WidgetState.disabled}), isNotNull);
    });
  });
}
