import 'invitation.dart';
import 'membership.dart';

/// What the session feature needs from the backend. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions;
/// an invalid invitation code is a normal outcome, returned as a value.
abstract interface class SessionRepository {
  /// Checks whether [email] belongs to a resident who's only been invited
  /// (so the login screen can point them at "Valida tu código"). Doesn't
  /// require a session.
  Future<EmailLoginStatus> checkEmailLoginStatus(String email);

  /// Checks an invitation code without consuming it. Returns null when the
  /// code is invalid, used or expired. Doesn't require a session.
  Future<InvitationPreview?> validateInvitation({required String code});

  /// The units (and their residential) the current user belongs to. Empty
  /// means an admin hasn't linked them to a unit yet.
  Future<List<Membership>> fetchMyMemberships();

  /// Consumes an invitation code, linking the current user to its unit.
  /// Returns false when the code is invalid, used or expired.
  Future<bool> acceptInvitation(String code);
}
