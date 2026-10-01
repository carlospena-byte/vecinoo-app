import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env/env.dart';
import 'core/error/provider_retry.dart';
import 'l10n/l10n.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/vecinoo_brand.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('es');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  await PushNotificationService.initialize();
  final themeMode = await ThemeModeStorage.read();
  runApp(
    ProviderScope(
      retry: providerRetry,
      overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
      child: const GatesApp(),
    ),
  );
}

class GatesApp extends ConsumerWidget {
  const GatesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // The device token can arrive (async, from Firebase) before or after
    // login, in either order, so both PushNotificationService.initialize()
    // and every auth state change try the sync — whichever happens last
    // is the one that actually has both pieces and succeeds.
    ref.listen(authStateChangesProvider, (_, _) {
      PushNotificationService.syncTokenWithBackend(
        ref.read(supabaseClientProvider),
      );
    });
    return MaterialApp.router(
      title: 'Gates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Spanish only for now; also the fallback for any other device locale.
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      routerConfig: router,
      builder: (context, child) => GatesBackground(child: child),
    );
  }
}
