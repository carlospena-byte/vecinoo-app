import 'package:flutter/foundation.dart';

/// Where a tapped push notification should take the user.
///
/// Kept free of Firebase imports so it can be unit-tested. The tap can
/// arrive before the router is ready (cold start) or before the user is
/// signed in, so [PushNavigation.pendingRoute] holds the destination until
/// `HomeShell` — which only exists once there is a session and a selected
/// unit — opens it.
class PushNavigation {
  PushNavigation._();

  static final ValueNotifier<String?> pendingRoute = ValueNotifier(null);
}

/// Maps a push `data` payload to an in-app route, or null when the
/// notification has no destination (or one this app version doesn't know).
String? notificationRoute(Map<String, dynamic> data) {
  switch (data['type']) {
    case 'bulletin':
      final id = data['bulletin_id'];
      if (id is String && id.isNotEmpty) {
        return '/bulletins/${Uri.encodeComponent(id)}';
      }
      return null;
    default:
      return null;
  }
}
