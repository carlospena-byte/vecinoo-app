import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('fetchMine called with no signed-in user');
    final row = await _client.from('profiles').select().eq('user_id', userId).single();
    return Profile.fromMap(row);
  }

  Future<void> updateMine({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('updateMine called with no signed-in user');
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('user_id', userId);
  }
}
