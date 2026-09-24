import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/membership.dart';

/// Where a resident is headed once they finish registering, from
/// validate_unit_invitation — shown as a confirmation before they choose
/// how to create their account.
class InvitationPreview {
  const InvitationPreview({required this.unitName, required this.residentialName});

  factory InvitationPreview.fromMap(Map<String, dynamic> map) => InvitationPreview(
        unitName: map['unit_name'] as String,
        residentialName: map['residential_name'] as String,
      );

  final String unitName;
  final String residentialName;
}

class SessionRepository {
  SessionRepository(this._client);

  final SupabaseClient _client;

  /// Checks an invitation code against the email that received it,
  /// *before* the resident picks an email or SMS code to sign in with —
  /// so registration is gated on a real invitation from the start instead
  /// of only being checked afterwards. Doesn't require a session
  /// (callable by `anon`) and doesn't consume the code; throws with the
  /// Postgres RAISE EXCEPTION message on an invalid, used, or expired
  /// code.
  Future<InvitationPreview> validateInvitation({
    required String email,
    required String code,
  }) async {
    final rows = await _client.rpc('validate_unit_invitation', params: {
      '_email': email,
      '_code': code,
    });
    final row = (rows as List).first as Map<String, dynamic>;
    return InvitationPreview.fromMap(row);
  }

  /// The units (and their residential) the current user belongs to.
  /// Empty means the resident has signed up but an admin hasn't linked
  /// them to a unit yet.
  Future<List<Membership>> fetchMyMemberships() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('fetchMyMemberships called with no signed-in user');
    final rows = await _client
        .from('unit_members')
        .select('units(id, name, residential_id, residentials(id, name))')
        .eq('user_id', userId);
    return (rows as List)
        .map((row) => Membership.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Consumes an invitation code an admin created in gates-admin, linking
  /// the current user to that unit via unit_members (see
  /// accept_unit_invitation in 20261001000000_unit_invitations.sql).
  /// Throws with the Postgres RAISE EXCEPTION message on an invalid,
  /// used, or expired code.
  Future<void> acceptInvitation(String code) async {
    await _client.rpc('accept_unit_invitation', params: {'_code': code});
  }
}
