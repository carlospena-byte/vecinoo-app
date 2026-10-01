import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/env/env.dart';
import 'package:gates_app/core/notifications/push_notification_service.dart';
import 'package:gates_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Env', () {
    test('reads the Supabase settings from dotenv', () {
      dotenv.loadFromString(
        envString:
            'SUPABASE_URL=http://127.0.0.1:54321\n'
            'SUPABASE_PUBLISHABLE_KEY=pk_test\n',
      );
      expect(Env.supabaseUrl, 'http://127.0.0.1:54321');
      expect(Env.supabasePublishableKey, 'pk_test');
    });

    test('publicAppUrl defaults, and can be overridden', () {
      dotenv.loadFromString(envString: 'SUPABASE_URL=x\n');
      expect(Env.publicAppUrl, 'https://admin.vecinoo.app/');
      dotenv.loadFromString(
        envString: 'PUBLIC_APP_URL=https://example.test/\n',
      );
      expect(Env.publicAppUrl, 'https://example.test/');
    });

    test('a missing required key throws', () {
      dotenv.loadFromString(envString: 'OTHER=1');
      expect(() => Env.supabaseUrl, throwsA(isA<AssertionError>()));
      expect(() => Env.supabasePublishableKey, throwsA(isA<AssertionError>()));
    });
  });

  group('GatesPalette', () {
    test('lerp at the ends returns the endpoints', () {
      final a = GatesPalette.light.lerp(GatesPalette.dark, 0);
      final b = GatesPalette.light.lerp(GatesPalette.dark, 1);
      expect(a.bgCanvas, GatesPalette.light.bgCanvas);
      expect(b.bgCanvas, GatesPalette.dark.bgCanvas);
      expect(b.toneInfo.foreground, GatesPalette.dark.toneInfo.foreground);
      expect(b.glowOpacity, closeTo(GatesPalette.dark.glowOpacity, 1e-9));
    });

    test('lerp halfway blends colours and tones', () {
      final mid = GatesPalette.light.lerp(GatesPalette.dark, 0.5);
      expect(
        mid.textPrimary,
        Color.lerp(
          GatesPalette.light.textPrimary,
          GatesPalette.dark.textPrimary,
          0.5,
        ),
      );
      expect(
        mid.tonePending.background,
        Color.lerp(
          GatesPalette.light.tonePending.background,
          GatesPalette.dark.tonePending.background,
          0.5,
        ),
      );
    });

    test('lerp with a foreign extension keeps this palette', () {
      expect(GatesPalette.light.lerp(null, 0.5), same(GatesPalette.light));
    });

    test('copyWith returns an equal palette', () {
      expect(GatesPalette.dark.copyWith(), same(GatesPalette.dark));
    });

    test('GatesTone.lerp blends every channel', () {
      const a = GatesTone(
        background: Color(0xFF000000),
        border: Color(0xFF000000),
        foreground: Color(0xFF000000),
      );
      const b = GatesTone(
        background: Color(0xFFFFFFFF),
        border: Color(0xFFFFFFFF),
        foreground: Color(0xFFFFFFFF),
      );
      final mid = GatesTone.lerp(a, b, 1);
      expect(mid.background, const Color(0xFFFFFFFF));
      expect(mid.border, const Color(0xFFFFFFFF));
      expect(mid.foreground, const Color(0xFFFFFFFF));
    });
  });

  group('theme extension fallback', () {
    testWidgets('a plain MaterialApp resolves the stock palettes', (
      tester,
    ) async {
      late GatesPalette light;
      late GatesPalette dark;
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              light = context.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              dark = context.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(light, same(GatesPalette.light));
      expect(dark, same(GatesPalette.dark));
    });

    testWidgets('AppTheme themes expose the palette and gatesText', (
      tester,
    ) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        late GatesPalette palette;
        late TextStyle caption;
        late TextStyle labelSecondary;
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            home: Builder(
              builder: (context) {
                palette = context.palette;
                caption = context.gatesText.caption;
                labelSecondary = context.gatesText.labelSecondary;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(theme.extension<GatesPalette>(), isNotNull);
        expect(caption.color, palette.textSecondary);
        expect(labelSecondary.color, palette.textSecondary);
        expect(theme.colorScheme.primary, palette.bgBrand);
      }
    });
  });

  group('dark theme component themes resolve per state', () {
    test('switch, dialog and popup follow the palette', () {
      final theme = AppTheme.dark();
      const p = GatesPalette.dark;
      final selected = <WidgetState>{WidgetState.selected};
      final idle = <WidgetState>{};
      final sw = theme.switchTheme;
      expect(sw.trackColor!.resolve(selected), p.bgBrand);
      expect(sw.trackColor!.resolve(idle), p.bgSubtle);
      expect(sw.trackOutlineColor!.resolve(selected), p.bgBrand);
      expect(sw.trackOutlineColor!.resolve(idle), p.borderDefault);
      expect(sw.thumbColor!.resolve(selected), p.textOnBrand);
      expect(sw.thumbColor!.resolve(idle), p.knobOff);
      expect(theme.dialogTheme.backgroundColor, p.bgElevated);
      expect(theme.popupMenuTheme.color, p.bgElevated);
      expect(theme.bottomSheetTheme.backgroundColor, p.bgElevated);
    });

    test('light theme keeps Material defaults for those components', () {
      final theme = AppTheme.light();
      expect(theme.dialogTheme.backgroundColor, isNull);
      expect(theme.bottomSheetTheme.backgroundColor, isNull);
    });
  });

  group('PushNotificationService', () {
    test('syncTokenWithBackend is a no-op without token or session', () async {
      PushNotificationService.deviceToken = null;
      final client = SupabaseClient('http://localhost:54321', 'anon');
      addTearDown(client.dispose);
      await PushNotificationService.syncTokenWithBackend(client);

      PushNotificationService.deviceToken = 'token';
      // Token but no signed-in user: still nothing to upsert.
      await PushNotificationService.syncTokenWithBackend(client);
      PushNotificationService.deviceToken = null;
    });

    test('the background handler tries to boot Firebase when needed', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // No Firebase platform plugin in unit tests: initializeApp fails, which
      // proves the handler took the "no app yet" branch.
      await expectLater(
        firebaseMessagingBackgroundHandler(const RemoteMessage()),
        throwsA(anything),
      );
    });

    test('initialize swallows platform failures instead of throwing', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await PushNotificationService.initialize(
        onForegroundMessage: (_) {},
        onNotificationTap: (_) {},
      );
      expect(PushNotificationService.deviceToken, isNull);
    });
  });
}
