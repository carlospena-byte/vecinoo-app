import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

/// Refresh with `ref.invalidate(myProfileProvider)` after an update.
final myProfileProvider = FutureProvider<Profile>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(profileRepositoryProvider).fetchMine();
});
