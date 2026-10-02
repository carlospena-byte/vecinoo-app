import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_app_status_repository.dart';
import '../domain/app_status.dart';
import '../domain/app_status_repository.dart';

final appStatusRepositoryProvider = Provider<AppStatusRepository>((ref) {
  return SupabaseAppStatusRepository(ref.watch(supabaseClientProvider));
});

/// Store platform this build ships to: releases are tracked per platform.
final appPlatformProvider = Provider<String>(
  (ref) => !kIsWeb && Platform.isIOS ? 'ios' : 'android',
);

class AppStatusState {
  const AppStatusState({required this.status, this.unreachable = false});

  final AppStatus status;

  /// The server couldn't be reached and there is no earlier answer to fall
  /// back on, so the app can't tell if it is in maintenance.
  final bool unreachable;
}

/// Loads the status on launch; `ref.invalidate` it to re-check (app resume,
/// connectivity coming back, "Reintentar").
///
/// Fails open: a backend error (not a network one) never locks users out of
/// the app. Without a network, a refresh keeps the last known status.
class AppStatusController extends AsyncNotifier<AppStatusState> {
  @override
  Future<AppStatusState> build() async {
    final previous = state.value;
    try {
      final version = await ref.watch(appVersionProvider.future);
      final status = await ref
          .read(appStatusRepositoryProvider)
          .fetch(platform: ref.read(appPlatformProvider), version: version);
      return AppStatusState(status: status);
    } on NetworkFailure {
      return previous ??
          const AppStatusState(status: AppStatus.operational, unreachable: true);
    } catch (error) {
      debugPrint('[app-status] check failed, continuing: $error');
      return previous ?? const AppStatusState(status: AppStatus.operational);
    }
  }
}

final appStatusControllerProvider =
    AsyncNotifierProvider<AppStatusController, AppStatusState>(
      AppStatusController.new,
    );

/// Version whose optional "update available" screen the user already
/// dismissed in this session; it isn't shown again until a newer one exists.
class DismissedUpdateController extends Notifier<String?> {
  @override
  String? build() => null;

  void dismiss(String version) => state = version;
}

final dismissedUpdateProvider =
    NotifierProvider<DismissedUpdateController, String?>(
      DismissedUpdateController.new,
    );

/// Emits whenever a platform admin changes `app_config` (maintenance mode) or
/// `app_versions` (a new or forced release), so an app that is already open
/// reacts without waiting for a resume. Needs both tables in the
/// `supabase_realtime` publication (migrations `20261112000001_…` and
/// `20261112000002_…`).
final appConfigChangesProvider = StreamProvider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<void>();
  final channel = client
      .channel('app_status_changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_config',
        callback: (_) => controller.add(null),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_versions',
        callback: (_) => controller.add(null),
      )
      .subscribe();
  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });
  return controller.stream;
});
