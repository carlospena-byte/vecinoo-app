import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/core/theme/theme_mode_controller.dart';
import 'package:gates_app/core/widgets/gates_button.dart';
import 'package:gates_app/core/widgets/gates_segmented_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeStorage', () {
    test('defaults to system', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ThemeModeStorage.read(), ThemeMode.system);
    });

    test('ignores unknown stored values', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
      expect(await ThemeModeStorage.read(), ThemeMode.system);
    });

    test('controller persists the selection', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
      await container.read(themeModeProvider.notifier).select(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(await ThemeModeStorage.read(), ThemeMode.dark);
    });

    test('starts from the value loaded before runApp', () {
      final container = ProviderContainer(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('dark theme', () {
    Future<void> pump(WidgetTester tester, Widget child, ThemeMode mode) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('widgets resolve palette tokens per mode', (tester) async {
      late BuildContext ctx;
      final probe = Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      );

      await pump(tester, probe, ThemeMode.dark);
      expect(ctx.palette.bgCanvas, GatesPalette.dark.bgCanvas);
      expect(Theme.of(ctx).colorScheme.primary, GatesPalette.dark.bgBrand);

      await pump(tester, probe, ThemeMode.light);
      await tester.pumpAndSettle();
      expect(ctx.palette.bgCanvas, GatesPalette.light.bgCanvas);
      expect(Theme.of(ctx).colorScheme.primary, GatesPalette.light.bgBrand);
    });

    testWidgets('destructive button uses on-danger text, not white', (
      tester,
    ) async {
      await pump(
        tester,
        GatesButton(
          label: 'Sí, cancelar',
          style: GatesButtonStyle.destructive,
          onPressed: () {},
        ),
        ThemeMode.dark,
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bg = button.style!.backgroundColor!.resolve({});
      final fg = button.style!.foregroundColor!.resolve({});
      expect(bg, GatesPalette.dark.bgDanger);
      expect(fg, GatesPalette.dark.textOnDanger);
    });

    testWidgets('selected tab is outlined, not just filled', (tester) async {
      await pump(
        tester,
        GatesSegmentedTabs<int>(
          options: const [
            GatesSegmentedTabOption(value: 0, label: 'A'),
            GatesSegmentedTabOption(value: 1, label: 'B'),
          ],
          selected: 0,
          onSelect: (_) {},
        ),
        ThemeMode.dark,
      );
      final pills = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.shape is StadiumBorder);
      final selected = pills.firstWhere(
        (m) => m.color == GatesPalette.dark.bgBrand,
      );
      expect(
        (selected.shape! as StadiumBorder).side.color,
        GatesPalette.dark.borderSelectedBrand,
      );
    });
  });
}
