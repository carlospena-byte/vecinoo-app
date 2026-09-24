import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/session_repository.dart';
import '../domain/membership.dart';

const _selectedUnitPrefsKey = 'selected_unit_id';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(supabaseClientProvider));
});

/// Refresh with `ref.invalidate(myMembershipsProvider)` after the admin
/// links this user, or when returning to the app.
final myMembershipsProvider = FutureProvider<List<Membership>>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(sessionRepositoryProvider).fetchMyMemberships();
});

/// The unit/residential the app currently acts on behalf of. Null until
/// resolved (either restored from prefs, auto-picked when there's only
/// one membership, or chosen by the user on the selector screen).
class SelectedMembershipController extends AsyncNotifier<Membership?> {
  @override
  Future<Membership?> build() async {
    final memberships = await ref.watch(myMembershipsProvider.future);
    if (memberships.isEmpty) return null;
    if (memberships.length == 1) return memberships.first;

    final prefs = await SharedPreferences.getInstance();
    final savedUnitId = prefs.getString(_selectedUnitPrefsKey);
    if (savedUnitId != null) {
      final match = memberships.where((m) => m.unitId == savedUnitId);
      if (match.isNotEmpty) return match.first;
    }
    return null; // Ambiguous — the selector screen will ask.
  }

  Future<void> select(Membership membership) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedUnitPrefsKey, membership.unitId);
    state = AsyncData(membership);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedUnitPrefsKey);
    ref.invalidateSelf();
  }
}

final selectedMembershipProvider =
    AsyncNotifierProvider<SelectedMembershipController, Membership?>(
  SelectedMembershipController.new,
);
