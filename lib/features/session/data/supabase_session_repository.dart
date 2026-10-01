import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/invitation.dart';
import '../domain/membership.dart';
import '../domain/session_repository.dart';

/// Supabase-backed [SessionRepository]; every call surfaces errors as
/// `Failure`s.
class SupabaseSessionRepository implements SessionRepository {
  SupabaseSessionRepository(this._client);

  final SupabaseClient _client;

  /// Postgres `RAISE EXCEPTION` without a custom SQLSTATE: how the
  /// invitation functions reject an invalid, used or expired code.
  static const _raiseExceptionCode = 'P0001';

  @override
  Future<EmailLoginStatus> checkEmailLoginStatus(String email) =>
      guardFailure(() async {
        final status = await _client.rpc(
          'check_email_login_status',
          params: {'_email': email},
        ) as String;
        return EmailLoginStatus.fromString(status);
      });

  @override
  Future<InvitationPreview?> validateInvitation({required String code}) =>
      guardFailure(() async {
        try {
          final rows = await _client.rpc(
            'validate_unit_invitation',
            params: {'_code': code},
          );
          final list = rows as List;
          if (list.isEmpty) return null;
          return InvitationPreview.fromMap(list.first as Map<String, dynamic>);
        } on PostgrestException catch (e) {
          if (e.code == _raiseExceptionCode) return null;
          rethrow;
        }
      });

  @override
  Future<List<Membership>> fetchMyMemberships() => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final rows = await _client
        .from('unit_members')
        .select('units(id, name, residential_id, residentials(id, name))')
        .eq('user_id', userId);
    return (rows as List)
        .map((row) => Membership.fromMap(row as Map<String, dynamic>))
        .toList();
  });

  /// Consumes an invitation code an admin created in gates-admin, linking
  /// the current user to that unit via unit_members (see
  /// accept_unit_invitation in 20261001000000_unit_invitations.sql).
  @override
  Future<bool> acceptInvitation(String code) => guardFailure(() async {
    try {
      await _client.rpc('accept_unit_invitation', params: {'_code': code});
      return true;
    } on PostgrestException catch (e) {
      if (e.code == _raiseExceptionCode) return false;
      rethrow;
    }
  });
}
