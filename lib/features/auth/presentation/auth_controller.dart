import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Emits every auth change (sign in, sign out, token refresh) so the
/// router can redirect accordingly.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The current signed-in user, or null. Derived from the stream above but
/// also seeded with the current session so the first frame is correct.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState?.session?.user ??
      ref.watch(authRepositoryProvider).currentUser;
});
