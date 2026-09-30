import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/membership.dart';

/// Where a resident is headed once they finish registering, from
/// validate_unit_invitation — shown as a "you're joining X" summary right
/// before the sign-in code goes out.
class InvitationPreview {
  const InvitationPreview({
    required this.unitName,
    required this.residentialName,
    required this.email,
    this.phone,
    this.fullName,
  });

  factory InvitationPreview.fromMap(Map<String, dynamic> map) =>
      InvitationPreview(
        unitName: map['unit_name'] as String,
        residentialName: map['residential_name'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String?,
        fullName: map['full_name'] as String?,
      );

  final String unitName;
  final String residentialName;

  /// The email the invitation was sent to — already on file, so the
  /// resident isn't asked to retype it.
  final String email;
  final String? phone;

  /// The resident's name, if an admin already captured it — null for an
  /// invitation that isn't linked to a unit_residents row.
  final String? fullName;
}

/// From check_email_login_status: whether an email belongs to a resident
/// who already has real access, one who's only been invited so far, or
/// neither.
enum EmailLoginStatus {
  active,
  invited,
  unknown;

  factory EmailLoginStatus.fromString(String value) => switch (value) {
    'active' => EmailLoginStatus.active,
    'invited' => EmailLoginStatus.invited,
    _ => EmailLoginStatus.unknown,
  };
}

class SessionRepository {
  SessionRepository(this._client);

  final SupabaseClient _client;

  /// Checks whether [email] belongs to a resident who's only been
  /// invited (an admin created the invitation, but they haven't entered
  /// the code yet) — so the login screen can point them at "Valida tu
  /// código" instead of sending a sign-in code straight to a disconnected
  /// account. Doesn't require a session (callable by `anon`).
  Future<EmailLoginStatus> checkEmailLoginStatus(String email) async {
    final status = await _client.rpc(
      'check_email_login_status',
      params: {'_email': email},
    ) as String;
    return EmailLoginStatus.fromString(status);
  }

  /// Checks an invitation code, *before* the resident picks an email or
  /// SMS code to sign in with — so registration is gated on a real
  /// invitation from the start instead of only being checked afterwards.
  /// Doesn't require a session (callable by `anon`) and doesn't consume
  /// the code; throws with the Postgres RAISE EXCEPTION message on an
  /// invalid, used, or expired code.
  Future<InvitationPreview> validateInvitation({required String code}) async {
    final rows = await _client.rpc(
      'validate_unit_invitation',
      params: {'_code': code},
    );
    final row = (rows as List).first as Map<String, dynamic>;
    return InvitationPreview.fromMap(row);
  }

  /// The units (and their residential) the current user belongs to.
  /// Empty means the resident has signed up but an admin hasn't linked
  /// them to a unit yet.
  Future<List<Membership>> fetchMyMemberships() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('fetchMyMemberships called with no signed-in user');
    }
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
