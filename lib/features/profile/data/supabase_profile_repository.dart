import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

/// Supabase-backed [ProfileRepository]; every call surfaces errors as
/// `Failure`s.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile> fetchMine() => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return Profile.fromMap(row);
  });

  @override
  Future<void> updateMine({
    String? firstName,
    String? lastName,
    String? phone,
  }) => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('user_id', userId);
  });
}
