import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has any network interface up. This can't tell a
/// captive Wi-Fi without internet from a working one, so callers that reach a
/// server also treat a `NetworkFailure` as "offline".
abstract interface class ConnectivityChecker {
  Future<bool> isOnline();

  /// Emits whenever connectivity flips.
  Stream<bool> get onlineChanges;
}

class PlatformConnectivityChecker implements ConnectivityChecker {
  PlatformConnectivityChecker([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork);
}

final connectivityCheckerProvider = Provider<ConnectivityChecker>(
  (ref) => PlatformConnectivityChecker(),
);

/// Current connectivity: the initial reading followed by every change.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final checker = ref.watch(connectivityCheckerProvider);
  yield await checker.isOnline();
  yield* checker.onlineChanges;
});
