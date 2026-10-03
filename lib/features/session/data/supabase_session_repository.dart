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
        .select(
          'units(id, name, location_id, residential_id, residentials(id, name))',
        )
        .eq('user_id', userId);
    final memberships = (rows as List).cast<Map<String, dynamic>>();
    final residentialIds = {
      for (final row in memberships)
        (row['units'] as Map<String, dynamic>)['residential_id'] as String,
    };
    final locations = residentialIds.isEmpty
        ? const <String, Map<String, dynamic>>{}
        : {
            for (final l
                in (await _client
                        .from('locations')
                        .select('id, name, parent_id')
                        .inFilter('residential_id', residentialIds.toList()))
                    as List)
              (l as Map<String, dynamic>)['id'] as String: l,
          };
    return memberships.map((row) {
      final unit = row['units'] as Map<String, dynamic>;
      return Membership.fromMap(
        row,
        locationPath: _pathTo(unit['location_id'] as String?, locations),
      );
    }).toList();
  });

  /// Names from the outermost level down to [locationId] (inclusive).
  static List<String> _pathTo(
    String? locationId,
    Map<String, Map<String, dynamic>> locations,
  ) {
    final path = <String>[];
    final seen = <String>{};
    var current = locationId == null ? null : locations[locationId];
    while (current != null && seen.add(current['id'] as String)) {
      path.insert(0, current['name'] as String);
      final parent = current['parent_id'] as String?;
      current = parent == null ? null : locations[parent];
    }
    return path;
  }

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
