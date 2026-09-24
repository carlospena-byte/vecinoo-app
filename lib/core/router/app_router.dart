import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/amenities/domain/amenity.dart';
import '../../features/amenities/presentation/amenity_booking_screen.dart';
import '../../features/amenities/presentation/my_bookings_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verify_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/incidents/presentation/report_incident_screen.dart';
import '../../features/profile/presentation/complete_profile_screen.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/session/presentation/pending_link_screen.dart';
import '../../features/session/presentation/session_controller.dart';
import '../../features/session/presentation/unit_selector_screen.dart';
import '../../features/visits/presentation/create_delivery_visit_screen.dart';
import '../../features/visits/presentation/create_fastlane_visit_screen.dart';
import '../../features/visits/presentation/create_frequent_visit_screen.dart';

/// Notifies GoRouter to re-run [redirect] whenever any provider that
/// gates navigation changes (auth, profile completeness, memberships,
/// selected unit).
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

const _authRoutes = {'/login', '/register', '/verify-otp'};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: ref.watch(_routerRefreshProvider),
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final user = ref.read(currentUserProvider);

      if (user == null) {
        return _authRoutes.contains(location) ? null : '/login';
      }

      try {
        final profile = await ref.read(myProfileProvider.future);
        if (!profile.isComplete) {
          return location == '/complete-profile' ? null : '/complete-profile';
        }

        final memberships = await ref.read(myMembershipsProvider.future);
        if (memberships.isEmpty) {
          return location == '/pending-link' ? null : '/pending-link';
        }

        final selected = await ref.read(selectedMembershipProvider.future);
        if (selected == null) {
          return location == '/select-unit' ? null : '/select-unit';
        }

        final onGateScreen = _authRoutes.contains(location) ||
            location == '/complete-profile' ||
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
        return ref.read(currentUserProvider) == null && !_authRoutes.contains(location)
            ? '/login'
            : null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => OtpVerifyScreen(args: state.extra as OtpVerifyArgs),
      ),
      GoRoute(path: '/complete-profile', builder: (context, state) => const CompleteProfileScreen()),
      GoRoute(path: '/pending-link', builder: (context, state) => const PendingLinkScreen()),
      GoRoute(path: '/select-unit', builder: (context, state) => const UnitSelectorScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/amenities/my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/amenities/:id',
        builder: (context, state) => AmenityBookingScreen(amenity: state.extra as Amenity),
      ),
      GoRoute(
        path: '/incidents/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/visits/new/frequent',
        builder: (context, state) => const CreateFrequentVisitScreen(),
      ),
      GoRoute(
        path: '/visits/new/delivery',
        builder: (context, state) => const CreateDeliveryVisitScreen(),
      ),
      GoRoute(
        path: '/visits/new/fastlane',
        builder: (context, state) => const CreateFastlaneVisitScreen(),
      ),
    ],
  );
});
