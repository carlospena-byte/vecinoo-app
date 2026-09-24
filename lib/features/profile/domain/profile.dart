class Profile {
  const Profile({
    required this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  final String userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  bool get isComplete =>
      (firstName?.trim().isNotEmpty ?? false) &&
      (lastName?.trim().isNotEmpty ?? false);

  String get displayName {
    final full = [firstName, lastName].where((s) => (s ?? '').trim().isNotEmpty).join(' ');
    return full.isNotEmpty ? full : (email ?? phone ?? 'Residente');
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'] as String,
      email: map['email'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
    );
  }
}
