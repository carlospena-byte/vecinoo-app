/// One row of the guard's access log for a visitor.
class AccessMovement {
  const AccessMovement({required this.checkedInAt, this.checkedOutAt});

  final DateTime checkedInAt;
  final DateTime? checkedOutAt;

  bool get isInside => checkedOutAt == null;

  factory AccessMovement.fromMap(Map<String, dynamic> map) => AccessMovement(
    checkedInAt: DateTime.parse(map['checked_in_at'] as String).toLocal(),
    checkedOutAt: (map['checked_out_at'] as String?) == null
        ? null
        : DateTime.parse(map['checked_out_at'] as String).toLocal(),
  );
}
