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
