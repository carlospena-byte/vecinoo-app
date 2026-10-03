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
    case 'payment':
    case 'charge':
      return '/billing';
    case 'visitor_checkin':
      return _idRoute('/visits', data['visitorId']);
    case 'incident':
      return _idRoute('/incidents', data['incident_id']);
    case 'booking':
      return '/amenities';
    case 'deeplink':
      final route = data['route'];
      return route is String && _isAllowedRoute(route) ? route : null;
    default:
      return null;
  }
}

String? _idRoute(String base, Object? id) =>
    id is String && id.isNotEmpty ? '$base/${Uri.encodeComponent(id)}' : null;

/// Screens an admin-composed push (type `deeplink`) may open. The payload
/// comes from the network, so anything off this list is ignored instead of
/// being handed to the router. Keep in sync with `destinationRoute` in the
/// send-push-announcement edge function.
const _allowedPushRoutes = {
  '/bulletins',
  '/amenities',
  '/billing',
  '/incidents/report',
  '/visits/new',
  '/profile',
};

final _bulletinRoute = RegExp(r'^/bulletins/[^/?#]+$');

bool _isAllowedRoute(String route) =>
    _allowedPushRoutes.contains(route) || _bulletinRoute.hasMatch(route);
