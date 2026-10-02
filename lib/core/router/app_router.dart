import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/vecinoo_brand.dart';
import '../../features/amenities/presentation/amenity_detail_screen.dart';
import '../../features/amenities/presentation/booking_result_screen.dart';
import '../../features/amenities/presentation/amenities_list_screen.dart';
import '../../features/amenities/presentation/review_booking_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/biometric_setup_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verify_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bulletins/presentation/bulletin_detail_screen.dart';
import '../../features/bulletins/presentation/bulletins_list_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/incidents/presentation/incident_detail_screen.dart';
import '../../features/incidents/presentation/incident_edit_args.dart';
import '../../features/incidents/presentation/report_incident_screen.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/session/presentation/pending_link_screen.dart';
import '../../features/session/presentation/session_controller.dart';
import '../../features/session/presentation/unit_selector_screen.dart';
import '../../features/visits/presentation/create_fastlane_visit_screen.dart';
import '../../features/visits/presentation/create_frequent_visit_screen.dart';
import '../../features/visits/presentation/create_visit_type_screen.dart';
import '../../features/visits/presentation/frequent_visit_detail_screen.dart';
import '../../features/visits/presentation/select_provider_screen.dart';
import '../../features/visits/presentation/visit_pending_detail_screen.dart';
import '../../features/visits/presentation/visit_details_screen.dart';
import '../../features/visits/domain/visit.dart';

/// Notifies GoRouter to re-run [redirect] whenever any provider that
/// gates navigation changes (auth, memberships, selected unit).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(myProfileProvider, (_, _) => notifyListeners());
    ref.listen(myMembershipsProvider, (_, _) => notifyListeners());
    ref.listen(selectedMembershipProvider, (_, _) => notifyListeners());
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Every screen goes through a [MaterialPage] explicitly: go_router's
/// automatic page choice resolves to `NoTransitionPage` here, which has no
/// slide transition and no iOS edge swipe-back.
GoRoute _route({
  required String path,
  GoRouterRedirect? redirect,
  required GoRouterWidgetBuilder builder,
}) => GoRoute(
  path: path,
  redirect: redirect,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: <String, String>{
      ...state.pathParameters,
      ...state.uri.queryParameters,
    },
    restorationId: state.pageKey.value,
    // Scaffolds are transparent (the canvas is painted once at the app
    // root), so during the slide / swipe-back both pages would show through
    // each other. Each page paints its own opaque canvas instead.
    child: GatesBackground(
      child: Builder(builder: (context) => builder(context, state)),
    ),
  ),
);

const _authRoutes = {'/login', '/register', '/verify-otp'};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: ref.watch(_routerRefreshProvider),
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final user = ref.read(currentUserProvider);

      // A router refresh (any provider change) re-resolves the current
      // location without its `extra`; a code screen with nothing to verify
      // must never be built, so route away before the builder runs.
      if (location == '/verify-otp' && state.extra is! OtpVerifyArgs) {
        return user != null ? '/' : '/login';
      }

      if (user == null) {
        return _authRoutes.contains(location) ? null : '/login';
      }

      try {
        final memberships = await ref.read(myMembershipsProvider.future);
        if (memberships.isEmpty) {
          return location == '/pending-link' ? null : '/pending-link';
        }

        final selected = await ref.read(selectedMembershipProvider.future);
        if (selected == null) {
          return location == '/select-unit' ? null : '/select-unit';
        }

        final onGateScreen =
            _authRoutes.contains(location) ||
            location == '/pending-link' ||
            location == '/select-unit';
        return onGateScreen ? '/' : null;
      } catch (e) {
        // The session can end (sign-out, expired/invalid refresh token)
        // while these awaits are in flight — e.g. fetchMine() racing a
        // sign-out throws once `currentUser` goes null mid-fetch. Treat
        // any failure here as "not signed in" instead of letting it
        // surface as an unhandled GoException that red-screens the app.
        debugPrint('Router redirect gate failed, sending to /login: $e');
        return ref.read(currentUserProvider) == null &&
                !_authRoutes.contains(location)
            ? '/login'
            : null;
      }
    },
    routes: [
      _route(path: '/login', builder: (context, state) => const LoginScreen()),
      _route(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      _route(
        path: '/verify-otp',
        // The router rebuilds this route without `extra` right after a
        // successful verification (the session appears and the gate
        // redirect is still resolving), and on hot reload / state
        // restoration. Nothing left to verify then: a signed-in user goes
        // on (the gate redirect picks the right screen), anyone else
        // restarts at login.
        redirect: (context, state) {
          if (state.extra is OtpVerifyArgs) return null;
          return ref.read(currentUserProvider) != null ? '/' : '/login';
        },
        builder: (context, state) {
          // The page can still be rebuilt from the stale match (no `extra`)
          // for a frame while the redirect above is applied; render nothing
          // rather than throwing on the cast.
          final args = state.extra;
          if (args is! OtpVerifyArgs) return const SizedBox.shrink();
          return OtpVerifyScreen(args: args);
        },
      ),
      _route(
        path: '/setup-biometrics',
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      _route(
        path: '/pending-link',
        builder: (context, state) => const PendingLinkScreen(),
      ),
      _route(
        path: '/select-unit',
        builder: (context, state) => const UnitSelectorScreen(),
      ),
      _route(
        path: '/',
        builder: (context, state) => HomeShell(
          tabRequest: state.extra is HomeTabRequest
              ? state.extra as HomeTabRequest
              : null,
        ),
      ),
      _route(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      _route(
        path: '/amenities',
        builder: (context, state) => const AmenitiesListScreen(),
      ),
      _route(
        path: '/amenities/:id',
        builder: (context, state) =>
            AmenityDetailScreen(amenityId: state.pathParameters['id']!),
      ),
      _route(
        path: '/amenities/:id/review',
        redirect: (context, state) => state.extra is ReviewBookingArgs
            ? null
            : '/amenities/${state.pathParameters['id']}',
        builder: (context, state) =>
            ReviewBookingScreen(args: state.extra as ReviewBookingArgs),
      ),
      _route(
        path: '/amenities/:id/result',
        redirect: (context, state) => state.extra is BookingResultArgs
            ? null
            : '/amenities/${state.pathParameters['id']}',
        builder: (context, state) =>
            BookingResultScreen(args: state.extra as BookingResultArgs),
      ),
      _route(
        path: '/bulletins',
        builder: (context, state) => BulletinsListScreen(
          startOnHistory: state.uri.queryParameters['tab'] == 'history',
        ),
      ),
      _route(
        path: '/bulletins/:id',
        builder: (context, state) =>
            BulletinDetailScreen(bulletinId: state.pathParameters['id']!),
      ),
      _route(
        path: '/incidents/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      _route(
        path: '/incidents/:id',
        builder: (context, state) =>
            IncidentDetailScreen(incidentId: state.pathParameters['id']!),
      ),
      _route(
        path: '/incidents/:id/edit',
        redirect: (context, state) => state.extra is IncidentEditArgs
            ? null
            : '/incidents/${state.pathParameters['id']}',
        builder: (context, state) =>
            ReportIncidentScreen(editing: state.extra as IncidentEditArgs),
      ),
      _route(
        path: '/visits/new',
        builder: (context, state) => const CreateVisitTypeScreen(),
      ),
      _route(
        path: '/visits/new/frequent',
        builder: (context, state) => const CreateFrequentVisitScreen(),
      ),
      _route(
        path: '/visits/new/delivery',
        builder: (context, state) =>
            const SelectProviderScreen(initialKind: ProviderKind.delivery),
      ),
      _route(
        path: '/visits/new/delivery/details',
        builder: (context, state) =>
            VisitDetailsScreen(args: state.extra as VisitDetailsArgs),
      ),
      _route(
        path: '/visits/new/fastlane',
        builder: (context, state) => const CreateFastlaneVisitScreen(),
      ),
      _route(
        path: '/visits/:id/access/edit',
        redirect: (context, state) => state.extra is Visit
            ? null
            : '/visits/${state.pathParameters['id']}/access',
        builder: (context, state) =>
            CreateFrequentVisitScreen(editing: state.extra as Visit),
      ),
      _route(
        path: '/visits/:id/access',
        builder: (context, state) =>
            FrequentVisitDetailScreen(visitId: state.pathParameters['id']!),
      ),
      _route(
        path: '/visits/:id',
        builder: (context, state) => VisitPendingDetailScreen(
          visitId: state.pathParameters['id']!,
          initialVisit: state.extra is Visit ? state.extra as Visit : null,
          justCreated: state.uri.queryParameters['created'] == '1',
        ),
      ),
      _route(
        path: '/visits/:id/edit',
        redirect: (context, state) => state.extra is Visit
            ? null
            : '/visits/${state.pathParameters['id']}',
        builder: (context, state) =>
            CreateFastlaneVisitScreen(editing: state.extra as Visit),
      ),
    ],
  );
});
