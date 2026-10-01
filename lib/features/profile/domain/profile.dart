class Profile {
  const Profile({
    required this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.deletionScheduledFor,
  });

  final String userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;

  /// When the resident asked to delete their account, the day everything is
  /// permanently removed. Null when there is no pending request.
  final DateTime? deletionScheduledFor;

  bool get isComplete =>
      (firstName?.trim().isNotEmpty ?? false) &&
      (lastName?.trim().isNotEmpty ?? false);

  String get displayName {
    final full = [
      firstName,
      lastName,
    ].where((s) => (s ?? '').trim().isNotEmpty).join(' ');
    return full.isNotEmpty ? full : (email ?? phone ?? 'Residente');
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final scheduled = map['deletion_scheduled_for'] as String?;
    return Profile(
      userId: map['user_id'] as String,
      email: map['email'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      deletionScheduledFor: scheduled == null
          ? null
          : DateTime.parse(scheduled).toLocal(),
    );
  }
}
