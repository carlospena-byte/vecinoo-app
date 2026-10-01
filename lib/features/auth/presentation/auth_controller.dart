import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Emits the signed-in user (null once signed out) on every auth change
/// (sign in, sign out, token refresh) so the router can redirect
/// accordingly.
final authStateChangesProvider = StreamProvider<SignedInUser?>((ref) {
  return ref.watch(authRepositoryProvider).userChanges;
});

/// The current signed-in user, or null. Derived from the stream above but
/// also seeded with the current session so the first frame is correct.
final currentUserProvider = Provider<SignedInUser?>((ref) {
  final streamed = ref.watch(authStateChangesProvider).value;
  return streamed ?? ref.watch(authRepositoryProvider).currentUser;
});

/// Joins a failure's explanation (if any) in front of the screen's own
/// message, so the original copy stays as the fallback.
String withFailureDetail(String? detail, String fallback) =>
    detail == null ? fallback : '$detail $fallback';

/// Signs out; on failure shows an error toast instead of dropping it.
Future<void> signOutReportingErrors(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authRepositoryProvider).signOut();
  } catch (error) {
    if (!context.mounted) return;
    showGatesToast(
      context,
      type: GatesToastType.error,
      title: context.l10n.commonLogout,
      message: failureDetail(context.l10n, Failure.from(error)),
    );
  }
}
