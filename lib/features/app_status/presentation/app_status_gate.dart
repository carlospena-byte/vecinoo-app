import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_providers.dart';
import 'app_status_controller.dart';
import 'maintenance_screen.dart';
import 'no_connection_screen.dart';
import 'update_screen.dart';

/// Covers the app with the platform-level status screens, in priority order:
/// no connection, maintenance, update (forced or optional). Re-checks when
/// the app returns to the foreground and when connectivity comes back.
///
/// Installed once via `MaterialApp.builder`, above the router, so these
/// screens also show to signed-out users.
class AppStatusGate extends ConsumerStatefulWidget {
  const AppStatusGate({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<AppStatusGate> createState() => _AppStatusGateState();
}

class _AppStatusGateState extends ConsumerState<AppStatusGate>
    with WidgetsBindingObserver {
  /// Safety net for a dropped realtime socket: maintenance still lands
  /// within a minute.
  static const _pollInterval = Duration(minutes: 1);

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(_pollInterval, (_) => _recheck());
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  void _recheck() => ref.invalidate(appStatusControllerProvider);

  @override
  Widget build(BuildContext context) {
    // Maintenance or a release changed in the admin while the app is open.
    ref.listen(appConfigChangesProvider, (_, next) {
      if (next.hasValue) _recheck();
    });
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) _recheck();
    });

    final online = ref.watch(isOnlineProvider).value;
    final statusAsync = ref.watch(appStatusControllerProvider);
    final dismissed = ref.watch(dismissedUpdateProvider);
    final state = statusAsync.value;

    final Widget? overlay;
    if (online == false || (state?.unreachable ?? false)) {
      overlay = NoConnectionScreen(
        onRetry: _recheck,
        retrying: statusAsync.isLoading,
      );
    } else if (state == null) {
      // First answer pending: show nothing rather than flash the app and
      // then cover it with a maintenance screen.
      return const SizedBox.shrink();
    } else if (state.status.maintenance.enabled) {
      overlay = MaintenanceScreen(
        info: state.status.maintenance,
        onRetry: _recheck,
      );
    } else if (state.status.update case final update?
        when update.isForced || update.version != dismissed) {
      overlay = UpdateScreen(
        info: update,
        onContinue: () =>
            ref.read(dismissedUpdateProvider.notifier).dismiss(update.version),
      );
    } else {
      overlay = null;
    }

    return Stack(
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }
}
